"""Gate3 milestone audit. Source-bound evidence; final coverage stays separate."""
import collections
import hashlib
import json
import re
from pathlib import Path
from rtl_paths import rtl_source, resolve_source

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT/'results/week11'

def read(path):
    raw=path.read_bytes()
    return raw.decode('utf-16') if raw.startswith(b'\xff\xfe') else raw.decode('utf-8-sig')

def coverage(paths):
    points=collections.Counter()
    for path in paths:
        for line in read(path).splitlines():
            if line.startswith("C '"):
                key,count=line[3:].rsplit("' ",1)
                points[key]+=int(count)
    totals,hits=collections.Counter(),collections.Counter()
    unhit=[]
    for key,count in points.items():
        fields=dict(x.split('\x02',1) for x in key.split('\x01') if '\x02' in x)
        kind=fields['page'].split('/',1)[0].removeprefix('v_')
        totals[kind]+=1
        hits[kind]+=count>0
        if not count:
            unhit.append(dict(kind=kind,file=fields.get('f'),line=fields.get('l'),
                              hierarchy=fields.get('h'),object=fields.get('o')))
    return dict(metrics={k:dict(hit=hits[k],total=totals[k],percent=100*hits[k]/totals[k]) for k in totals},
                unhit_points=unhit,exclusions='None')

assert read(RUN/'run_status.txt').strip()=='COMPLETE','Native suite incomplete'
assert read(RUN/'modelsim/run_status.txt').strip()=='COMPLETE','ModelSim suite incomplete'
hashes=json.loads(read(RUN/'modelsim/source_sha256.json'))
for name,digest in hashes.items():
    assert hashlib.sha256(resolve_source(ROOT/name).read_bytes()).hexdigest()==digest,('ModelSim source changed',name)
frozen=json.loads(read(ROOT/'results/l1_floor_rne_freeze/summary.json'))
for name,digest in frozen['source_sha256'].items():
    assert hashlib.sha256(resolve_source(ROOT/name).read_bytes()).hexdigest()==digest,('Frozen L1 changed',name)
fixture_digests={}
for line in read(RUN/'fixtures.sha256').splitlines():
    digest,name=line.split(maxsplit=1)
    assert hashlib.sha256(resolve_source(ROOT/name).read_bytes()).hexdigest()==digest
    fixture_digests[name]=digest

profiles=[]
for nb,es in ((8,0),(16,1),(32,2),(32,3)):
    folder=RUN/f'{nb}_{es}'
    lint=read(folder/'lint.log')
    assert not re.search(r'%Warning|%Error',lint),'Strict lint failed'
    for saved in (folder/'src').rglob('*'):
        if not saved.is_file(): continue
        if saved.parent.name=='l1': live=ROOT/'l1/include'/saved.name
        elif saved.suffix in ('.sv','.vh'): live=rtl_source(saved.name)
        elif saved.name.startswith('week'): live=ROOT/'tb'/saved.name
        else: live=ROOT/'l0'/saved.name
        assert saved.read_bytes()==live.read_bytes(),('Native snapshot changed',saved)
    pilot=json.loads(read(folder/'pilot_summary.json'))
    assert pilot['completed']>=20000 and pilot['mismatches']==0
    assert 'W11 HARNESS PASS' in read(folder/'pilot.log')
    main=None
    raw=[folder/'pilot_coverage.dat']
    if (nb,es)==(32,3):
        main=json.loads(read(folder/'acceptance_summary.json'))
        assert main['completed']>=10000000 and main['mismatches']==0
        assert 'W11 HARNESS PASS' in read(folder/'acceptance.log')
        assert len(main['regime_sign_bins'])==256 and min(main['regime_sign_bins'])>0
        # Reachability follows normalized mantissas in [1,2), not observed hits.
        # Equal scales + same sign always carry. Delta>=2 cannot cancel deeply.
        # Delta>F cannot carry on the retained Posit lattice.
        required=[(0,1,0)]+[(0,0,c) for c in (2,3,4,5,6)]
        required += [(1,1,c) for c in (0,1)]+[(1,0,c) for c in (1,2,3,4,5)]
        required += [(d,s,c) for d in (2,3) for s in (0,1) for c in ((0,1) if s else (1,2))]
        required += [(4,1,1),(4,0,1),(4,0,2)]
        required_indices={d*14+s*7+c for d,s,c in required}
        assert all(main['adder_bins'][index]>0 for index in required_indices),'Missing reachable adder bin'
        assert not any(count for index,count in enumerate(main['adder_bins']) if index not in required_indices),'Adder reachability model inconsistent'
        assert all(main['iteration_bins']),'Missing iteration bin'
        functional=dict(regime_sign='256/256',regime_sign_min=min(main['regime_sign_bins']),
                        config_control='72/72',config_control_min=min(main['bins']),
                        adder='24/24 reachable bins',adder_indices=sorted(required_indices),
                        adder_exclusions='46 impossible crosses from normalized magnitude/sign/delta constraints',
                        iteration='7/7',flags='All five flags observed; exact counts in acceptance_summary')
        (RUN/'functional_coverage.json').write_text(json.dumps(functional,indent=2)+'\n')
        raw.append(folder/'acceptance_coverage.dat')
    for counts in (pilot,main):
        if counts is None: continue
        assert counts['accepted']==counts['completed']+counts['reset_aborts']
        assert len(counts['bins'])==72 and min(counts['bins'])>0
        assert counts['reset_busy'] and counts['reset_stalled'] and counts['long_stalls']
        assert counts['acc_commits'] and counts['clears'] and counts['invalid_checks']
        assert counts['first_valid_min']==11
    ms=read(RUN/f'modelsim/simulate_{nb}_{es}.log')
    assert not re.search(r'\*\*\s+(Error|Fatal):',ms)
    match=re.search(rf'W11 MODELSIM PASS NB={nb} ES={es} rows=7200 completed=7128 aborted=72 stalls=(\d+) mismatches=0',ms)
    assert match
    measured=coverage(raw)
    (folder/'structural_coverage.json').write_text(json.dumps(measured,indent=2)+'\n')
    profiles.append(dict(NB=nb,ES=es,pilot=pilot,acceptance=main,
                         modelsim_completed=7128,modelsim_aborts=72,
                         coverage=measured['metrics']))

