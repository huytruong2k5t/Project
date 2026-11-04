"""Source-bound synthesis-only measurement; recover reports from existing DCP.

No implementation, routing or bitstream. Never modifies a frozen source snapshot.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('snapshot', type=Path)
    ap.add_argument('variant', choices=['nf', 'f'])
    ap.add_argument('--vivado', default='vivado')
    ap.add_argument('--report-only', action='store_true')
    args = ap.parse_args()
    run = args.snapshot.resolve()
    manifest = json.loads((run/'manifest.json').read_text(encoding='utf-8-sig'))
    scope = manifest.get('verify_scope', 'All').lower()
    assert scope == 'all' or scope == args.variant, 'Requested variant was not verified'
    for rel, expected in manifest['sha256'].items():
        assert sha(run/'source'/rel).lower() == expected.lower(), rel
    assert (run/'verify/status.txt').read_text(encoding='utf-8-sig').strip() == 'PASS'
    target = run/('synth_'+args.variant)
    if args.report_only:
        assert (target/'synthesis.dcp').is_file()
        target = target/'f2f_recheck'
    assert not target.exists(), 'Fresh measurement folder required'
    target.mkdir()
    for name in ['tmp', 'appdata', 'localappdata']:
        (target/name).mkdir()
    shutil.copyfile(ROOT/'syn/report_mac_f2f.tcl', target/'report_mac_f2f.tcl')
    if args.report_only:
        text = 'open_checkpoint ../synthesis.dcp\nsource report_mac_f2f.tcl\nclose_design\nexit\n'
    else:
        text = (run/'source/syn/refactored_mac_synth.tcl').read_text()
        text = text.replace('source [file join $root syn report_mac_f2f.tcl]',
                            'source report_mac_f2f.tcl')
    (target/'measure.tcl').write_text(text)
    env = os.environ.copy()
    env.update({'REFACTORED_SOURCE_ROOT': str(run/'source'),
                'TEMP': str(target/'tmp'), 'TMP': str(target/'tmp'),
                'APPDATA': str(target/'appdata'), 'LOCALAPPDATA': str(target/'localappdata'),
                'XILINX_LOCAL_USER_DATA': 'no'})
    command = [args.vivado, '-mode', 'batch', '-notrace', '-source', 'measure.tcl',
               '-log', 'vivado.log', '-journal', 'vivado.jou']
    if not args.report_only:
        command += ['-tclargs', args.variant]
    receipt = {'source_manifest_sha256': sha(run/'manifest.json'),
               'report_script_sha256': sha(target/'report_mac_f2f.tcl'),
               'measurement_script_sha256': sha(target/'measure.tcl'),
               'command': command, 'report_only': args.report_only,
               'part': 'xc7a35tcpg236-1', 'period_ns': 10,
               'implementation_run': False}
    (target/'execution.json').write_text(json.dumps(receipt, indent=2)+'\n')
    with (target/'console.log').open('w') as log:
        result = subprocess.run(command, cwd=target, env=env,
                                stdout=log, stderr=subprocess.STDOUT)
    if result.returncode:
        print((target/'console.log').read_text(errors='replace')[-3000:])
        raise RuntimeError('Measurement failed; preserve evidence')
    assert (target/'timing_metrics.csv').is_file()
    for rel, expected in manifest['sha256'].items():
        assert sha(run/'source'/rel).lower() == expected.lower(), rel
    print('F2F_MEASUREMENT_PASS', args.variant, target, flush=True)


if __name__ == '__main__':
    main()
