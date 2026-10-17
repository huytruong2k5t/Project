"""Audit the isolated OPT-02b experiment; never promote production implicitly."""
from pathlib import Path
import csv
import hashlib
import json
import re
import sys
import zipfile

R=Path(__file__).resolve().parents[1]
O=R/'results/opt02b_20261017'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()


def read(name):
    return (O/name).read_text(encoding='utf-8-sig',errors='replace')


def collect():
    for name,digest in json.loads(read('verification_inputs.json')).items():
        assert sha(R/name)==digest,name
        assert sha(O/'verification_inputs'/name)==digest,name
    for name,digest in json.loads(read('source_sha256.json')).items():assert sha(O/name)==digest,name
    paths=[R/name for name in (R/'rtl/production.f').read_text().splitlines() if name.strip()]+[R/'rtl/posit_mac.vh']
    assert all(p.read_bytes()==(O/'source/baseline'/p.name).read_bytes() for p in paths),'Production changed'
    previous_sources=json.loads(read('baseline_reference/single_source_sha256.json'))
    assert all(sha(O/'source/baseline'/p.name)==previous_sources[p.relative_to(R).as_posix()] for p in paths)
    changed=[p.name for p in (O/'source/candidate').iterdir() if p.read_bytes()!=(O/'source/baseline'/p.name).read_bytes()]
    assert changed==['posit_add_align.sv'],changed
    assert sha(R/'rtl/candidates/adder/opt02b/posit_add_align.sv')==sha(O/'source/candidate/posit_add_align.sv')
    header=lambda s:re.sub(r'\s+','',s[s.index('module posit_add_align #('):].split(');',1)[0])
    assert header(read('source/baseline/posit_add_align.sv'))==header(read('source/candidate/posit_add_align.sv'))
    assert len(list((O/'lint').glob('*.log')))==406
    assert all(not re.search(r'%Warning|%Error',p.read_text()) for p in (O/'lint').glob('*.log'))
    leaf=read('leaf/simulate.log')
    assert 'ALIGN MATRIX PASS' in leaf and not re.search(r'\*\*\s+(Fatal|Error):',leaf)
    checks=[list(map(int,m)) for m in re.findall(r'ALIGN PASS NB=(\d+) ES=(\d+) SW=(\d+) checks=(\d+) mismatch=0 nar_zero=(\d+) clamp=(\d+) threshold=(\d+) tie=(\d+)',leaf)]
    assert len(checks)==11 and all(min(m[4:])>0 for m in checks)
    pilots=[]
    for nb,es in [(8,0),(16,1),(32,2),(32,3)]:
        d=json.loads(read(f'nf/{nb}_{es}/pilot_summary.json'))
        assert d['completed']==20000 and d['mismatches']==0 and min(d['bins'])>0
        assert not re.search(r'%Warning|%Error',read(f'nf/{nb}_{es}/lint.log'))
        pilots.append(d)
        run=O/f'nf/{nb}_{es}'
        for line in (run/'source.sha256').read_text().splitlines():
            digest,name=line.split(maxsplit=1);p=run/name.strip()
            if p.suffix=='.so' and not p.exists():
                assert name.strip()=='src/libsoftposit.so'
                assert digest==json.loads(read('runtime_sha256.json'))['l0/libsoftposit.so']
                continue
            assert sha(p)==digest,str(p)
    large=json.loads(read('nf/32_3/acceptance_summary.json'))
    ref=json.loads(read('baseline_reference/nf_acceptance_summary.json'))
    assert large==ref,'Same-latency frozen corpus/control counters differ'
    assert large['completed']==10000000 and large['mismatches']==0
    assert min(large['regime_sign_bins'])>0
    modelsim=[]
    for nb,es in [(8,0),(16,1),(32,2),(32,3)]:
        for kind,goal in [('simulate',20736),('protocol',7128)]:
            log=read(f'modelsim/{kind}_{nb}_{es}.log')
            assert not re.search(r'\*\*\s+(Error|Fatal):',log)
            m=re.search(r'W11 MODELSIM PASS NB=(\d+) ES=(\d+) rows=(\d+) completed=(\d+) aborted=(\d+) stalls=(\d+) mismatches=0',log)
            assert m and int(m[4])==goal
            modelsim.append(dict(NB=nb,ES=es,kind=kind,completed=int(m[4]),aborted=int(m[5])))
    assert read('modelsim/status.txt').strip()=='COMPLETE'
    assert read('ppa/status.txt').strip()=='COMPLETE'
    log=read('ppa/vivado.log')
    assert 'OPT02B_A35_PPA_COMPLETE' in log and not re.search(r'^ERROR:',log,re.M)
    counts={k:len(re.findall(r'^Command: '+k+r'\b',log,re.M)) for k in ['synth_design','place_design','route_design']}
    assert all(v==1 for v in counts.values()),counts
    for name,digest in json.loads(read('ppa/driver_sha256.json')).items():assert sha(R/name)==digest,name
    before_route=lambda s:s[:s.index('report_utilization')]
    assert before_route(read('baseline_reference/executed_baseline_driver.tcl'))==before_route(read('ppa/driver/opt02b_a35_ppa.tcl'))
    assert previous_sources['tb/prepack_nf_ppa_top.sv']==sha(O/'ppa/driver/prepack_nf_ppa_top.sv')
    with (O/'ppa/stages.csv').open() as f:rows=list(csv.DictReader(f))
    assert len(rows)==6
    for row in rows:
        row['register_count']=int(row['register_count']);row['levels']=int(row['levels'])
        for k in ['setup_slack_ns','hold_slack_ns','data_delay_ns','logic_delay_ns','route_delay_ns']:row[k]=float(row[k])
        assert row['register_count']>0
    assert read('ppa/structural.txt').strip()=='latches=0\nunrouted=0'
    util=read('ppa/utilization.rpt')
    resource_patterns={'LUT':r'\| Slice LUTs\s*\|\s*([0-9]+)','FF':r'\| Slice Registers\s*\|\s*([0-9]+)',
        'CARRY4':r'\| CARRY4\s*\|\s*([0-9]+)','DSP':r'\| DSPs\s*\|\s*([0-9]+)',
        'BRAM':r'\| Block RAM Tile\s*\|\s*([0-9]+)'}
    resources={k:int(re.search(pat,util)[1]) for k,pat in resource_patterns.items()}
    baseline_resources={k:int(re.search(pat,read('baseline_reference/utilization.rpt'))[1]) for k,pat in resource_patterns.items()}
    old=json.loads(read('baseline_reference/single_run_summary.json'))
    now=rows[0];mhz=1000/(10-now['setup_slack_ns'])
    result=dict(status='PASS_EXPERIMENT_SCOPE',production_variant='baseline',candidate_module='rtl/candidates/adder/opt02b/posit_add_align.sv',
        RTL_changed_in_production=False,interface_and_pipeline_unchanged=True,leaf_profiles=checks,
        leaf_checks=sum(m[3] for m in checks),leaf_mismatches=0,strict_leaf_lint=406,strict_NF_lint=4,
        pilots=pilots,main=large,frozen_corpus_counters_identical=True,modelsim=modelsim,
        ppa=dict(part='xc7a35tcpg236-1',directive='Default',clock_ns=10,phase_counts=counts,stages=rows,resources=resources,
            sta_estimate_mhz=mhz,hold_positive=all(r['hold_slack_ns']>0 for r in rows),
            baseline_resources=baseline_resources,baseline_sta_estimate_mhz=old['sta_estimate_mhz'],
            frequency_change_percent=100*(mhz/old['sta_estimate_mhz']-1)),
        limitations=['One candidate P&R versus source-identical baseline Default; not a median/multi-part promotion',
            'Candidate only: no C prefix registers or max_fanout, no latency/II or L1/Fused change',
            'Known-binary leaf equivalence plus ModelSim reset/X-output checks, not formal X/Z equivalence',
            'Initial wide-ES cast warning fixed before final acceptance; preliminary logs excluded from totals',
            'Final AC04/per-n, board signoff and matched NF/F PPA remain open'])
    p=O/'summary.json'
    if not p.exists() or json.loads(p.read_text())!=result:p.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result['ppa'],indent=2));print('OPT02B_AUDIT_PASS')