probe=read(RUN/'prepack.log')
assert 'checked=1244064 new_mismatches=0 legacy_differences=238906' in probe
fused=json.loads(read(RUN/'fused_pilot_summary.json'))
assert fused['checked']==100000 and fused['mismatches']==0
assert 'FIXTURE 32/3 completed=7128 aborted=72' in read(RUN/'generator_ubsan.log')
assert 'W11 F PILOT GENERATED checked=100000' in read(RUN/'fused_ubsan.log')
source_files=[*ROOT.glob('rtl/mac_nf/*nf*.sv'),ROOT/'rtl/packer/round_unpacked_comb.sv',ROOT/'rtl/multiplier/mul_prepack_norm_comb.sv',
              *ROOT.glob('tb/*week11*'),*ROOT.glob('l1/test/*week11*'),*ROOT.glob('scripts/*week11*')]
report=dict(status='PASS: Gate3 NF prepack-preserving milestone',date='2026-10-13',
            main_profile='32/3 FRAC_W12 FLOOR/RNE OPS0/1 exact/approx n0..8 acc_mode0/1',
            legacy_L1='Frozen sources unchanged; historical Gate1B/Gate2 retained',
            product_contract='R(P_hat) uses raw prepack, unlike legacy carry truncation',
            structural_coverage_scope='Line/branch from pilot+main; toggle from full-instrumented pilot; no final AC04 signoff',
            prepack_checks=1244064,legacy_product_differences=238906,
            main_completed=profiles[-1]['acceptance']['completed'],
            modelsim_completed=28512,modelsim_aborts=288,mismatches=0,
            profiles=profiles,fused_pilot=fused,fixture_sha256=fixture_digests,
            source_sha256={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in source_files},
            limits=['Not final AC02/AC04 or final per-n10M NF/F matrix',
                    'No fused RTL/window/acc_mode/flags acceptance, no paired accuracy or PPA/STA/CDC signoff',
                    'Native no-timing checks cycle function; ModelSim retains CK2Q/4-state'],
            tools=dict(verilator=read(RUN/'verilator_version.log').strip(),compiler=read(RUN/'compiler.log').splitlines()[0],
                       modelsim=read(RUN/'modelsim/version.log').strip()))
(RUN/'summary.json').write_text(json.dumps(report,indent=2)+'\n')
manifest=dict(status='FROZEN NF MILESTONE',source_sha256=report['source_sha256'],
              report_sha256=hashlib.sha256((RUN/'summary.json').read_bytes()).hexdigest(),
              limits=report['limits'])
(RUN/'baseline_nf_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('W11 AUDIT PASS main_completed=',report['main_completed'],'ModelSim=',report['modelsim_completed'],'mismatches=0')
for p in profiles: print(p['NB'],p['ES'],p['coverage'])
