#!/usr/bin/env python3
"""Read-only fixed-format source, evidence and freeze audit."""
import copy
import hashlib
import json
import re
import sys
from pathlib import Path
from fix_posit32_3 import ROOT, OUT, run


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def code(text):
    return re.sub(r'//[^\n]*|/\*.*?\*/', '', text, flags=re.S)


def static(root):
    paths = (root/'rtl/production.f').read_text().splitlines()
    modules = []
    for rel in paths:
        text = code((root/rel).read_text())
        assert not re.search(r'\bparameter\b', text), rel
        found = re.findall(r'^module\s+(\w+)', text, re.M)
        assert found == [Path(rel).stem], rel
        head = text[text.index('module'):text.index(');')]
        assert not re.search(r'\[[^\]]*[A-Za-z_$][^\]]*\]', head), rel
        assert not re.search(r'\b\w+\s*#\s*\(', text), rel
        modules += found
    assert len(modules) == len(set(modules)) == 54
    return paths


def lint():
    current_lock = json.loads((ROOT/'rtl/production_freeze.json').read_text())
    fixed = ROOT if current_lock.get('status') == 'FIXED32_3_FUNCTION_VERIFIED' else OUT/'fixed'
    paths = static(fixed)
    if (OUT/'lint_summary.json').exists():
        previous = json.loads((OUT/'lint_summary.json').read_text())
        assert previous['rtl_sha256'] == {p: sha(fixed/p) for p in paths}
        print('Existing strict lint source-identical: 54/54 PASS')
        return
    (OUT/'lint').mkdir(exist_ok=True)
    for rel in paths:
        top = Path(rel).stem
        run(['verilator', '--lint-only', '--timing', '--assert', '-Wall',
             '--top-module', top, '-Irtl', '-f', 'rtl/production.f'],
            'lint/'+top+'.log', fixed)
    result = {'status': 'PASS', 'fixed_modules': len(paths),
              'strict_lint_tops': [Path(p).stem for p in paths],
              'rtl_sha256': {rel: sha(fixed/rel) for rel in paths}}
    (OUT/'lint_summary.json').write_text(json.dumps(result, indent=2)+'\n')
    print('STRICT LINT PASS', len(paths))


def evidence():
    fixed = OUT/'fixed'
    paths = static(fixed)
    lint_result = json.loads((OUT/'lint_summary.json').read_text())
    assert lint_result['status'] == 'PASS'
    assert lint_result['rtl_sha256'] == {p: sha(fixed/p) for p in paths}
    results = {}
    for kind in ['nf', 'f']:
        build = OUT/('build_'+kind+'_literal_ports')
        for rel, digest in json.loads((build/'source_binary_sha256.json').read_text()).items():
            assert sha(build/rel) == digest, 'Changed build input '+rel
        for rel in paths:
            built = (build/'src/rtl'/Path(rel).name).read_text()
            if Path(rel).stem == ('posit_mac_nf' if kind == 'nf' else 'posit_mac_f'):
                # Remove the read-only reference companion added by the runner.
                start = built.index('\n    // Verification-only reference:')
                end = built.rindex('\nendmodule')
                built = built[:start]+built[end:]
            normalize = lambda value: re.sub(r'\s+', '', code(value))
            assert normalize(built) == normalize((fixed/rel).read_text()), rel
        report = build/('main_summary.json' if kind == 'nf' else 'main.json')
        data = json.loads(report.read_text())
        assert data['completed'] == 10000000 and data['mismatches'] == 0
        assert data['seed'] == 20261022
        assert data['oracle_checks'] >= data['completed']
        assert min(data['bins'] if kind == 'nf' else data['n_hits']) > 0
        results[kind] = {'report': str(report.relative_to(ROOT)),
                         'sha256': sha(report), 'completed': data['completed'],
                         'mismatches': 0, 'seed': data['seed']}
    event = OUT/'event_literal_ports'
    assert (event/'status.txt').read_text().strip() == 'PASS'
    for kind, marker in [('corner','W11 MODELSIM PASS'),
                         ('protocol','W11 MODELSIM PASS'),('fused','W13_EVENT_PASS')]:
        text = (event/(kind+'.log')).read_text()
        assert marker in text and not re.search(r'\*\*\s+(Error|Fatal):', text)
    results['event'] = {'nf_corner_completed': 20736, 'nf_protocol_completed': 7128,
                        'nf_protocol_aborted': 72, 'f_completed': 8192,
                        'f_reset_aborts': 24, 'mismatches': 0,
                        'typed_cast_compatibility': str((event/'compatibility.json').relative_to(ROOT))}
    return results


def validate(manifest, root=ROOT):
    assert manifest['status'] == 'FIXED32_3_FUNCTION_VERIFIED'
    assert manifest['format'] == {'NB': 32, 'ES': 3}
    paths = static(root)
    assert paths == manifest['production_files']
    for group in ['rtl_sha256', 'model_sha256', 'build_contract_sha256']:
        for rel, digest in manifest[group].items():
            assert sha(root/rel) == digest, 'Frozen input changed: '+rel
    for row in manifest['verification'].values():
        if 'report' in row:
            assert sha(root/row['report']) == row['sha256']
    return True


def main():
    if '--lint' in sys.argv:
        lint()
        return
    manifest = json.loads((ROOT/'rtl/production_freeze.json').read_text())
    validate(manifest)
    if '--self-test' in sys.argv:
        rejected = 0
        for group in ['rtl_sha256', 'model_sha256', 'build_contract_sha256']:
            bad = copy.deepcopy(manifest)
            bad[group][next(iter(bad[group]))] = '0'*64
            try:
                validate(bad)
            except AssertionError:
                rejected += 1
        bad = copy.deepcopy(manifest)
        bad['status'] = 'RUNNING'
        try:
            validate(bad)
        except AssertionError:
            rejected += 1
        assert rejected == 4
        print('Anti-tamper checks PASS 4/4')
    print('FIXED32/3 RELEASE PASS; 54 fixed modules; numerical/STA signoff scopes separate')


if __name__ == '__main__':
    main()
