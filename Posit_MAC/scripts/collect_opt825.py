"""Collect measured experiments without converting unfinished work into PASS."""
from pathlib import Path
import csv
import hashlib
import json
import re

R = Path(__file__).resolve().parents[1]
STUDIES = ('opt05_20261017','opt09_20261018','opt10a_20261018','optcombo_20261018')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()


def read(p):
    return p.read_text(encoding='utf-8-sig', errors='replace')


def ppa(run):
    assert read(run/'status.txt').strip() == 'COMPLETE'
    manifest = json.loads(read(run/'manifest.json'))
    for name,digest in manifest['source_sha256'].items():
        assert sha(run/'source'/name.replace('\\','/')) == digest, name
    frozen=run.parents[2]/'source'/manifest['variant']
    for p in (run/'source/rtl').rglob('*'):
        if p.suffix in ('.sv','.vh'):
            assert sha(p)==sha(frozen/p.name),p
    assert sha(run/'source/tb/prepack_nf_ppa_top.sv')==sha(R/'tb/prepack_nf_ppa_top.sv')
    log = read(run/'vivado.log')
    assert not re.search(r'^(ERROR|CRITICAL WARNING):',log,re.M), run
    for command in ('synth_design','place_design','route_design'):
        assert len(re.findall(r'^Command: '+command+r'\b',log,re.M)) == 1, (run,command)
    for xdc in ('a35t_clock.xdc','a35t_benchmark_100mhz.xdc'):
        assert sha(run/'source/syn/constraints'/xdc) == sha(R/'syn/constraints'/xdc)
    flow=read(run/'source/syn/run_a35t.tcl')
    assert flow.index('read_xdc') < flow.index('    synth_design')
    text=read(run/'utilization.rpt')
    resource={}
    for name in ('Slice LUTs','Slice Registers','CARRY4','DSPs','RAMB36/FIFO*','RAMB18'):
        match=re.search(r'^\|\s*'+re.escape(name)+r'\s*\|\s*(\d+)',text,re.M)
        if match: resource[name]=int(match[1])
    timing=read(run/'timing.rpt')
    match=re.search(r'WNS\(ns\).*?\n\s*-.*?\n\s*([-\d.]+)\s+([-\d.]+)\s+\d+\s+\d+\s+([-\d.]+)\s+([-\d.]+)',timing,re.S)
    assert match, run
    values=dict(zip(('wns_ns','tns_ns','whs_ns','ths_ns'),map(float,match.groups())))
    rows=list(csv.DictReader((run/'stages.csv').open()))
    assert len(rows)==24 and sum(int(x['register_count']) for x in rows if x['group']!='whole_data')==int(next(x['register_count'] for x in rows if x['group']=='whole_data'))
    structural=dict(line.split('=',1) for line in read(run/'structural.txt').splitlines())
    assert structural['latches']=='0' and structural['unrouted']=='0' and structural['unclassified']=='0'
    for line in ('There are 0 register/latch pins with no clock.',
                 'There are 0 pins that are not constrained for maximum delay.'):
        assert line in timing,line
    path=read(run/'r2r_setup.rpt')
    r2r=re.search(r'Slack\s*\([^)]*\)\s*:\s*([-\d.]+)ns',path)
    assert r2r
    return dict(variant=manifest['variant'],strategy=manifest['strategy'],resources=resource,
                **values,r2r_wns_ns=float(r2r[1]),structural=structural,stages=rows,
                f_sta_estimate_mhz=1000/(10-float(r2r[1])),
                interface_scope='Assumed OOC budget; no PARTPIN/board signoff')


