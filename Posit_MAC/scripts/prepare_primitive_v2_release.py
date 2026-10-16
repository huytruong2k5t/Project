"""Prepare a provisional selective release from immutable baseline/candidate sources."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/primitive_v2_20261016'
DST=ROOT/'rtl/candidates/primitives_v2/selected'
SNAP=OUT/'source/selected'
DST.mkdir(parents=True,exist_ok=True);SNAP.mkdir(parents=True,exist_ok=True)

def header(name,description):
 return f'''//-----------------------------------------------------------------------------
// File          : {name}.sv
// Author(s)     : Dan Huy / Codex
// Email         :
// Project       : Posit MAC IP
// Creation Date : 2026-10-16
// Description   : {description}
//                 Unmeasured configurations retain the binary baseline.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 2.0-selective-candidate $
// $Log: Same parameters/ports; no registers or added combinational latency. $
//-----------------------------------------------------------------------------
'''

def save(name,text):
 p=DST/(name+'.sv');data=text.encode()
 if p.exists() and p.read_bytes()!=data:raise RuntimeError('Selective source already differs: '+name)
 p.write_bytes(data);shutil.copyfile(p,SNAP/p.name)
 return hashlib.sha256(data).hexdigest()

def indent(text):
 return '\n'.join('        '+line if line else '' for line in text.splitlines())+'\n'

def region(text):
 return '\n'.join(line for line in text.splitlines() if line.strip() not in ('generate','endgenerate'))+'\n'

base=(OUT/'source/baseline/dyn_left_shifter.sv').read_text()
base=base[base.index('module dyn_left_shifter #('):]
marker='    generate\n    if (N == 1) begin : g_single_bit'
assert marker in base
start=base.index(marker)
inner=base[start+len('    generate\n'):base.rindex('    endgenerate')]
left=header('dyn_left_shifter','Selective native N12/SW4; original implementation elsewhere.')+base[:start]+"""    generate
        if (N == 12 && SHIFT_W == 4) begin : g_native_12
            assign out = in << b;
        end else begin : g_baseline
"""+indent(inner)+"""        end
    endgenerate
endmodule
// End of dyn_left_shifter.sv
"""

base=(OUT/'source/baseline/lod_lzd_core.sv').read_text()
start=base.index('module lod_lzd_core #(');body=base.index('    //-------------------------------------------------------------------------',start)
ports=base[start:body]
binary=region(base[body:base.rindex('endmodule')])
g4=(OUT/'source/group4/lod_lzd_core.sv').read_text()
g4=region(g4[g4.index('    localparam int LEVELS'):g4.rindex('endmodule')])
lod=header('lod_lzd_core','Selective group4 N31/N32 MODE0; binary fallback.')+ports+"""    generate
        if (MODE == 0 && (N == 31 || N == 32) && S == $clog2(N)) begin : g_group4
"""+indent(g4)+"""        end else begin : g_baseline
"""+indent(binary)+"""        end
    endgenerate
endmodule
// End of lod_lzd_core.sv
"""
right=(OUT/'source/baseline/dyn_right_shifter.sv').read_bytes()
digests={}
for name,text in [('lod_lzd_core',lod),('dyn_left_shifter',left)]:digests[name]=save(name,text)
p=DST/'dyn_right_shifter.sv'
if p.exists() and p.read_bytes()!=right:raise RuntimeError('Right baseline changed')
p.write_bytes(right);shutil.copyfile(p,SNAP/p.name);digests['dyn_right_shifter']=hashlib.sha256(right).hexdigest()
shutil.copyfile(OUT/'source/baseline/posit_mac.vh',SNAP/'posit_mac.vh')
manifest=dict(status='PROVISIONAL_NOT_PROMOTED',sources=digests,
    selection={'lod':'MODE=0,N=31 or32,S=clog2N:group4; otherwise original binary tree',
               'left':'N=12,SHIFT_W=4:native; otherwise original cascade',
               'right':'original; no uniform timing win across fill/width/part'},
    requirement='Pass selected-source oracle/lint, matched release PPA and complete cross-part review before copying to common.')
p=OUT/'release_manifest.json'
if p.exists() and json.loads(p.read_text())!=manifest:raise RuntimeError('Release manifest already differs')
p.write_text(json.dumps(manifest,indent=2)+'\n')
lines=[]
for n,k,fill in ((12,0,0),(31,2,1),(32,2,1),(12,4,0),(31,3,0)):
 sw=(n-1).bit_length()
 for variant in ('baseline','selected'):
  for strategy in ('default','explore','runtime'):
   ident=f'{variant}_n{n}_k{k}_m0_a0_f{fill}_w{sw}_{strategy}'
   lines.append('\t'.join(map(str,(ident,variant,n,k,0,0,fill,strategy,sw)))+'\n')
cases=OUT/'release_cases.tsv';text=''.join(lines)
if cases.exists() and cases.read_text()!=text:raise RuntimeError('Release case list already differs')
cases.write_text(text,newline='\n')
lod_only=OUT/'source/lod_only';lod_only.mkdir(exist_ok=True)
for name in ('lod_lzd_core','dyn_left_shifter','dyn_right_shifter'):
 src=SNAP/(name+'.sv') if name=='lod_lzd_core' else OUT/f'source/baseline/{name}.sv'
 target=lod_only/src.name
 if target.exists() and target.read_bytes()!=src.read_bytes():raise RuntimeError('LOD-only snapshot differs')
 shutil.copyfile(src,target)
shutil.copyfile(OUT/'source/baseline/posit_mac.vh',lod_only/'posit_mac.vh')
lines=[]
for n,k,fill in ((31,2,1),(32,2,1),(31,3,0)):
 sw=(n-1).bit_length()
 for variant in ('baseline','lod_only'):
  for strategy in ('default','explore','runtime'):
   ident=f'{variant}_n{n}_k{k}_m0_a0_f{fill}_w{sw}_{strategy}'
   lines.append('\t'.join(map(str,(ident,variant,n,k,0,0,fill,strategy,sw)))+'\n')
cases=OUT/'adoption_cases.tsv';text=''.join(lines)
if cases.exists() and cases.read_text()!=text:raise RuntimeError('LOD-only case list already differs')
cases.write_text(text,newline='\n')
print('Prepared provisional selected source; common unchanged')
