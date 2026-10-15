"""Audit isolated normalization trials without promoting production RTL."""
import hashlib
import json
from pathlib import Path
import re
import statistics

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'results/normalize_refactor_20261015'


def read(path):
    return path.read_text(encoding='utf-8-sig')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path):
    return json.loads(read(path))


def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')


def check_sources(mapping):
    for name, digest in mapping.items():
        assert sha(ROOT/name) == digest, ('Source changed', name)


def interface(path):
    text = read(path).split('    localparam int Q', 1)[0]
    text = text[text.index('module '):]
    for variant in ['zero', 'shared']:
        text = text.replace('posit_add_normalize_'+variant, 'posit_add_normalize')
    return re.sub(r'\s+', '', re.sub(r'//[^\n]*', '', text))


before = ROOT/'rtl/posit_add_normalize.sv'
assert sha(before) == sha(RUN/'before/posit_add_normalize.sv'), 'Production leaf changed'
for variant in ['zero', 'shared']:
    candidate = ROOT/f'rtl/posit_add_normalize_{variant}.sv'
    assert interface(before) == interface(candidate), 'Parameter or port change'
    # Special canonicalization and all metadata logic stay identical.
    assert read(candidate).split('        sticky = alignment_tail', 1)[1].split('endmodule')[0] == read(before).split('        sticky = alignment_tail', 1)[1].split('endmodule')[0]
    assert "is_zero = is_zero_in || !(leading_valid || carry);" in read(candidate)
    assert 'logic [Q-1:0] normalized;' in read(candidate)
    assert '.N (Q),' in read(candidate)

assert read(RUN/'modelsim/status.txt').strip() == 'COMPLETE'
matrix = load(RUN/'modelsim/summary.json')
assert matrix['status'] == 'PASS' and matrix['mismatches'] == 0
assert len(matrix['profiles']) == 11 and matrix['candidates'] == 2
assert matrix['checks'] == sum(p['checks'] for p in matrix['profiles'])
assert all(all(p[k] > 0 for k in ['shift_bins', 'zero_clean', 'zero_prior_inexact',
    'nar_zero', 'carry', 'retained_only', 'tail_only']) for p in matrix['profiles'])
check_sources(matrix['source_sha256'])
assert read(RUN/'lint/status.txt').strip() == 'COMPLETE'
leaf_logs = [p for p in (RUN/'lint').glob('*.log') if p.name != 'version.log']
assert len(leaf_logs) == 22
assert all(not re.search(r'%Warning|%Error', read(p)) for p in leaf_logs)

assert read(RUN/'integration/status.txt').strip() == 'COMPLETE'
integration = []
for variant in ['zero', 'shared']:
    candidate = ROOT/f'rtl/posit_add_normalize_{variant}.sv'
    for nb, es in [(8, 0), (16, 1), (32, 2), (32, 3)]:
        folder = RUN/'integration'/variant/f'{nb}_{es}'
        assert not re.search(r'%Warning|%Error', read(folder/'lint.log'))
        copied = read(folder/'src/posit_add_normalize.sv')
        assert copied == read(candidate).replace('module posit_add_normalize_'+variant+' #(', 'module posit_add_normalize #(')
        assert sha(folder/'src/posit_add_align.sv') == sha(ROOT/'rtl/posit_add_align.sv'), 'Alignment was also substituted'
        for line in read(folder/'source.sha256').splitlines():
            digest, name = line.split(maxsplit=1)
            assert sha(folder/name) == digest, ('Integration source changed', variant, nb, es, name)
        for stage in ['pilot']+(['trial'] if (nb, es) == (32, 3) else []):
            report = load(folder/f'{stage}_summary.json')
            assert report['mismatches'] == 0
            assert report['completed'] >= (1000000 if stage == 'trial' else 50000)
            assert report['accepted'] == report['completed'] + report['reset_aborts']
            assert report['max_slots'] == 3 and report['reset_busy'] and report['reset_output_stall'] and report['long_stalls']
            assert report['L0_RNE_checks'] == (0 if es == 3 else report['accepted'])
            assert 'W10 HARNESS PASS' in read(folder/f'{stage}.log')
            integration.append(dict(variant=variant, stage=stage, **report))

