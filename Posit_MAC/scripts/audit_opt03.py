"""Audit/archive/restore the isolated OPT-03 checkpoint (no simulator binaries)."""
from pathlib import Path
import csv
import hashlib
import json
import re
import statistics
import sys
import zipfile

R = Path(__file__).resolve().parents[1]
O = R/'results/opt03_20261017'
PARTS = ['xc7a35tcpg236-1', 'xc7a100tcsg324-1']


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def read(p):
    return (O/p).read_text(encoding='utf-8-sig', errors='replace')


def load(p):
    return json.loads(read(p))


def collect():
    for name,digest in load('verification_inputs.json').items():
        assert sha(R/name)==digest,name
        assert sha(O/'verification_inputs'/name)==digest,name
    changed=[]
    for v in ('baseline','candidate'):
        for name,digest in load(f'{v}_sha256.json').items():
            assert sha(O/'source'/v/name)==digest, (v,name)
            if v=='candidate':
                paths=list((R/'rtl').glob('**/'+name))
                paths=[p for p in paths if 'candidates' not in p.parts and 'research' not in p.parts]
                assert len(paths)==1 and sha(paths[0])==digest, name
                if sha(O/'source/baseline'/name)!=digest:changed.append(name)
    assert changed==['mac_nf_wrapper.sv'], changed
    native=[]
    for nb,es in [(8,0),(16,1),(32,2),(32,3)]:
        run=O/f'nf/{nb}_{es}'
        for line in (run/'source.sha256').read_text().splitlines():
            digest,name=line.split(maxsplit=1)
            p=run/name.strip()
            if p.suffix=='.so' and not p.exists():
                assert name.strip()=='src/libsoftposit.so'
                assert digest==load('verification_runtime.json')['l0/libsoftposit.so']
                continue
            assert sha(p)==digest, str(p)
        d=load(f'nf/{nb}_{es}/pilot_summary.json')
        assert d['completed']==20000 and d['mismatches']==0
        assert d['accepted']==d['completed']+d['reset_aborts']
        assert min(d['bins'])>0
        assert all(d[k]>0 for k in ['reset_busy','reset_stalled','acc_commits','clears','long_stalls'])
        assert not re.search(r'%Warning|%Error',read(f'nf/{nb}_{es}/lint.log'))
        native.append(d)
    large=load('nf/32_3/acceptance_summary.json')
    assert large['completed']==10000000 and large['mismatches']==0
    assert large['accepted']==large['completed']+large['reset_aborts']
    assert min(large['bins'])>0 and min(large['regime_sign_bins'])>0
    assert large['product_packer_events']==large['final_packer_events']==10000000
    near=[]
    for j in range(2):
        n=sum(large['near_delta_standalone_acc'][5*j:5*j+5])
        denominator=large['finite_add_standalone_acc'][j]
        near.append(n/denominator)
        assert n*100 >= denominator*30
    model=[]
    schedule=[]
    for nb,es in [(8,0),(16,1),(32,2),(32,3)]:
        for kind,expected in [('simulate',20736),('protocol',7128)]:
            log=read(f'modelsim/{kind}_{nb}_{es}.log')
            assert not re.search(r'\*\*\s+(Error|Fatal):',log)
            m=re.search(r'W11 MODELSIM PASS NB=(\d+) ES=(\d+) rows=(\d+) completed=(\d+) aborted=(\d+) stalls=(\d+) mismatches=0',log)
            assert m and int(m[4])==expected
            model.append(dict(kind=kind,NB=nb,ES=es,completed=int(m[4]),aborted=int(m[5])))
        log=read(f'modelsim/schedule_{nb}_{es}.log')
        assert 'OPT03 SCHEDULE PASS' in log and 'valid=q+12 handshake=q+13 II=q+14' in log
        assert not re.search(r'\*\*\s+(Error|Fatal):',log)
        m=re.search(r'reset_ages=(\d+) captures=(\d+) dense_checks=(\d+)',log)
        assert m and int(m[3])==int(m[1])+2
        schedule.append(dict(NB=nb,ES=es,reset_ages=int(m[1]),captures=int(m[2]),dense_checks=int(m[3])))
    assert '41024 checks, 0 mismatches' in read('modelsim/lod_simulate.log')
    for name,digest in load('modelsim/fixture_sha256.json').items():assert sha(O/'fixtures'/name)==digest
    for name,digest in load('protocol_fixture_sha256.json').items():assert sha(O/'protocol_fixtures'/name)==digest
    rows=[]
    reuse=load('baseline_reuse.json')
    assert reuse['all_source_bytes_identical'] and reuse['fresh_default_metrics_identical_on_both_parts']
    for name,digest in reuse['files'].items():assert sha(O/name)==digest
    for part in PARTS:
        assert 'OPT03_PPA_COMPLETE' in read(f'ppa/{part}/console.log')
        for name,digest in load(f'ppa/{part}/driver_sha256.json').items():assert sha(R/name)==digest
        with (O/'ppa'/part/'metrics.csv').open() as f:rs=list(csv.DictReader(f))
        assert len(rs)==3 and all(d['variant']=='candidate' for d in rs)
        with (O/'baseline_reference'/part/'historical_metrics.csv').open() as f:
            rs += [d for d in csv.DictReader(f) if d['variant']=='baseline']
        assert len(rs)==6 and {(d['variant'],d['strategy']) for d in rs}=={
            (v,s) for v in ['baseline','candidate'] for s in ['default','explore','runtime']}
        for d in rs:
            for k in ['lut','ff','carry4','dsp','bram','levels','latches','unrouted']:d[k]=int(d[k])
            for k in ['slack','hold','delay_ns','logic_ns','route_ns','norm_slack','norm_delay_ns']:d[k]=float(d[k])
            assert d['latches']==d['unrouted']==d['dsp']==d['bram']==0
            assert d['hold']>0
            d['part']=part
            d['sta_estimate_mhz']=1000/(10-d['slack'])
            folder=(O/'ppa'/part if d['variant']=='candidate' else O/'baseline_reference'/part)/f"{d['variant']}_{d['strategy']}"
            d['endpoints']=dict(line.split('=',1) for line in (folder/'endpoints.txt').read_text().splitlines() if '=' in line)
            d['stage_slack_ns']={}
            for report in folder.glob('stage_*.rpt'):
                m=re.search(r'Slack\s*\((?:MET|VIOLATED)\)\s*:\s*([+-]?[0-9.]+)ns',report.read_text())
                assert m,report
                d['stage_slack_ns'][report.stem]=float(m[1])
            rows.append(d)
    comparisons=[]
    for part in PARTS:
        out={'part':part}
        for v in ['baseline','candidate']:
            rs=[d for d in rows if d['part']==part and d['variant']==v]
            out[v]={k:statistics.median(d[k] for d in rs) for k in ['sta_estimate_mhz','lut','ff','delay_ns']}
        out['frequency_change_percent']=100*(out['candidate']['sta_estimate_mhz']/out['baseline']['sta_estimate_mhz']-1)
        out['throughput_ratio_by_q']={str(q):out['candidate']['sta_estimate_mhz']/out['baseline']['sta_estimate_mhz']*(q+12)/(q+14) for q in [1,2,4,8]}
        comparisons.append(out)
    result=dict(status='PASS_OPT03_SCOPE',date='2026-10-17',production_variant='candidate',
        RTL_changed=changed,latency=dict(valid='q+12',handshake='q+13',II_min='q+14',added_cycles=2),
        native_pilots=native,native_main=large,near_fraction_standalone_acc=near,
        modelsim=model,schedule=schedule,ppa=rows,comparisons=comparisons,baseline_reuse=reuse,
        limitations=['STA estimates at 10ns; positive hold checked, no board signoff',
            'Three directives per variant, not independent random seeds',
            'NF EXACT_EN1; no matched approximate-only NF/F conclusion',
            'No new formal/CDC/RDC or final per-n acceptance',
            'ModelSim10.1d uses verified equivalent typedef casts only in private LOD copy',
            'Native corpus generator is cycle-dependent; same seed does not imply the identical historical operand stream after retiming',
            'No numerical model or fused RTL change; Table I not rerun'])
    p=O/'summary.json'
    if not p.exists() or load('summary.json')!=result:p.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(comparisons,indent=2))
    print('AUDIT_OPT03_PASS')


