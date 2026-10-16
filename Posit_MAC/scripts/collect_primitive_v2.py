"""Collect measured primitive tradeoffs; never label an incomplete matrix PASS."""
from pathlib import Path
from collections import defaultdict
from statistics import median
import argparse
import csv
import hashlib
import json
import re

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/primitive_v2_20261016'


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--final',action='store_true');args=parser.parse_args()
    manifest=json.loads((OUT/'manifest.json').read_text())
    adoption_path=OUT/'adoption.json'
    adopted=json.loads(adoption_path.read_text()) if adoption_path.exists() else None
    dependency=json.loads((OUT/'dependency_sha256.json').read_text())
    assert sha(ROOT/'rtl/posit_mac.vh')==dependency['rtl/posit_mac.vh']
    for header in (OUT/'source').glob('*/posit_mac.vh'):
        assert sha(header)==dependency['rtl/posit_mac.vh']
    for name,digest in manifest['sources'].items():
        actual=sha(ROOT/name)
        if name.startswith('rtl/common/'):
            assert sha(OUT/'source/baseline'/Path(name).name)==digest
            if adopted:
                assert actual==adopted['source_sha256'][name]
                assert (ROOT/name).read_bytes()==(OUT/'source/lod_only'/Path(name).name).read_bytes()
        if actual!=digest:
            assert adopted and adopted['status']=='PROMOTED' and name.startswith('rtl/common/'),('Source changed',name)
            assert actual==adopted['source_sha256'][name]
            assert (ROOT/name).read_bytes()==(OUT/'source/lod_only'/Path(name).name).read_bytes()
            assert sha(OUT/'source/baseline'/Path(name).name)==digest
    for variant in ('baseline','group4','reverse','radix4','native'):
        for name in ('lod_lzd_core','dyn_left_shifter','dyn_right_shifter'):
            source=OUT/f'source/baseline/{name}.sv'
            if (variant=='group4' and name=='lod_lzd_core') or (variant in ('reverse','radix4','native') and name!='lod_lzd_core'):
                source=ROOT/f'rtl/candidates/primitives_v2/{variant}/{name}.sv'
            assert (OUT/f'source/{variant}/{name}.sv').read_bytes()==source.read_bytes(),('Snapshot changed',variant,name)
    for name in ('lod_lzd_core','dyn_left_shifter','dyn_right_shifter'):
        component='group4' if name=='lod_lzd_core' else 'reverse'
        assert (OUT/f'source/combined_reverse/{name}.sv').read_bytes()==(OUT/f'source/{component}/{name}.sv').read_bytes()
    verified={}
    variant_names=['group4','reverse','radix4','native']
    if (OUT/'mixed_manifest.json').exists():
        extra=json.loads((OUT/'mixed_manifest.json').read_text())
        assert sha(ROOT/extra['source'])==extra['sha256']
        assert sha(OUT/'source/group4_mixed/lod_lzd_core.sv')==extra['sha256']
        variant_names.append('group4_mixed')
    if (OUT/'release_manifest.json').exists():
        release=json.loads((OUT/'release_manifest.json').read_text())
        for name,digest in release['sources'].items():
            assert sha(ROOT/f'rtl/candidates/primitives_v2/selected/{name}.sv')==digest
            assert sha(OUT/f'source/selected/{name}.sv')==digest
        variant_names.append('selected')
        if (OUT/'source/lod_only').is_dir():
            for name in ('lod_lzd_core','dyn_left_shifter','dyn_right_shifter'):
                original=OUT/('source/selected' if name=='lod_lzd_core' else 'source/baseline')/(name+'.sv')
                assert (OUT/'source/lod_only'/(name+'.sv')).read_bytes()==original.read_bytes()
            variant_names.append('lod_only')
    for variant in variant_names:
        p=OUT/f'verification/{variant}/verification.json'
        if not p.exists():continue
        data=json.loads(p.read_text(encoding='utf-8-sig'))
        assert data['status']=='PASS' and data['mismatch']==0
        assert data['configurations']==138 and data['checks']>=3082416
        verified[variant]=data
    lint=(OUT/'lint/summary.txt').read_text() if (OUT/'lint/summary.txt').exists() else ''
    if (OUT/'lint/source.sha256').exists():
        for line in (OUT/'lint/source.sha256').read_text().splitlines():
            expected,name=line.split(None,1)
            assert sha(ROOT/name.strip())==expected,('Lint input changed',name)
    rows=[];completion={};sources={}
    for part in manifest['parts']:
        for phase in ('lod','lod_mixed','shift','chain','chain_extra','packer','confirm','release','adoption'):
            path=OUT/f'{part}/{phase}/metrics.csv'
            if not path.exists():continue
            data=list(csv.DictReader(path.open()))
            for r in data:
                assert int(r['latches'])==0 and int(r['unrouted'])==0, r['id']
                folder=path.parent/r['id']
                assert (folder/'utilization.rpt').is_file() and (folder/'setup.rpt').is_file()
                rows.append(dict(r,phase=phase,shift_w=int(r.get('shift_w') or (int(r['n'])-1).bit_length())))
            cases=OUT/f'{phase}_cases.tsv'
            expected_ids={line.split('\t')[0] for line in cases.read_text().splitlines() if line.strip()}
            expected=len(expected_ids)
            completion[part+'/'+phase]=dict(completed=len(data),expected=expected)
            assert len({r['id'] for r in data})==len(data)
            assert {r['id'] for r in data} <= expected_ids,('Unexpected measured case',path)
            lock=json.loads((path.parent/'input_sha256.json').read_text(encoding='utf-8-sig'))
            assert sha(cases)==lock['cases'],('Measured case list changed',cases)
            for name,digest in lock.items():
                if name!='cases':assert sha(ROOT/name)==digest,('Measured wrapper/driver changed',name)
            sources[path.relative_to(ROOT).as_posix()]=sha(path)
    groups=defaultdict(list)
    # Use the highest measured phase, avoiding duplicate weight. Release and
    # confirmation have the same wrappers/constraints and matched strategies.
    priorities=defaultdict(int)
    for r in rows:
        key=tuple(r[x] for x in ('part','variant','n','kind','mode','arith','fill','shift_w'))
        rank={'confirm':2,'release':3,'adoption':4}.get(r['phase'],1)
        priorities[key]=max(priorities[key],rank)
    for r in rows:
        key=tuple(r[x] for x in ('part','variant','n','kind','mode','arith','fill','shift_w'))
        if {'confirm':2,'release':3,'adoption':4}.get(r['phase'],1)!=priorities[key]:continue
        groups[key].append(r)
    comparison=[]
    for key,data in sorted(groups.items()):
        part,v,n,k,m,a,f,sw=key
        if v=='baseline':continue
        baseline=groups.get((part,'baseline',n,k,m,a,f,sw))
        if not baseline:continue
        def metrics(ds):
            freq=[1000/(5-float(d['slack'])) for d in ds]
            return dict(lut_median=median(int(d['lut']) for d in ds),ff=median(int(d['ff']) for d in ds),
                sta_mhz_min=min(freq),sta_mhz_median=median(freq),sta_mhz_max=max(freq),
                logic_ns_median=median(float(d['logic_ns']) for d in ds),
                route_ns_median=median(float(d['route_ns']) for d in ds),
                hold_min=min(float(d['hold']) for d in ds),runs=len(ds))
        base=metrics(baseline);candidate=metrics(data)
        lut_pct=100*(candidate['lut_median']/base['lut_median']-1)
        speed_pct=100*(candidate['sta_mhz_median']/base['sta_mhz_median']-1)
        comparison.append(dict(part=part,variant=v,n=int(n),kind=int(k),mode=int(m),arith=int(a),fill=int(f),shift_w=sw,
            baseline=base,candidate=candidate,lut_change_pct=lut_pct,sta_change_pct=speed_pct,
            physical_ff_changed=base['ff']!=candidate['ff'],
            tentative_timing_win=speed_pct>=5-1e-9 and lut_pct<=10+1e-9 and candidate['hold_min']>=0,
            selected_in_production=bool(adopted and v=='lod_only')))
    # Screen all shift architectures on A35T; A100T validates promising points
    # rather than rerunning architectures already dominated in screening.
    required=[f'{p}/{phase}' for p in manifest['parts'] for phase in ('lod','chain','chain_extra','packer','confirm')]
    required.append('xc7a35tcpg236-1/shift')
    if 'group4_mixed' in variant_names:required += [p+'/lod_mixed' for p in manifest['parts']]
    if 'selected' in variant_names:required += [p+'/release' for p in manifest['parts']]
    if 'lod_only' in variant_names:required += [p+'/adoption' for p in manifest['parts']]
    missing=[x for x in required if x not in completion or completion[x]['completed']!=completion[x]['expected']]
    netlist_checks=[]
    for log in [p for phase in ('confirm','release','adoption') for p in OUT.glob(f'*/{phase}/*/netlist_check/simulate.log')]:
        match=re.search(r'NETLIST_PASS checks=(\d+) mismatch=0',log.read_text())
        if match:
            netlist_checks.append(dict(log=log.relative_to(ROOT).as_posix(),checks=int(match[1]),sha256=sha(log)))
    expected_netlists=sum(r['phase'] in ('confirm','release','adoption') and r['strategy']=='default' for r in rows)
    integration=None
    if adopted and adopted.get('integration_status')=='PASS':
        integration=json.loads((ROOT/adopted['integration_evidence']).read_text())
        assert integration['status']=='PASS' and integration['mismatch']==0 and integration['strict_lint_profiles']==17
        assert len(integration['checks'])==3 and all(x['completed']==10000 and x['mismatch']==0 for x in integration['checks'].values())
        assert integration['source_common_lod_sha256']==sha(ROOT/'rtl/common/lod_lzd_core.sv')
    complete=not missing and len(verified)==len(variant_names) and len(netlist_checks)==expected_netlists and integration
    report=dict(status='PROCESSING' if missing else 'COMPLETE' if complete else 'MEASURED_COMPLETE_REVIEW_REQUIRED',date='2026-10-16',
        tool='Vivado 2026.1 build6511674',period_ns=5.0,strict_lint=lint.strip(),
        verification=verified,completion=completion,missing=missing,rows=comparison,
        production=adopted if adopted else 'Unchanged; a screening win alone never authorizes production replacement.',integration=integration,
        predeclared_review='Timing-first: >=5% median STA gain, <=10% physical LUT growth, identical declared RTL boundary banks, nonnegative hold. Report physical FF changes and verify netlist function/latency. Confirm worst-case behavior and chains on both parts. No threshold tuning; floating point comparisons use only roundoff epsilon.',
        limitations=['STA-derived estimates, not swept Fmax or on-board measurements.',
            'Default/Explore/Runtime are strategies, not independent random placement seeds.',
            'Identical declared boundary banks; implementation may replicate/merge FF. Report physical FF changes; inspect netlist before promotion.',
            'Synthetic OOC I/O delays, no board pins; assess R2R and I/O separately.',
            'No new pipeline or numeric changes. No whole-MAC speedup inferred.'],
        source_sha256=manifest['sources'],metrics_sha256=sources,
        netlist_verification=dict(cases=len(netlist_checks),checks=sum(x['checks'] for x in netlist_checks),
            mismatch=0,scope='Functional post-route default-strategy netlists and declared two-bank latency; no SDF timing simulation.',
            evidence=netlist_checks))
    if args.final:
        assert not missing,missing
        assert len(verified)==len(variant_names) and 'V2_STRICT_LINT_PASS' in lint
        assert len(netlist_checks)==expected_netlists,('Incomplete netlist checks',len(netlist_checks),expected_netlists)
        if adopted:assert integration,'Missing integration proof after source promotion'
    (OUT/'summary.json').write_text(json.dumps(report,indent=2)+'\n')
    flat=[]
    for r in comparison:
        flat.append({k:v for k,v in r.items() if k not in ('baseline','candidate')})
        flat[-1].update({'baseline_'+k:v for k,v in r['baseline'].items()})
        flat[-1].update({'candidate_'+k:v for k,v in r['candidate'].items()})
    if flat:
        with (OUT/'comparison.csv').open('w',newline='') as fp:
            w=csv.DictWriter(fp,fieldnames=list(flat[0]));w.writeheader();w.writerows(flat)
    print(json.dumps(dict(status=report['status'],runs=len(rows),missing=missing)))


if __name__=='__main__':main()
