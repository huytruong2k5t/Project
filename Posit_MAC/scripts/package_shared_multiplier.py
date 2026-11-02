#!/usr/bin/env python3
"""Preserve source/evidence only; never include caches, binaries or waves."""
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'results/shared_multiplier_20261102'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(name):
    return json.loads((OUT/name).read_text(encoding='utf-8-sig'))


def bundle(path, files):
    if path.exists():
        raise RuntimeError('Preserve existing archive: '+str(path))
    hashes = {name: sha(ROOT/name) for name in sorted(files)}
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        for name in hashes:
            z.write(ROOT/name, name)
        z.writestr('BUNDLE_MANIFEST.json', json.dumps(hashes, indent=2)+'\n')
    # Verify archive contents, not just the input directory.
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        for name, expected in hashes.items():
            assert hashlib.sha256(z.read(name)).hexdigest() == expected
    return hashes


def main():
    summary = load('summary.json')
    assert summary['status'] == 'PILOT_FUNCTION_VERIFIED_NOT_FINAL_RELEASE'
    sources = set()
    for name in ('build_units.json','build_nf.json','build_f.json',
                 'coverage_build_nf.json','coverage_build_f.json','model_check_receipt.json',
                 'ports_and_lint.json'):
        sources.update(load(name)['source_sha256'])
    sources.update(load('modelsim_signoff/manifest.json')['sha256'])
    # Fixture files belong to evidence, rather than the editable source bundle.
    sources = {name for name in sources if not name.startswith('results/')}
    sources.update(['Makefile','tb/reference/rtl/files.f',
                    'scripts/audit_shared_multiplier.py','scripts/run_shared_multiplier_matrix.py',
                    'scripts/run_shared_multiplier_coverage.py','scripts/summarize_shared_multiplier.py',
                    'scripts/package_shared_multiplier.py',
                    'README.md','SPEC_Posit_MAC_IP.md','Digital_Design_Guidelines.md',
                    'rtl/README.md','rtl/multiplier/README.md','rtl/common/README.md','tb/README.md',
                    'l1/PLAN.md','l1/README.md','docs/HUONG_DAN_CHAY_WSL_MODELSIM.md',
                    'docs/TIEN_DO_DO_AN.md','results/README.md'])
    source_zip = OUT/'verified_sources.zip'
    hashes = bundle(source_zip, sources)
    evidence = {p.relative_to(ROOT).as_posix() for p in OUT.glob('*.json')}
    evidence.update(p.relative_to(ROOT).as_posix() for p in OUT.glob('matrix_pilot_*.log'))
    for name in ('units.log','default_stress_nf.log','default_stress_f.log',
                 'coverage_stratified_nf.log','coverage_stratified_f.log',
                 'coverage_stratified_nf.json.dat','coverage_stratified_f.json.dat',
                 'build_nf_v7.log','build_f_v7.log','build_units_v6.log'):
        evidence.add((OUT/name).relative_to(ROOT).as_posix())
    for subdir, pattern in [('modelsim_signoff','manifest.json'),
                            ('modelsim_signoff/verify','*.log'),
                            ('modelsim_signoff/verify','status.txt'),
                            ('modelsim_signoff/vectors','*.txt'),
                            ('modelsim_signoff/vectors','*.json')]:
        evidence.update(p.relative_to(ROOT).as_posix() for p in (OUT/subdir).glob(pattern))
    evidence_zip = OUT/'verified_evidence.zip'
    bundle(evidence_zip, evidence)
    checkpoint = {'id':'POSIT_MAC_SHARED_FULL_TERM_20261102_PILOT',
                  'status':summary['status'], 'gate_status':'OPEN',
                  'profile':summary['profile'], 'source_sha256':hashes,
                  'summary_sha256':sha(OUT/'summary.json'),
                  'archives':{p.relative_to(ROOT).as_posix():sha(p)
                              for p in (source_zip,evidence_zip,
                                        ROOT/'archive/shared_multiplier_before_20261102.zip',
                                        ROOT/'archive/shared_multiplier_docs_before_20261102.zip')},
                  'remaining':summary['remaining'],
                  'limits':'Pilot checkpoint only. Does not replace historical production_freeze.json or claim original paper baseline.'}
    (ROOT/'rtl/shared_multiplier_checkpoint.json').write_text(json.dumps(checkpoint,indent=2)+'\n')
    print('SHARED_BUNDLE_PASS',len(sources),'source files',len(evidence),'evidence files',
          source_zip.stat().st_size,evidence_zip.stat().st_size)


if __name__ == '__main__':
    main()
