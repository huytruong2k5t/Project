"""Reuse source-identical historical baseline and derive a synth-once STA run."""
from pathlib import Path
import hashlib
import json
import shutil

R=Path(__file__).resolve().parents[1]
O=R/'results/opt03_20261017'
OLD=R/'results/prepack_refactor_20261016'
assert all(p.read_bytes()==(OLD/'source/baseline'/p.name).read_bytes()
           for p in (O/'source/baseline').iterdir())
assert not (O/'calibration').exists()
# Keep both completed calibration runs and interrupted redundant synthesis logs.
src=(O/'ppa').resolve(); dst=(O/'calibration').resolve()
assert src.is_relative_to(O.resolve()) and dst.is_relative_to(O.resolve())
src.rename(dst)
files={}
for part in ['xc7a35tcpg236-1','xc7a100tcsg324-1']:
    for strategy in ['default','explore','runtime']:
        base=OLD/'ppa'/part/f'baseline_{strategy}'
        target=O/'baseline_reference'/part/f'baseline_{strategy}'
        shutil.copytree(base,target)
        for p in target.rglob('*'):
            if p.is_file():files[p.relative_to(O).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
    shutil.copy2(OLD/'ppa'/part/'metrics.csv',O/'baseline_reference'/part/'historical_metrics.csv')
    # Completed new Default calibration must reproduce all baseline metrics.
    import csv
    with (O/'calibration'/part/'metrics.csv').open() as f:new=list(csv.DictReader(f))
    with (OLD/'ppa'/part/'metrics.csv').open() as f:old=list(csv.DictReader(f))
    assert new and new[0]==old[0], part
    for p in ['setup.rpt','hold.rpt','norm_round.rpt']:
        # Vivado report timestamp/header differs; metric equality is above.
        assert (O/'calibration'/part/'baseline_default'/p).is_file()
(O/'baseline_reuse.json').write_text(json.dumps(dict(
    source_checkpoint='prepack_refactor_20261016',all_source_bytes_identical=True,
    fresh_default_metrics_identical_on_both_parts=True,
    conditions='Same Vivado2026.1, parts, wrapper, 10ns/.1ns clock, IO2.5ns/.5ns, directives',
    files=files),indent=2)+'\n')
s=(R/'scripts/opt03_ppa.tcl').read_text()
s=s.replace('foreach variant {baseline candidate}', 'foreach variant {candidate}')
a=s.index('        create_project -in_memory')
b=s.index('        opt_design',a)
chunk=s[a:b]
s=s[:a]+'''        set checkpoint [file join [pwd] ${variant}_synth.dcp]
        if {$strategy eq "default"} {
'''+chunk+'''            write_checkpoint -force $checkpoint
        } else {
            create_project -in_memory -part $part
            read_checkpoint $checkpoint
        }
'''+s[b:]
(R/'scripts/opt03_ppa.tcl').write_text(s)
print('OPT03_STA_PREPARED: baseline reuse locked; candidate synth once/part')