def archive():
    assert json.loads(read('summary.json'))['status']=='PASS_EXPERIMENT_SCOPE'
    assert not (O/'evidence.zip').exists()
    skip={'work','obj_fast','obj_dir','tmp','appdata','localappdata','.Xil','__pycache__'}
    suffix={'.sv','.vh','.h','.hpp','.cpp','.vlt','.py','.ps1','.sh','.tcl','.log','.rpt','.json','.txt','.csv','.dat','.sha256','.do','.xdc'}
    manifest={}
    with zipfile.ZipFile(O/'evidence.zip','w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted(O.rglob('*')):
            if not p.is_file() or skip.intersection(p.relative_to(O).parts) or p.suffix not in suffix:continue
            if p.name=='archive_manifest.json':continue
            raw=p.read_bytes();name=p.relative_to(O).as_posix()
            manifest[name]=hashlib.sha256(raw).hexdigest();z.writestr(name,raw)
    with zipfile.ZipFile(O/'evidence.zip') as z:
        assert z.testzip() is None
        assert all(hashlib.sha256(z.read(k)).hexdigest()==v for k,v in manifest.items())
    (O/'archive_manifest.json').write_text(json.dumps(dict(files=manifest,archive_sha256=sha(O/'evidence.zip')),indent=2)+'\n')
    print('OPT02B_ARCHIVE_PASS',len(manifest),(O/'evidence.zip').stat().st_size)


def restore():
    m=json.loads(read('archive_manifest.json'));assert sha(O/'evidence.zip')==m['archive_sha256']
    with zipfile.ZipFile(O/'evidence.zip') as z:
        assert set(z.namelist())==set(m['files'])
        for name,digest in m['files'].items():
            p=O/name;assert p.resolve().is_relative_to(O.resolve())
            assert hashlib.sha256(z.read(name)).hexdigest()==digest
            if p.exists():assert sha(p)==digest,'Preserve existing different file: '+name
        for name in m['files']:
            p=O/name
            if not p.exists():p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(z.read(name))
    print('OPT02B_RESTORE_PASS')


if __name__=='__main__':
    assert len(sys.argv)==2 and sys.argv[1] in ['collect','archive','restore']
    globals()[sys.argv[1]]()
