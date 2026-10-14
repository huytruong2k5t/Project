"""Close W11 only when the new distribution suite and directed corners pass."""
import hashlib
import json
import re
from pathlib import Path
import audit_nf_coverage as base

ROOT=Path(__file__).resolve().parents[1]
RUN=ROOT/'results/nf_coverage_20261014'
CORNER=ROOT/'results/nf_corners_20261014'
base.audit('final')
assert base.read(CORNER/'modelsim/run_status.txt').strip()=='COMPLETE'
for filename in ('fixtures.sha256','generator_source.sha256'):
    for line in base.read(CORNER/filename).splitlines():
        digest,name=line.split(maxsplit=1)
        assert base.sha(ROOT/name)==digest,('Corner evidence changed',name)
for name,digest in json.loads(base.read(CORNER/'modelsim/source_sha256.json')).items():
    assert base.sha(ROOT/name)==digest
rows=[]
for nb,es in base.FORMATS:
    log=base.read(CORNER/f'modelsim/simulate_{nb}_{es}.log')
    assert not re.search(r'\*\*\s+(Error|Fatal):',log)
    assert re.search(rf'W11 MODELSIM PASS NB={nb} ES={es} rows=20736 completed=20736 aborted=0 .*mismatches=0',log)
    assert re.search(rf'CORNER {nb}/{es} rows=20736 max_iterations={nb-3-es} .*mismatches=0',
                     base.read(CORNER/'generator.log'))
    rows.append(dict(NB=nb,ES=es,completed=20736,aborted=0,mismatches=0,
                     max_exact_iterations=nb-3-es))
guards=json.loads(base.read(RUN/'audit_guard_tests.json'))
assert len(guards)==4 and all(v['rejected'] for v in guards.values())
core=json.loads(base.read(RUN/'summary.json'))
source_names=['l1/test/gen_nf_corners.cpp','scripts/prepare_nf_corners.sh',
              'scripts/verify_nf_corners_modelsim.ps1','scripts/test_nf_coverage_audit.py',
              'scripts/audit_nf_completion.py']
report=dict(status='PASS',date='2026-10-14',week11='COMPLETE within NF Gate3 milestone',
            core=core,corner_profiles=rows,corner_completed=4*20736,corner_mismatches=0,
            corner_scope='8 special/endpoint codes cubed x exact/approx x n0..8 x OPS0/1, plus 4x4 fraction patterns x 4 sign pairs; standalone; reset between groups, no reset-abort',
            core_scope='10M completed with standalone and accumulator sequences; near denominator excludes all reset-aborts and the supplemental corners',
            supplemental_source_sha256={p:base.sha(ROOT/p) for p in source_names},
            evidence_sha256={p.relative_to(ROOT).as_posix():base.sha(p) for p in
                [RUN/'summary.json',RUN/'checkpoint_manifest.json',RUN/'32_3/acceptance_summary.json',
                 RUN/'structural_coverage.json',RUN/'audit_guard_tests.json',
                 CORNER/'fixtures.sha256',CORNER/'generator_source.sha256']},
            remaining=core['limitations'])
base.dump(RUN/'completion.json',report)
base.dump(CORNER/'summary.json',dict(status='PASS',profiles=rows,completed=4*20736,mismatches=0))
print('W11 COMPLETION PASS: main10M/0 mismatch + ModelSim directed82,944/0 mismatch; final AC/F/PPA remain open')
