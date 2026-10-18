"""Read-only evidence collection for the open OPT12 study, not a release lock."""
from pathlib import Path
import csv
import hashlib
import json
import re
import zipfile
from audit_rtl_release import validate

R = Path(__file__).resolve().parents[1]
O = R/'results/opt120_20261018'
read = lambda p: p.read_text(encoding='utf-8-sig')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()


def path_slack(path):
    return float(re.search(r'Slack\s*\([^)]*\)\s*:\s*([-\d.]+)ns',read(path))[1])


def ppa(path):
    m=json.loads(read(path/'manifest.json'))
    assert read(path/'status.txt').strip()=='COMPLETE'
    for name,digest in m['source_sha256'].items():
        assert sha(path/'source'/name.replace('\\','/'))==digest,name
    variant=O/'source'/m['variant']
    for p in (path/'source/rtl').rglob('*'):
        if p.suffix in ('.sv','.vh'):
            assert sha(p)==sha(variant/p.relative_to(path/'source')),p
    clock=read(path/'source/syn/constraints/a35t_clock.xdc')
    assert f"-period {m['clock_ns']:.3f}" in clock
    assert clock.count('0.100')==2
    assert sha(path/'source/syn/constraints/a35t_benchmark_100mhz.xdc')==sha(R/'syn/constraints/a35t_benchmark_100mhz.xdc')
    flow=read(path/'source/syn/run_a35t.tcl')
    assert flow.index('read_xdc')<flow.index('    synth_design')
    log=read(path/'vivado.log')
    assert not re.search(r'^ERROR:',log,re.M)
    critical=re.findall(r'^CRITICAL WARNING:.*$',log,re.M)
    assert all('[Route 35-39] The design did not meet timing requirements.' in line for line in critical)
    text=read(path/'timing.rpt')
    match=re.search(r'WNS\(ns\).*?\n\s*-.*?\n\s*([-\d.]+)\s+([-\d.]+)\s+\d+\s+\d+\s+([-\d.]+)\s+([-\d.]+)',text,re.S)
    assert match
    timing=dict(zip(('wns_ns','tns_ns','whs_ns','ths_ns'),map(float,match.groups())))
    if critical:assert timing['wns_ns']<0 or timing['whs_ns']<0
    for line in ('There are 0 register/latch pins with no clock.',
                 'There are 0 pins that are not constrained for maximum delay.'):
        assert line in text,line
    resources={}
    for name in ('Slice LUTs','Slice Registers','CARRY4','DSPs','RAMB36/FIFO*','RAMB18','Register as Latch'):
        hit=re.search(r'^\|\s*'+re.escape(name)+r'\s*\|\s*(\d+)',read(path/'utilization.rpt'),re.M)
        if hit:resources[name]=int(hit[1])
    assert resources.get('Register as Latch',0)==0
    r2r={kind:path_slack(path/f'r2r_{kind}.rpt') for kind in ('setup','hold')}
    stages=list(csv.DictReader((path/'stages.csv').open())) if (path/'stages.csv').exists() else []
    if stages:
        assert len(stages)==24
        structural=dict(line.split('=',1) for line in read(path/'structural.txt').splitlines())
        assert structural['latches']==structural['unclassified']==structural['unrouted']=='0'
    return dict(path=path.relative_to(R).as_posix(),top=m['top'],variant=m['variant'],
                strategy=m['strategy'],clock_ns=m['clock_ns'],frequency_mhz=1000/m['clock_ns'],
                **timing,r2r_setup_ns=r2r['setup'],r2r_hold_ns=r2r['hold'],resources=resources,stages=stages,
                full_timing_pass=timing['wns_ns']>=0 and timing['whs_ns']>=0 and timing['tns_ns']==timing['ths_ns']==0,
                r2r_pass=min(r2r.values())>=0,critical_warnings=critical,
                note='Direct post-route declared-clock result with unchanged C2 I/O, not board or maximum-frequency sweep')


