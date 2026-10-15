"""Audit a path-only migration; never rewrite historical verification reports."""
from pathlib import Path
import ast
import hashlib
import json
import re
from rtl_paths import PATHS, ROOT, resolve_source

OUT = ROOT / 'results/layout_cleanup_20261015'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    migration = json.loads((OUT/'rtl_migration.json').read_text())
    for entry in migration['moves']:
        assert not (ROOT/entry['old']).exists(), entry['old']
        assert PATHS[entry['old']] == entry['new']
        assert sha(ROOT/entry['new']) == entry['sha256'], entry['new']
        assert resolve_source(ROOT/entry['old']) == ROOT/entry['new']
    tsv = dict(line.split('\t') for line in (ROOT/'scripts/rtl_paths.tsv').read_text().splitlines())
    assert tsv == PATHS
    sources = (ROOT/'rtl/production.f').read_text().splitlines()
    expected = {p for p in PATHS.values() if not any('/'+g+'/' in p for g in ('candidates','benchmarks','research'))}
    assert set(sources) == expected and len(sources) == len(expected)
    for name in sources:
        assert (ROOT/name).is_file(), name
    for name in (ROOT/'scripts/week13_sources.txt').read_text().splitlines():
        assert name in sources, name
    for path in (ROOT/'scripts').glob('*.py'):
        ast.parse(path.read_text(encoding='utf-8-sig'), filename=str(path))
    # Historical reports still name the measured source locations. Verify their
    # content hashes using the relocation map; do not rename keys or reissue PASS.
    historic_rtl = {}
    for name in ('week13/summary.json','primitive_xilinx_20261015/manifest.json'):
        data = json.loads((ROOT/'results'/name).read_text(encoding='utf-8-sig'))
        entries = data.get('source_sha256',data.get('sources',{}))
        count = 0
        for path, digest in entries.items():
            if path.startswith('rtl/'):
                assert sha(resolve_source(ROOT/path)) == digest, path
                count += 1
        historic_rtl[name] = count
    report = dict(status='PASS_PATH_ONLY', moved=len(PATHS), production_modules=len(sources),
                  rtl_bytes_unchanged=True, historic_rtl_hashes_checked=historic_rtl,
                  limits='This audit proves relocation integrity, not a new numerical or timing signoff.')
    nf = json.loads((OUT/'nf/smoke_summary.json').read_text())
    fused = json.loads((OUT/'fused/verilator/smoke.json').read_text())
    assert nf['completed'] == fused['completed'] == 10000
    assert nf['mismatches'] == fused['mismatches'] == 0
    assert len(list((OUT/'lint').glob('*.log'))) == 16
    for path in [*(OUT/'lint').glob('*.log'), OUT/'fused/lint.log']:
        assert not re.search(r'%Warning|%Error', path.read_text()), path
    model = ROOT/'results/week10_adder/layout_comb'
    assert (model/'run_status.txt').read_text().strip() == 'COMPLETE'
    model_rows = 0
    for path in model.glob('simulate_*.log'):
        text = path.read_text()
        match = re.search(r'W10 COMB PASS.*rows=(\d+) mismatches=0',text)
        assert match and not re.search(r'\*\*\s+(?:Error|Fatal):',text), path
        model_rows += int(match[1])
    assert model_rows == 143976
    event = (OUT/'fused/simulate/simulate.log').read_text()
    assert 'W13_EVENT_PASS completed=8192 reset_aborts=24 mismatch=0' in event
    report['verification'] = dict(strict_lint_profiles=17,
        NF=dict(completed=10000,mismatches=0,seed=nf['seed']),
        F=dict(completed=10000,mismatches=0,seed=fused['seed']),
        ModelSim=dict(cases=model_rows,mismatches=0,profiles=['8/0','16/1','32/2','32/3']),
        XSim=dict(completed=8192,reset_aborts=24,mismatches=0))
    initial = json.loads((OUT/'cleanup_initial.json').read_text(encoding='utf-8-sig'))
    final = json.loads((OUT/'cleanup.json').read_text(encoding='utf-8-sig'))
    assert initial['retained_hash_check'] == final['retained_hash_check'] == 'PASS'
    report['cleanup'] = dict(initial_bytes=initial['before_bytes'],
        removed_build_bytes=initial['reclaim_bytes']+final['reclaim_bytes'],
        remaining_bytes=sum(p.stat().st_size for p in (ROOT/'results').rglob('*') if p.is_file()),
        preserved_evidence_hash_check='PASS',
        note='New smoke evidence added between the two cleanup passes.')
    report['commands'] = [
        'bash scripts/verify_rtl_layout.sh',
        'powershell -NoProfile -File scripts/verify_week10_adder_comb.ps1 -FixtureRun pilot -RunName layout_comb',
        'powershell -NoProfile -File scripts/run_week13_xilinx.ps1 -Mode simulate -RunRoot results/layout_cleanup_20261015/fused',
        'powershell -NoProfile -File scripts/cleanup_results.ps1 -Apply',
        'python scripts/audit_rtl_layout.py']
    (OUT/'layout_audit.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