def main():
    frozen=json.loads(read(R/'results/opt05_20261017/freeze.json'))
    assert all(sha(R/name)==digest for name,digest in frozen['production_sha256'].items()), 'Production changed'
    for variant in ('a','ab','abc_sub','abc_tree'):
        source=R/'results/opt05_20261017/source'/variant
        canonical=R/'rtl/candidates/multiplier/opt05'/variant
        for p in canonical.glob('*.sv'):assert sha(p)==sha(source/p.name)
    for family,study,variant in (('mac_nf/opt09','opt09_20261018','magnitude'),
                                 ('packer/opt10a','opt10a_20261018','sticky')):
        for p in (R/'rtl/candidates'/family).glob('*.sv'):
            assert sha(p)==sha(R/'results'/study/'source'/variant/p.name)
    output={'production_unchanged':True,'promoted':False,'studies':{}}
    for study in STUDIES:
        root=R/'results'/study
        if not root.exists():continue
        results=[]
        pending=[]
        for manifest in sorted(root.glob('ppa/*/*/manifest.json')):
            run=manifest.parent
            if (run/'status.txt').exists(): results.append(ppa(run))
            else: pending.append(run.relative_to(root).as_posix())
        data={'ppa':results,'pending_ppa':pending,'pilots':[]}
        for report in sorted(root.glob('verify/*/nf/*/pilot_summary.json')):
            pilot=json.loads(read(report))
            assert pilot['completed']==20000 and pilot['mismatches']==0
            assert min(pilot['bins'])>0
            assert not re.search(r'%Warning|%Error',read(report.parent/'lint.log'))
            data['pilots'].append({'path':report.relative_to(root).as_posix(),'result':pilot})
        for name in ('leaf_native_v2','leaf_event','product','leaf'):
            p=root/name/'status.txt'
            if p.exists():data[name+'_status']=read(p).strip()
        if study=='opt05_20261017':
            text=read(root/'leaf_native_v2/simulate.log')
            counts=re.findall(r'SAC PASS W=(\d+) S=(\d+) checks=(\d+) variants=5 mismatches=0',text)
            assert len(counts)==54 and 'SAC MATRIX PASS' in text
            data['leaf_cases']=sum(int(x[2]) for x in counts)
            data['candidate_oracle_comparisons']=4*data['leaf_cases']
            data['event_cases']=sum(int(re.search(r'checks=(\d+)',read(p))[1])
                for p in (root/'leaf_event').glob('simulate_*.log'))
            for variant in ('a','ab','abc_sub','abc_tree'):
                logs=list((root/'verify'/variant/'lint').glob('*.log'))
                assert len(logs)==54 and all(not re.search(r'%Warning|%Error',read(p)) for p in logs)
        if study=='opt09_20261018' and (root/'product/status.txt').exists():
            text=read(root/'product/simulate.log')
            assert 'PRODUCT MATRIX PASS' in text
            data['roundtrip_cycles']=sum(map(int,re.findall(r'cycles=(\d+)',text)))
            data['roundtrip_completed']=sum(map(int,re.findall(r'completed=(\d+)',text)))
        if study=='opt10a_20261018' and (root/'leaf/status.txt').exists():
            text=read(root/'leaf/simulate.log')
            assert 'PREPARE MATRIX PASS' in text
            data['leaf_cases']=sum(map(int,re.findall(r'checks=(\d+)',text)))
            logs=list((root/'leaf/lint').glob('*.log'))
            assert len(logs)==435 and all(not re.search(r'%Warning|%Error',read(p)) for p in logs)
        if study=='optcombo_20261018':
            report=root/'verify/combined/nf/32_3/acceptance_summary.json'
            if report.exists():
                data['nf_main']=json.loads(read(report))
                previous=json.loads(read(R/'results/opt02b_20261017/nf/32_3/acceptance_summary.json'))
                assert data['nf_main']==previous, 'Same-cycle NF corpus/counters changed'
            data['acceptance_status']=read(root/'acceptance_status.txt').strip() if (root/'acceptance_status.txt').exists() else 'PENDING'
            if (root/'fused/status.txt').exists():
                assert read(root/'fused/status.txt').strip()=='COMPLETE'
                data['f_main']=json.loads(read(root/'fused/main.json'))
                previous=json.loads(read(R/'results/week13/summary.json'))['main']
                assert data['f_main']==previous, 'Same-cycle F corpus/counters changed'
                assert data['f_main']['completed']==10000000 and data['f_main']['mismatches']==0
                assert not re.search(r'%Warning|%Error',read(root/'fused/lint.log'))
            if (root/'fused_event_v2/status.txt').exists():
                assert read(root/'fused_event_v2/status.txt').strip()=='COMPLETE'
                text=read(root/'fused_event_v2/simulate.log')
                assert 'W13_EVENT_PASS completed=8192 reset_aborts=24 mismatch=0 CK2Q=1ns' in text
                data['f_modelsim']={'completed':8192,'reset_aborted':24,'mismatches':0,'CK2Q_ns':1}
            if (root/'modelsim/status.txt').exists():
                assert read(root/'modelsim/status.txt').strip()=='COMPLETE'
                data['nf_modelsim']=[]
                for p in sorted((root/'modelsim').glob('*.log')):
                    if not re.match(r'(simulate|protocol)_\d+_\d+\.log',p.name):continue
                    text=read(p)
                    match=re.search(r'W11 MODELSIM PASS NB=(\d+) ES=(\d+) rows=(\d+) completed=(\d+) aborted=(\d+) stalls=(\d+) mismatches=0',text)
                    assert match and not re.search(r'\*\*\s+(Error|Fatal):',text)
                    data['nf_modelsim'].append(dict(zip(('NB','ES','rows','completed','aborted','stalls'),map(int,match.groups()))))
                assert len(data['nf_modelsim'])==8
        (root/'summary.json').write_text(json.dumps(data,indent=2)+'\n')
        output['studies'][study]={k:v for k,v in data.items() if k not in ('ppa','pilots')}
        output['studies'][study]['ppa']=[{k:v for k,v in x.items() if k!='stages'} for x in results]
        output['studies'][study]['pilot_completed']=sum(p['result']['completed'] for p in data['pilots'])
    (R/'results/opt05_20261017/optimization_summary.json').write_text(json.dumps(output,indent=2)+'\n')
    return output


if __name__=='__main__':
    result=main()
    print('OPT825 AUDIT PASS; production unchanged; '+str(len(result['studies']))+' studies collected')
