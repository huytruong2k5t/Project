#!/usr/bin/env python3
"""Summarize retained evidence without promoting pilot results to signoff."""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'results/shared_multiplier_20261102'


def read(name):
    return json.loads((OUT / name).read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_guard(mapping):
    for relative, expected in mapping.items():
        if digest(ROOT / relative).lower() != expected.lower():
            raise RuntimeError('Evidence source differs: ' + relative)


def coverage(kind):
    raw = OUT / ('coverage_stratified_' + kind + '.json.dat')
    counters = {}
    misses = []
    for line in raw.read_text().splitlines():
        if not line.startswith('C '):
            continue
        fields = dict(token.split('\x02', 1)
                      for token in line.split("'", 2)[1].split('\x01')
                      if '\x02' in token)
        if '/rtl/' not in fields.get('f', ''):
            continue
        category = fields['page'].split('/')[0]
        count = int(line.rsplit(' ', 1)[1])
        pair = counters.setdefault(category, [0, 0])
        pair[0] += count > 0
        pair[1] += 1
        if not count:
            misses.append(fields)
    thresholds = {'v_line': 95, 'v_branch': 90, 'v_toggle': 85}
    metrics = {k: {'hit': v[0], 'total': v[1], 'percent': 100*v[0]/v[1],
                   'threshold_percent': thresholds[k],
                   'met': 100*v[0]/v[1] >= thresholds[k]}
               for k, v in counters.items()}
    result = {'variant': kind, 'metrics': metrics,
              'raw_sha256': digest(raw), 'excluded': 'Verification top only',
              'rtl_exclusions_applied': [], 'unhit_points': misses,
              'status': 'PASS' if all(v['met'] for v in metrics.values()) else 'OPEN',
              'limits': '20k mixed transactions. Point-hit ratios from Verilator counters; no automatic waivers for unhit RTL or assertion code.'}
    (OUT / ('coverage_review_' + kind + '.json')).write_text(json.dumps(result, indent=2)+'\n')
    return {k: v for k, v in result.items() if k != 'unhit_points'}


def main():
    manifests = {k: read('build_' + k + '.json') for k in ('units', 'nf', 'f')}
    for m in manifests.values():
        source_guard(m['source_sha256'])
    for kind in ('nf', 'f'):
        source_guard(read('coverage_build_' + kind + '.json')['source_sha256'])
    audit = read('ports_and_lint.json')
    source_guard(audit['source_sha256'])
    source_guard(read('model_check_receipt.json')['source_sha256'])
    ms = read('modelsim_signoff/manifest.json')
    source_guard(ms['sha256'])
    markers = {}
    for kind, token in [('adder', 'ADDER_REFACTOR_PASS'), ('packer', 'PACKER_REFACTOR_PASS'),
                        ('core', 'SHARED_CORE_PASS'), ('nf', 'MAC_REFACTOR_PASS'),
                        ('f', 'MAC_REFACTOR_PASS')]:
        path = OUT / 'modelsim_signoff/verify' / (kind + '.log')
        hits = [line.strip().removeprefix('# ').strip()
                for line in path.read_text(errors='replace').splitlines() if token in line]
        if len(hits) != 1:
            raise RuntimeError('Missing unique ModelSim PASS: ' + kind)
        markers[kind] = {'marker': hits[0], 'log_sha256': digest(path)}
    units, model, matrix = [read(n + '.json') for n in ('units', 'model_check', 'matrix_pilot_summary')]
    stress = {k: read('default_stress_' + k + '.json') for k in ('nf', 'f')}
    for report in [units, model, matrix, *stress.values()]:
        assert report['status'] == 'PASS' and report['mismatches'] == 0
    # Verify every point rather than trusting only the aggregate report.
    for kind in ('nf', 'f'):
        for ops in range(2):
            for n in range(13):
                point = read(f'matrix_pilot_{kind}_ops{ops}_n{n}.json')
                assert point['completed'] == 100000 and point['mismatches'] == 0
                assert point['accepted'] == point['completed'] + point['reset_aborted']
    cov = {kind: coverage(kind) for kind in ('nf', 'f')}
    summary = {
        'date': '2026-11-02', 'status': 'PILOT_FUNCTION_VERIFIED_NOT_FINAL_RELEASE',
        'profile': 'POSIT32_ES3_APPROX12_FULL_TERM26_Q24', 'seed': 20261102,
        'modelsim_fixture_seed': 20261101,
        'tools': {'verilator': manifests['nf']['verilator'], 'compiler': manifests['nf']['compiler'],
                  'modelsim': 'ModelSim ALTERA STARTER EDITION 10.1d'},
        'sources_verified_against_builds': True,
        'port_audit': {k: audit[k] for k in ('active_modules', 'strict_lint_tops', 'instances_checked',
                      'pnr_clock_primitive_bindings_checked', 'missing_or_empty_ports')},
        'unit_comparisons': sum(units[k] for k in ('ops', 'ops_metadata', 'sac', 'sbm', 'accumulator', 'normalizer')),
        'units': units, 'model': model, 'matrix_pilot': matrix,
        'default_stress': {k: {f: r[f] for f in ('completed', 'accepted', 'reset_aborted', 'mismatches', 'stage_checks')}
                           for k, r in stress.items()},
        'verilator_final_completed_excluding_exploratory': matrix['completed'] + sum(r['completed'] for r in stress.values()),
        'modelsim': markers, 'coverage': cov,
        'gate_status': 'OPEN',
        'remaining': ['52 points x 10M completed (520M) not run on current source',
                      'Per-point regime quota >=4000 not met by pilot (min NF188/F189)',
                      'AC04 raw line/branch coverage below thresholds; review unhit points and add targeted tests',
                      'Paired accuracy and matched synthesis/route PPA not rerun for FULL_TERM',
                      'Quire extension is a contract, not implemented RTL'],
        'limits': ['No exhaustive raw32 A/B/C input space claim',
                   'All legal output flag codes observed as a union across the 52-point pilot, not every flag per configuration',
                   'Factorized unit domains are not a Cartesian exhaustion of full MAC state',
                   'No proof of original paper RTL/provenance or Table I reproduction'],
        'commands': ['python3 -B scripts/audit_shared_multiplier.py',
                     'SHARED_BUILD_TAG=<fresh> make build',
                     'python3 -B scripts/verify_shared_multiplier.py units',
                     'python3 -B scripts/run_shared_multiplier_matrix.py --count 100000 --label <fresh>',
                     'python3 -B scripts/verify_shared_multiplier.py run nf 1000000 <fresh> 12 1',
                     'python3 -B scripts/verify_shared_multiplier.py run f 1000000 <fresh> 12 1',
                     'python3 -B scripts/run_shared_multiplier_coverage.py --tag <fresh> --label <fresh>',
                     'python3 -B scripts/check_shared_model.py',
                     'powershell.exe -NoProfile -File scripts/run_refactored_mac.ps1 -Stage Verify -RunRoot <fresh> -VectorCount 30000']}
    (OUT / 'summary.json').write_text(json.dumps(summary, indent=2)+'\n')
    print('SHARED_SUMMARY', summary['status'], 'units='+str(summary['unit_comparisons']),
          'MAC_completed='+str(summary['verilator_final_completed_excluding_exploratory']), 'mismatches=0 Gate=OPEN')
    for kind, result in cov.items():
        print(kind, {k: round(v['percent'], 3) for k, v in result['metrics'].items()})


if __name__ == '__main__':
    main()
