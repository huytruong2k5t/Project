#!/usr/bin/env python3
"""Build the integer/L1/fixture cross-check inside the project, record inputs."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'results/shared_multiplier_20261102'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--fixtures', default='results/shared_multiplier_20261102/modelsim_signoff/vectors')
    args = parser.parse_args()
    fixtures = (ROOT / args.fixtures).resolve()
    if not fixtures.is_relative_to(ROOT):
        parser.error('Fixture directory must stay in project')
    paths = [ROOT/'tb/shared_multiplier_model_check.cpp', ROOT/'tb/opt17/full_term_reference.hpp',
             ROOT/'tb/week12_fused_reference.hpp', Path(__file__).resolve()]
    paths += list((ROOT/'l1/include').glob('*.hpp'))
    paths += [fixtures/'nf.txt', fixtures/'f.txt']
    hashes = {p.relative_to(ROOT).as_posix(): sha(p) for p in paths}
    binary = OUT/'model_check_recorded'
    command = ['g++', '-O3', '-std=c++17', '-Itb/opt17', '-Itb', '-Il1/include',
               'tb/shared_multiplier_model_check.cpp', '-o', str(binary.relative_to(ROOT))]
    env = os.environ.copy()
    (OUT/'tmp').mkdir(exist_ok=True)
    env['TMPDIR'] = str(OUT/'tmp')
    subprocess.run(command, cwd=ROOT, env=env, check=True, capture_output=True, text=True)
    run = [str(binary), str(fixtures)]
    result = subprocess.run(run, cwd=ROOT, env=env, check=True, capture_output=True, text=True)
    for relative, expected in hashes.items():
        assert sha(ROOT/relative) == expected, 'Source changed during check: '+relative
    report = json.loads(result.stdout)
    assert report['status'] == 'PASS' and report['mismatches'] == 0
    (OUT/'model_check.json').write_text(json.dumps(report, indent=2)+'\n')
    receipt = {'build_command': command, 'run_command': run,
               'source_sha256': hashes, 'binary_sha256': sha(binary),
               'compiler': subprocess.check_output(['g++', '--version'], text=True).splitlines()[0],
               'seed': 20261102, 'python_fixture_seed': 20261101,
               'scope': 'L1, independent integer oracle, Python ModelSim fixtures'}
    (OUT/'model_check_receipt.json').write_text(json.dumps(receipt, indent=2)+'\n')
    print('SHARED_MODEL_PASS', report)


if __name__ == '__main__':
    main()
