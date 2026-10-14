"""Source-bound W11 distribution/functional audit, separate from final AC matrix."""
import argparse
import collections
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'results/ops_refactor_20261014/nf'
FORMATS = ((8, 0), (16, 1), (32, 2), (32, 3))
PACK_NAMES = ('up', 'down_inexact', 'tie_up', 'tie_hold', 'sat_max', 'sat_min', 'carry_regime')

def read(path):
    raw = path.read_bytes()
    return raw.decode('utf-16') if raw.startswith(b'\xff\xfe') else raw.decode('utf-8-sig')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def dump(path, obj):
    path.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

def source_paths():
    paths = list((ROOT / 'rtl').glob('*.sv'))
    paths += [ROOT / 'rtl/posit_mac.vh']
    paths += list((ROOT / 'l1/include').glob('*.hpp'))
    paths += [ROOT / ('tb/' + name) for name in (
        'nf_coverage_harness.cpp', 'nf_coverage_corpus.hpp', 'nf_coverage.vlt',
        'week11_model.hpp', 'week10_add_reference.hpp', 'week9_exact_reference.hpp',
        'tb_week11_mac.sv')]
    paths += [ROOT / ('scripts/' + name) for name in (
        'prepare_nf_coverage.sh', 'verify_ops_refactor_nf.sh',
        'verify_ops_refactor_nf_modelsim.ps1', 'audit_ops_refactor_nf.py')]
    paths += [ROOT / 'l1/test/gen_nf_coverage.cpp', ROOT / 'l0/softposit_api.h',
              ROOT / 'l0/libsoftposit.so']
    return {p.relative_to(ROOT).as_posix(): sha(p) for p in sorted(paths)}

def check_snapshot(folder):
    for line in read(folder / 'source.sha256').splitlines():
        digest, name = line.split(maxsplit=1)
        saved = folder / name
        assert sha(saved) == digest, ('Snapshot hash changed', saved)
        if saved.parent.name == 'l1':
            live = ROOT / 'l1/include' / saved.name
        elif saved.suffix in ('.sv', '.vh'):
            live = ROOT / 'rtl' / saved.name
        elif saved.suffix in ('.cpp', '.hpp', '.vlt'):
            live = ROOT / 'tb' / saved.name
        else:
            live = ROOT / 'l0' / saved.name
        assert saved.read_bytes() == live.read_bytes(), ('Live source changed', live)

def check_report(folder, prefix):
    data = json.loads(read(folder / (prefix + '_summary.json')))
    assert data['mismatches'] == 0
    assert 'NF COVERAGE HARNESS PASS' in read(folder / (prefix + '.log'))
    assert data['accepted'] == data['completed'] + data['reset_aborts']
    assert data['oracle_checks'] == data['accepted']
    assert sum(data['bins']) == data['completed'] and min(data['bins']) > 0
    assert sum(data['completed_standalone_acc']) == data['completed']
    assert data['product_packer_events'] == data['final_packer_events'] == data['completed']
    assert data['rtl_adder_checks'] >= data['completed']
    assert data['rtl_adder_checks'] <= data['accepted']
    assert all(data[k] > 0 for k in ('reset_busy', 'reset_stalled', 'long_stalls',
                                   'acc_commits', 'clears', 'invalid_checks'))
    assert data['first_valid_min'] == 11
    assert len(data['near_delta_standalone_acc']) == 10
    assert all(data['near_delta_standalone_acc']), 'Missing direct delta bin'
    assert sum(data['near_delta_standalone_acc']) * 10 >= 3 * data['completed'], 'Near <30%'
    for mode in range(2):
        near = sum(data['near_delta_standalone_acc'][5*mode:5*mode+5])
        assert near <= data['finite_add_standalone_acc'][mode]
        assert (data['finite_add_standalone_acc'][mode] +
                data['non_finite_add_standalone_acc'][mode] == data['completed_standalone_acc'][mode])
    # Popcount >8 and iteration >8 cannot occur in p8 (F=5).
    pop_valid = 5 if data['NB'] == 8 else 6
    assert all(data['popcount_bins'][:pop_valid])
    assert not any(data['popcount_bins'][pop_valid:])
    # Bypass gives t=0 in either mode. Approx <=N_MAX=8; exact may exceed eight.
    assert all(data['iteration_mode_bins'][7:13])
    assert data['iteration_mode_bins'][13] == 0
    assert all(data['iteration_mode_bins'][:6])
    if data['NB'] != 8:
        assert data['iteration_mode_bins'][6] > 0
    for i in range(7):
        assert data['product_packer_bins'][i] + data['final_packer_bins'][i] > 0, PACK_NAMES[i]
    # Both operands of final NF add are Posit values, integer multiples of minpos.
    # A nonzero exact sum cannot underflow below minpos. Product pack can underflow.
    assert data['final_packer_bins'][5] == 0
    return data