assert read(RUN/'ppa/status.txt').strip() == 'COMPLETE'
ppa = load(RUN/'ppa/summary.json')
assert ppa['status'] == 'MEASURED' and len(ppa['rows']) == 9
check_sources(ppa['source_sha256'])
paths = []
for row in ppa['rows']:
    folder = RUN/'ppa'/f"{row['variant']}_seed{row['seed']}"
    selected = before if row['variant'] == 'before' else ROOT/f"rtl/posit_add_normalize_{row['variant']}.sv"
    text = read(selected)
    if row['variant'] != 'before':
        text = text.replace('module posit_add_normalize_'+row['variant']+' #(', 'module posit_add_normalize #(')
    assert read(folder/'src/posit_add_normalize.sv') == text
    for name in ['lod_lzd_core.sv', 'dyn_left_shifter.sv', 'normalize_ppa_boundary.sv', 'normalize_ppa_top.sv', 'posit_mac.vh']:
        assert sha(folder/'src'/name) == sha(ROOT/'rtl'/name)
    fit = read(folder/'output_files/normalize.fit.summary')
    report = read(folder/'output_files/normalize.sta.rpt')
    mapping = read(folder/'output_files/normalize.map.rpt')
    assert int(re.search(r'Total combinational functions\s*:\s*([\d,]+)', fit)[1].replace(',', '')) == row['LUT4']
    assert int(re.search(r'Total registers\s*:\s*([\d,]+)', fit)[1].replace(',', '')) == row['registers']
    assert not re.search(r'inferred.*latch|latch.*inferred', mapping, re.I)
    section = report.split("; Slow 1200mV 85C Model Setup: 'clk'", 1)[1]
    top = []
    for line in section.splitlines():
        fields = [x.strip() for x in line.strip().strip(';').split(';')]
        if len(fields) == 8 and re.fullmatch(r'-?\d+\.\d+', fields[0]):
            top.append(dict(slack_ns=float(fields[0]), startpoint=fields[1], endpoint=fields[2],
                clock_skew_ns=float(fields[6]), data_delay_ns=float(fields[7])))
            if len(top) == 10:
                break
    assert len(top) == 10 and top[0]['slack_ns'] == row['setup_wns_ns']
    corners = []
    for model in ['Slow 1200mV 85C', 'Slow 1200mV 0C', 'Fast 1200mV 0C']:
        item = {'model': model}
        for kind in ['Setup', 'Hold']:
            match = re.search(r';\s*'+re.escape(model)+rf' Model {kind} Summary.*?;\s*clk\s*;\s*(-?[\d.]+)\s*;\s*(-?[\d.]+)', report, re.S)
            assert match
            item[kind.lower()+'_wns_ns'] = float(match[1])
            item[kind.lower()+'_tns_ns'] = float(match[2])
        corners.append(item)
    arithmetic = re.search(r'-- arithmetic mode\s*;\s*(\d+)', mapping)
    paths.append(dict(variant=row['variant'], seed=row['seed'], timing_corners=corners,
        arithmetic_mode_cells=int(arithmetic[1]) if arithmetic else None, top10_setup=top))
dump(RUN/'ppa/critical_paths.json', paths)

baseline_rows = [r for r in ppa['rows'] if r['variant'] == 'before']
bmed = statistics.median(r['fmax_MHz'] for r in baseline_rows)
comparisons = []
for variant in ['before', 'zero', 'shared']:
    rows = [r for r in ppa['rows'] if r['variant'] == variant]
    assert {r['seed'] for r in rows} == {1, 2, 3}
    median = statistics.median(r['fmax_MHz'] for r in rows)
    comparisons.append(dict(variant=variant, lut4=sorted({r['LUT4'] for r in rows}),
        registers=sorted({r['registers'] for r in rows}), median_fmax_MHz=median,
        fmax_gain_percent=(median/bmed-1)*100,
        median_setup_wns_ns=statistics.median(r['setup_wns_ns'] for r in rows),
        meets_100MHz_all_seeds=all(r['setup_wns_ns'] >= 0 for r in rows), rows=rows))
sources = dict(matrix['source_sha256'], **ppa['source_sha256'])
for name in ['scripts/verify_normalize_refactor.sh', 'scripts/audit_normalize_refactor.py',
             'tb/week10_adder_harness.cpp', 'tb/week10_add_reference.hpp', 'tb/adder_verification_top.sv']:
    sources[name] = sha(ROOT/name)
summary = dict(status='PASS_ISOLATED_SURVEY', date='2026-10-15', production_replaced=False,
    interface='same parameters/defaults/ports; candidate module names differ',
    unit_vectors=matrix['checks'], unit_candidates=2, unit_mismatches=0,
    strict_lint_leaf_profiles=22, strict_lint_integration_profiles=8, inferred_latches=0,
    integration_completed=sum(r['completed'] for r in integration),
    integration_reset_aborts=sum(r['reset_aborts'] for r in integration),
    integration_mismatches=0, integration=integration,
    benchmark=dict(device=ppa['device'], clock_ns=10, profile=ppa['profile'],
        comparisons=comparisons, hold_all_corners_pass=all(c['hold_wns_ns'] >= 0 for p in paths for c in p['timing_corners'])),
    source_sha256=sources,
    limits=['Known binary input equivalence; no formal exhaustive HDL proof or X/Z behavior guarantee',
        'Unit magnitude/scale exhaustive only for small F2/SF_W<=8, metadata distributed rather than exhaustive cross-product',
        'Separate normalize candidates; production alignment and stage boundaries unchanged',
        'One million ES3 trial and four-format pilots per candidate, not full frozen NF/Gate3 regression',
        'LUT4 physical leaf benchmark, not whole adder/MAC, Xilinx LUT6 or board/power signoff',
        'Arithmetic-mode cell count alone does not prove a single physical adder',
        'ModelSim legacy replication-zero warning on F2 baseline/candidates retained; strict Verilator lint has no warning waiver',
        'Untimed cycle harness suppresses CK2Q ASSIGNDLY only; separate --timing lint has no waiver'],
    commands=['powershell -NoProfile -File scripts/verify_normalize_refactor_modelsim.ps1',
        'bash scripts/verify_normalize_refactor.sh',
        'powershell -NoProfile -File scripts/run_normalize_refactor_ppa.ps1',
        'python scripts/audit_normalize_refactor.py'])
dump(RUN/'summary.json', summary)
print(json.dumps({k: summary[k] for k in ['status', 'unit_vectors', 'unit_mismatches',
    'integration_completed', 'integration_reset_aborts', 'integration_mismatches']}, indent=2))
print(json.dumps(comparisons, indent=2))