def collect():
    active=json.loads(read(R/'rtl/production_freeze.json'));validate(active)
    # The trial remains bound to its original reference after explicit promotion.
    # Do not rewrite historical hashes or pretend the active parser is unchanged.
    with zipfile.ZipFile(O/'reference_source.zip') as archive:
        lock=json.loads(archive.read('rtl/production_freeze.json'))
        for group in ('rtl_sha256','model_sha256','build_contract_sha256'):
            for name,digest in lock[group].items():
                assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
    if active['release_id']!=lock['release_id']:
        assert active['parent_release']==lock['release_id']
        for name,digest in lock['model_sha256'].items():assert sha(R/name)==digest
        for name,digest in lock['build_contract_sha256'].items():assert sha(R/name)==digest
    variants=json.loads(read(O/'variants.json'))
    for variant,hashes in variants['variants'].items():
        for name,digest in hashes.items():assert sha(O/'source'/variant/name)==digest
        for leaf in ('posit_parser','posit_parser_comb'):
            relative=f'rtl/parser/{leaf}.sv'
            header=lambda p: re.sub(r'\s+','',read(p).split('module ',1)[1].split(');',1)[0])
            assert header(O/'source'/variant/relative)==header(O/'source/reference'/relative)
    units={}
    for variant in variants['variants']:
        run=O/'unit'/variant
        if not (run/'status.txt').exists():continue
        assert read(run/'status.txt').strip()=='COMPLETE'
        lint=list((run/'lint').glob('*.log'))
        assert len(lint)==870 and all(not re.search(r'%Warning|%Error',read(p)) for p in lint)
        text=read(run/'simulate.log')
        assert 'OPT12 PARSER MATRIX PASS' in text
        checks=re.findall(r'PARAM PASS NB=(\d+) ES=(\d+) SW=(\d+) checks=(\d+)',text)
        exhaustive=re.findall(r'OPT12 EXHAUSTIVE PASS NB=(\d+) ES=(\d+) checks=(\d+)',text)
        assert len(checks)==13 and len(exhaustive)==6
        units[variant]=dict(strict_lint_profiles=870,cycle_profiles=len(checks),
                            cycle_checks=sum(int(row[3]) for row in checks),
                            exhaustive_profiles=len(exhaustive),exhaustive_checks=sum(int(row[2]) for row in exhaustive),mismatches=0)
    pilots={};stress={}
    for variant in variants['variants']:
        nf=O/'verify'/variant
        if (nf/'status.txt').exists():
            assert read(nf/'status.txt').strip()=='COMPLETE'
            rows=[json.loads(read(nf/f'nf/{nb}_{es}/pilot_summary.json')) for nb,es in [(8,0),(16,1),(32,2),(32,3)]]
            assert all(row['completed']==20000 and row['mismatches']==0 for row in rows)
            pilots[variant]={'nf':rows}
        f=O/'fused'/variant
        if (f/'status.txt').exists():
            assert read(f/'status.txt').strip()=='COMPLETE'
            row=json.loads(read(f/'pilot.json'))
            assert row['completed']==100000 and row['mismatches']==0
            assert row==json.loads(read(R/'results/opt02c_20261018/fused/pilot.json'))
            pilots.setdefault(variant,{})['f']=row
        for top,path,report in [('nf',nf/'nf/32_3','stress_10000000_summary.json'),('f',f,'stress_10000000.json')]:
            if not (path/'stress_10000000_status.txt').exists():continue
            assert read(path/'stress_10000000_status.txt').strip()=='COMPLETE'
            row=json.loads(read(path/report))
            assert row['completed']==10000000 and row['mismatches']==0
            old=(R/'results/opt02c_20261018/verify/candidate/nf/32_3/acceptance_summary.json') if top=='nf' else (R/'results/optcombo_20261018/fused/main.json')
            assert row==json.loads(read(old)),f'{variant} {top}: prior numerical/protocol counters differ'
            stress.setdefault(variant,{})[top]=row
    events={}
    for variant in variants['variants']:
        path=O/f'event_{variant}'
        if not (path/'status.txt').exists():continue
        assert read(path/'status.txt').strip()=='COMPLETE'
        expected=json.loads(read(path/'source_sha256.json'))
        assert expected==variants['variants'][variant]
        for name,digest in expected.items():assert sha(path/'source'/name)==digest
        bound=json.loads(read(path/'fixture_sha256.json'))
        for name,digest in bound.items():assert sha(R/name)==digest
        rows=[]
        for nb,es in [(8,0),(16,1),(32,2),(32,3)]:
            for kind in ('corner','protocol'):
                text=read(path/f'{kind}_{nb}_{es}.log')
                assert not re.search(r'\*\*\s+(Error|Fatal):',text)
                hit=re.search(r'W11 MODELSIM PASS NB=(\d+) ES=(\d+) rows=(\d+) completed=(\d+) aborted=(\d+) stalls=(\d+) mismatches=0',text)
                assert hit
                rows.append(dict(zip(('NB','ES','rows','completed','aborted','stalls'),map(int,hit.groups()))))
        assert 'W13_EVENT_PASS completed=8192 reset_aborts=24 mismatch=0 CK2Q=1ns' in read(path/'fused.log')
        assert 'event_clock_ns=8.000 CK2Q_ns=1.000' in read(path/'event_scope.txt')
        for name in ('tb_week11_mac.sv','tb_week13_fused_event.sv'):
            assert 'always #4 clk = ~clk;' in read(path/'source/tb'/name)
        events[variant]=dict(nf_completed=sum(row['completed'] for row in rows),
            nf_reset_aborted=sum(row['aborted'] for row in rows),f_completed=8192,f_reset_aborted=24,
            mismatches=0,clock_ns=8,CK2Q_ns=1,limits='RTL event simulation; not SDF post-route simulation')
    measured=[]
    for path in sorted(O.glob('ppa*/*/p*/*')):
        if (path/'status.txt').exists():measured.append(ppa(path))
    return dict(status='PARTIAL_UNTIL_FINAL_AUDIT',reference_release=lock['release_id'],
                production_unchanged=True,units=units,pilots=pilots,stress=stress,events=events,ppa=measured,
                failed_setup_not_acceptance=['ppa/reference/p8000/Default'],
                limits=['No candidate promoted or release lock created','Not W14 final per-n/AC04','Report actual full-interface and R2R results separately'])


if __name__=='__main__':
    result=collect()
    if (O/'qualification.json').exists():
        qualification=json.loads(read(O/'qualification.json'))
        assert sha(O/'summary.json')==qualification['summary_sha256']
        saved=json.loads(read(O/'summary.json'))
        for key in ('reference_release','production_unchanged','units','pilots','stress','events','ppa'):
            assert saved[key]==result[key],f'Qualified evidence changed: {key}'
        for relative,digest in qualification['recommendation']['source_sha256'].items():
            assert sha(O/'source/candidate'/relative)==digest
            assert sha(R/'rtl/candidates/parser/opt12'/Path(relative).name)==digest
        print('Qualified historical trial remains unchanged; no summary or lock rewritten')
    else:
        (O/'summary.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('OPT12 evidence checked:',len(result['units']),'unit variants,',len(result['ppa']),'PPA runs')