def archive():
    assert load('summary.json')['status']=='PASS_OPT03_SCOPE'
    assert not (O/'evidence.zip').exists()
    skip={'obj_fast','obj_dir','work','tmp','.Xil','appdata','localappdata','__pycache__','-p'}
    suffix={'.sv','.vh','.hpp','.h','.cpp','.vlt','.tcl','.ps1','.py','.sh','.json','.txt','.rpt','.log','.csv','.sha256','.dat','.do'}
    files={}
    with zipfile.ZipFile(O/'evidence.zip','w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted(O.rglob('*')):
            if not p.is_file() or skip.intersection(p.relative_to(O).parts) or p.suffix not in suffix:continue
            if p.name=='archive_manifest.json':continue
            raw=p.read_bytes();name=p.relative_to(O).as_posix()
            files[name]=hashlib.sha256(raw).hexdigest();z.writestr(name,raw)
    with zipfile.ZipFile(O/'evidence.zip') as z:
        assert z.testzip() is None
        assert all(hashlib.sha256(z.read(k)).hexdigest()==v for k,v in files.items())
    (O/'archive_manifest.json').write_text(json.dumps(dict(files=files,archive_sha256=sha(O/'evidence.zip')),indent=2)+'\n')
    print('ARCHIVE_OPT03_PASS',len(files),(O/'evidence.zip').stat().st_size)


def restore():
    m=load('archive_manifest.json');assert sha(O/'evidence.zip')==m['archive_sha256']
    with zipfile.ZipFile(O/'evidence.zip') as z:
        assert set(z.namelist())==set(m['files'])
        for name,digest in m['files'].items():
            p=O/name
            assert p.resolve().is_relative_to(O.resolve())
            assert hashlib.sha256(z.read(name)).hexdigest()==digest
            if p.exists():assert sha(p)==digest, 'Preserve existing different file: '+name
        for name in m['files']:
            p=O/name
            if not p.exists():p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(z.read(name))
    print('RESTORE_OPT03_PASS')


if __name__=='__main__':
    assert len(sys.argv)==2 and sys.argv[1] in ['collect','archive','restore']
    globals()[sys.argv[1]]()
