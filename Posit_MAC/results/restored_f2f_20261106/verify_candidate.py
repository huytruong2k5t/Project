"""Verify the measurement snapshot without changing live RTL or frozen sources."""
from pathlib import Path
import hashlib
import json
import os
import sys
from concurrent.futures import ThreadPoolExecutor

run = Path(__file__).resolve().parent
snapshot = run / 'candidate'
source = snapshot / 'source'
out = source / 'results' / 'verification'
out.mkdir(parents=True, exist_ok=True)
os.environ['SHARED_RESULTS_ROOT'] = str(out)
os.environ['SHARED_BUILD_TAG'] = 'lutreview2'
os.environ['SHARED_SEED'] = '20261106'
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
sys.path.insert(0, str(source / 'scripts'))

def check_sources():
    manifest = json.loads((snapshot / 'manifest.json').read_text())
    for rel, digest in manifest['sha256'].items():
        assert hashlib.sha256((source / rel).read_bytes()).hexdigest() == digest, rel

check_sources()
import audit_shared_multiplier
if (out / 'ports_and_lint.json').exists():
    lint = json.loads((out / 'ports_and_lint.json').read_text())
    assert lint['status'] == 'PASS'
    for rel, digest in lint['source_sha256'].items():
        assert hashlib.sha256((source / rel).read_bytes()).hexdigest() == digest, rel
    print('REUSED_MATCHING_STRICT_LINT_PASS', flush=True)
else:
    audit_shared_multiplier.main()
import verify_shared_multiplier as verifier

def verify_variant(kind):
    verifier.build(kind)
    verifier.run_mac(kind, 100000, 'mixed', -1, -1)
    result = json.loads((out / ('mixed_' + kind + '.json')).read_text())
    assert result['status'] == 'PASS' and result['completed'] == 100000
    assert result['mismatches'] == 0
    assert len(result['bins']) == 26 and all(result['bins'])
    return {'variant': kind, 'status': 'PASS', 'completed': result['completed'],
            'mismatches': 0, 'configuration_bins_hit': 26}

with ThreadPoolExecutor(max_workers=2) as pool:
    records = list(pool.map(verify_variant, ['nf', 'f']))
check_sources()
(snapshot / 'verify' / 'evidence.json').write_text(json.dumps({
    'status': 'PASS', 'strict_lint': '31 active module tops', 'records': records,
    'limits': 'Mixed 100k/variant regression with golden oracle and protocol/core checks; not full coverage signoff or raw adder-bus equivalence.'
}, indent=2) + '\n')
(snapshot / 'verify' / 'status.txt').write_text('PASS\n')
print('CANDIDATE_VERIFICATION_PASS', flush=True)
