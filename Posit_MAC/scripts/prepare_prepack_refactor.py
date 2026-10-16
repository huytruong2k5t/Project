"""Prepare parameter-case test wrapper and source/hash manifest. No source edits."""
from pathlib import Path
import hashlib
import json
import os
import shutil

ROOT = Path(__file__).resolve().parents[1]
FROZEN = ROOT / 'results/prepack_refactor_20261016'
OUT = ROOT / os.environ.get('PREPACK_RESULTS_DIR', 'results/prepack_refactor_20261016')
assert OUT.resolve().is_relative_to((ROOT/'results').resolve()) and OUT.resolve()!=(ROOT/'results').resolve()
assert not (OUT/'summary.json').exists(), 'Frozen evidence exists; select a new PREPACK_RESULTS_DIR'
if OUT != FROZEN and not (OUT/'source').exists():
    OUT.mkdir(parents=True,exist_ok=True)
    shutil.copytree(FROZEN/'source',OUT/'source')
cases = []


def add(f, fw, en, aw=None, sw=11, fin=None):
    aw = aw or (max(2*f+2, fw+4) if en else fw+4)
    fin = fin or 2*f+1
    case = (f, fw, en, aw, sw, fin)
    if case not in cases:
        cases.append(case)


for f, fw, sw in [(1,1,1),(2,1,3),(3,2,4),(5,5,6),(12,12,8),(27,12,10),(26,12,11)]:
    for en in (0,1):
        add(f,fw,en,sw=sw)
        add(f,fw,en,sw=sw,fin=1)
        add(f,fw,en,sw=sw,fin=2*f+9)
        add(f,fw,en,aw=max(2*f+2,fw+4)+7,sw=sw+3,fin=max(1,f-1))
for f in (12,26,27):
    for en in (0,1):
        add(f,f,en,sw=17)
        add(f,1,en,sw=5,fin=2*f-1)
add(26,12,1,aw=80,sw=11,fin=70)
add(27,12,0,aw=80,sw=11,fin=70)
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'cases.json').write_text(json.dumps(cases,indent=2)+'\n')
lines=['`timescale 1ns/1ps','module tb_prepack_refactor;',f'wire [{len(cases)-1}:0] done;']
for i,(f,fw,en,aw,sw,fin) in enumerate(cases):
    lines += [f'prepack_refactor_checker #(.FRAC_MAX({f}), .FRAC_W({fw}), .EXACT_EN({en}), .ACC_W({aw}), .SF_W({sw}), .F_IN({fin})) c{i} (.done(done[{i}]));']
lines += ['initial begin wait (&done); $display("PREPACK ALL PASS"); $finish; end',
          'initial begin #100000; $fatal(1,"watchdog"); end','endmodule']
(OUT/'tb_prepack_refactor.sv').write_text('\n'.join(lines)+'\n')
old=(OUT/'source/baseline/mul_prepack_norm_comb.sv').read_bytes()
(OUT/'mul_prepack_norm_before.sv').write_bytes(old.replace(b'module mul_prepack_norm_comb #(', b'module mul_prepack_norm_before #('))
paths=list((OUT/'source').rglob('*.sv'))+list((OUT/'source').rglob('*.vh'))
manifest={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
(OUT/'source_sha256.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('PREPARE_PASS cases=',len(cases))