def structural(paths):
    points = collections.Counter()
    for path in paths:
        for line in read(path).splitlines():
            if line.startswith("C '"):
                key, count = line[3:].rsplit("' ", 1)
                points[key] += int(count)
    totals, hits = collections.Counter(), collections.Counter()
    unhit = []
    for key, count in points.items():
        fields = dict(x.split('\x02', 1) for x in key.split('\x01') if '\x02' in x)
        kind = fields['page'].split('/', 1)[0].removeprefix('v_')
        totals[kind] += 1
        hits[kind] += count > 0
        if not count:
            unhit.append(dict(kind=kind, file=fields.get('f'), line=fields.get('l'),
                              hierarchy=fields.get('h'), object=fields.get('o')))
    assert totals, 'Missing structural coverage'
    return dict(metrics={k:dict(hit=hits[k], total=totals[k], percent=100*hits[k]/totals[k])
                         for k in totals}, unhit_points=unhit, exclusions='None',
                scope='All Verilator verification hierarchy; toggle pilot only, line/branch pilot+main')

def audit(stage):
    frozen = json.loads(read(ROOT / 'results/l1_floor_rne_freeze/summary.json'))
    for name, digest in frozen['source_sha256'].items():
        assert sha(ROOT / name.replace(chr(92), '/')) == digest, ('Frozen L1 changed', name)
    assert read(RUN / 'fixture_status.txt').strip() == 'COMPLETE'
    for line in read(RUN / 'fixtures.sha256').splitlines():
        digest, name = line.split(maxsplit=1)
        assert sha(ROOT / name.replace(chr(92), '/')) == digest, ('Fixture changed', name)
    assert read(RUN / 'pilot_status.txt').strip() == 'COMPLETE'
    profiles = []
    for nb, es in FORMATS:
        folder = RUN / f'{nb}_{es}'
        assert not re.search(r'%Warning|%Error', read(folder / 'lint.log')), 'Strict lint'
        check_snapshot(folder)
        pilot = check_report(folder, 'pilot')
        assert pilot['completed'] >= 20000
        profiles.append(pilot)
    if stage == 'pilot':
        evidence = dict(stage='PILOT_PASS', seed_base=20261014,
                        source_sha256=source_paths(), pilot_profiles=profiles,
                        old_checkpoint_sha256=sha(ROOT / 'results/week11/baseline_nf_manifest.json'),
                        acceptance_goal=10000000, near_percent_min=30,
                        regime_cross_min=4000, finite_run_polarity_min=10000,
                        packer_bin_order=PACK_NAMES,
                        final_packer_exclusions={'sat_min': 'NF sum of two Posit values is an integer multiple of minpos'},
                        final_ac_scope='Not final per-n, exhaustive, F RTL, PPA or full AC04')
        dump(RUN / 'checkpoint_manifest.json', evidence)
        print('PILOT AUDIT PASS: four formats, 0 mismatch, distribution/counters verified; source sealed')
        return
    seal = json.loads(read(RUN / 'checkpoint_manifest.json'))
    assert source_paths() == seal['source_sha256'], 'Source changed after pilot seal'
    assert sha(ROOT / 'results/week11/baseline_nf_manifest.json') == seal['old_checkpoint_sha256']
    if stage == 'preflight':
        print('ACCEPTANCE PREFLIGHT PASS: pilot/source seal unchanged')
        return
    assert read(RUN / 'acceptance_status.txt').strip() == 'COMPLETE'
    main = check_report(RUN / '32_3', 'acceptance')
    assert main['completed'] >= seal['acceptance_goal']
    assert len(main['regime_sign_bins']) == 256 and min(main['regime_sign_bins']) >= 4000
    run_counts = [main['run_polarity_bins'][32*p+m]
                  for p in (0,1) for m in range(1,31+p)]
    assert len(run_counts) == 61 and min(run_counts) >= 10000
    invalid_runs = {0,31,32}
    assert all(main['run_polarity_bins'][i] == 0 for i in invalid_runs)
    required = [(0,1,0)] + [(0,0,c) for c in (2,3,4,5,6)]
    required += [(1,1,c) for c in (0,1)] + [(1,0,c) for c in (1,2,3,4,5)]
    required += [(d,s,c) for d in (2,3) for s in (0,1) for c in ((0,1) if s else (1,2))]
    required += [(4,1,1),(4,0,1),(4,0,2)]
    indices = {d*14+s*7+c for d,s,c in required}
    assert all(main['adder_bins'][i] > 0 for i in indices), 'Missing reachable adder bin'
    assert not any(n for i,n in enumerate(main['adder_bins']) if i not in indices)
    assert all(main['flag_bins'])
    assert read(RUN / 'modelsim/run_status.txt').strip() == 'COMPLETE'
    for name, digest in json.loads(read(RUN / 'modelsim/source_sha256.json')).items():
        assert sha(ROOT / name.replace(chr(92), '/')) == digest
    for nb, es in FORMATS:
        log = read(RUN / f'modelsim/simulate_{nb}_{es}.log')
        assert not re.search(r'\*\*\s+(Error|Fatal):', log)
        assert re.search(rf'W11 MODELSIM PASS NB={nb} ES={es} rows=7200 completed=7128 aborted=72 .*mismatches=0', log)
    raw = [RUN / '32_3/pilot_coverage.dat', RUN / '32_3/acceptance_coverage.dat']
    dump(RUN / 'structural_coverage.json', structural(raw))
    near = sum(main['near_delta_standalone_acc'])
    report = dict(status='PASS', milestone='W11 / Gate3 NF distribution and functional closure',
                  date='2026-10-14', completed=main['completed'], reset_aborts=main['reset_aborts'],
                  mismatches=0, near_completed=near, near_percent=100*near/main['completed'],
                  direct_delta_standalone_acc=main['near_delta_standalone_acc'],
                  completed_standalone_acc=main['completed_standalone_acc'],
                  regime_cross='256/256 >=4000', regime_cross_min=min(main['regime_sign_bins']),
                  run_polarity='61/61 finite valid runs >=10000', run_polarity_min=min(run_counts),
                  config_control='72/72', adder='24/24 reachable', adder_exclusions=46,
                  popcount='6/6', packer='7/7 union, directly observed RTL P1',
                  product_packer=dict(zip(PACK_NAMES, main['product_packer_bins'])),
                  final_packer=dict(zip(PACK_NAMES, main['final_packer_bins'])),
                  final_packer_exclusions=seal['final_packer_exclusions'],
                  modelsim_completed=4*7128, modelsim_reset_aborts=4*72,
                  old_numeric_checkpoint='Preserved, not combined in new near-cancellation denominator',
                  source_sha256=seal['source_sha256'],
                  limitations=['10M aggregate main 32/3; not 10M per n/profile',
                               'Structural toggle pilot only; no final AC04 claim',
                               'F full-sum pilot only; no F_W/RTL/flags/feedback acceptance',
                               'No full MAC STA/CDC/RDC/PPA, paired accuracy or author baseline provenance'])
    dump(RUN / 'summary.json', report)
    print(f"W11 COVERAGE AUDIT PASS completed={main['completed']} mismatch=0 near={100*near/main['completed']:.6f}%")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('stage', choices=('pilot','preflight','final'))
    audit(parser.parse_args().stage)
