"""Original synthesis recipe plus supplemental complete destination groups."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess
import sys

run = Path(__file__).resolve().parent
snapshot = run / 'candidate'
variant = sys.argv[1]
assert variant in ['nf', 'f']
manifest = json.loads((snapshot / 'manifest.json').read_text())
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def check():
    for rel, digest in manifest['sha256'].items():
        assert sha(snapshot / 'source' / rel) == digest, rel
check()
assert (snapshot / 'verify/status.txt').read_text().strip() == 'PASS'
target = snapshot / ('synth_' + variant)
assert not target.exists(), 'Preserve previous measurements'
target.mkdir()
for name in ['tmp', 'appdata', 'localappdata']:
    (target / name).mkdir()
shutil.copy2(snapshot / 'source/syn/report_mac_f2f.tcl', target / 'report_mac_f2f.tcl')
shutil.copy2(run / 'detailed_stages.tcl', target / 'detailed_stages.tcl')
original = (snapshot / 'source/syn/refactored_mac_synth.tcl').read_text()
anchor = 'source [file join $root syn report_mac_f2f.tcl]'
assert original.count(anchor) == 1
text = original.replace(anchor, 'source report_mac_f2f.tcl\nsource detailed_stages.tcl')
(target / 'measure.tcl').write_text(text)
env = os.environ.copy()
env.update({'REFACTORED_SOURCE_ROOT': str(snapshot / 'source'),
            'TEMP': str(target / 'tmp'), 'TMP': str(target / 'tmp'),
            'APPDATA': str(target / 'appdata'), 'LOCALAPPDATA': str(target / 'localappdata'),
            'XILINX_LOCAL_USER_DATA': 'no'})
command = [r'C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat', '-mode', 'batch', '-notrace',
           '-source', 'measure.tcl', '-log', 'vivado.log', '-journal', 'vivado.jou', '-tclargs', variant]
(target / 'execution.json').write_text(json.dumps({
    'command': command, 'source_manifest_sha256': sha(snapshot / 'manifest.json'),
    'original_recipe_sha256': sha(snapshot / 'source/syn/refactored_mac_synth.tcl'),
    'measurement_script_sha256': sha(target / 'measure.tcl'),
    'supplemental_report_sha256': sha(target / 'detailed_stages.tcl'),
    'part': 'xc7a35tcpg236-1', 'period_ns': 10,
    'change_from_original_recipe': 'Only add reporting after original F2F reports',
    'implementation_run': False, 'bitstream_run': False,
}, indent=2) + '\n')
with (target / 'console.log').open('w') as log:
    result = subprocess.run(command, cwd=target, env=env, stdout=log, stderr=subprocess.STDOUT)
if result.returncode:
    print((target / 'console.log').read_text(errors='replace')[-3000:])
    raise RuntimeError('Synthesis/report failed; retained evidence')
assert (target / 'status.txt').read_text().strip() == 'SYNTHESIS_COMPLETE'
assert (target / 'f2f_full_stages.csv').is_file()
check()
print('RESTORED_SYNTHESIS_FULL_F2F_PASS', variant, target, flush=True)
