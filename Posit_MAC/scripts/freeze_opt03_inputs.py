"""Lock verification/replay drivers and the historical Default STA driver."""
from pathlib import Path
import hashlib
import json
import shutil

R=Path(__file__).resolve().parents[1]
O=R/'results/opt03_20261017'
assert not (O/'verification_inputs.json').exists()
paths=set()
for pattern in ['scripts/*opt03*','tb/*opt03*']:
    paths.update(p for p in R.glob(pattern) if p.is_file())
paths.update(R/name for name in ['tb/nf_coverage_harness.cpp','tb/nf_coverage.vlt',
    'tb/nf_coverage_corpus.hpp','tb/week11_model.hpp','tb/week10_add_reference.hpp',
    'tb/week9_exact_reference.hpp','tb/tb_week11_mac.sv','tb/prepack_nf_ppa_top.sv'])
manifest={}
for p in sorted(paths):
    name=p.relative_to(R).as_posix()
    dest=O/'verification_inputs'/name
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(p,dest)
    manifest[name]=hashlib.sha256(p.read_bytes()).hexdigest()
(O/'verification_inputs.json').write_text(json.dumps(manifest,indent=2)+'\n')
(O/'verification_runtime.json').write_text(json.dumps({'l0/libsoftposit.so':hashlib.sha256((R/'l0/libsoftposit.so').read_bytes()).hexdigest()},indent=2)+'\n')
for part in ['xc7a35tcpg236-1','xc7a100tcsg324-1']:
    d=O/'ppa'/part
    expected=json.loads((d/'driver_sha256_default.json').read_text(encoding='utf-8-sig'))['scripts/opt03_ppa.tcl']
    text=(R/'scripts/opt03_ppa.tcl').read_text()
    text=text.replace('set resume [expr {[llength $argv] > 1 && [lindex $argv 1] eq "resume"}]\n','')
    text=text.replace('set csv [open metrics.csv [expr {$resume ? "a" : "w"}]]\nif {!$resume} {\n    puts $csv ', 'set csv [open metrics.csv w]\nputs $csv ')
    text=text.replace('norm_slack,norm_delay_ns"\n}\n','norm_slack,norm_delay_ns"\n')
    text=text.replace('        if {$resume && $strategy eq "default"} {continue}\n','')
    text=text.replace('            open_checkpoint $checkpoint','            create_project -in_memory -part $part\n            read_checkpoint $checkpoint')
    versions=[text.encode(),text.replace('\n','\r\n').encode()]
    matches=[raw for raw in versions if hashlib.sha256(raw).hexdigest()==expected]
    assert len(matches)==1, 'Cannot recover the executed Default STA driver'
    (d/'opt03_default_driver.tcl').write_bytes(matches[0])
print('OPT03_INPUTS_FROZEN')
