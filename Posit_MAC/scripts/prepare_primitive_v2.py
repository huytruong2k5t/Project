"""Freeze the baseline, create isolated shift candidates, and prepare fair cases."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'results/primitive_v2_20261016'
NAMES = ('lod_lzd_core','dyn_left_shifter','dyn_right_shifter')


def header(name, detail):
    return f'''//-----------------------------------------------------------------------------
// File          : {name}.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP
// Creation Date : 2026-10-16
// Description   : Candidate: {detail}.
// $Source: $ $Revision: 2.0-candidate $ $Log: No pipeline or interface change. $
//-----------------------------------------------------------------------------
'''


def shifter(name, variant):
    right = 'right' in name
    params = "parameter int N = 32,\n    parameter int SHIFT_W = (N > 1) ? $clog2(N) : 1"
    if right: params += ",\n    parameter bit ARITH = 1'b0"
    ports = "input logic [N-1:0] in,\n    input logic [SHIFT_W-1:0] b,\n"
    if right: ports += "    input logic fill_val,\n"
    ports += "    output logic [N-1:0] out"
    s = header(name,variant)+f'module {name} #(\n    {params}\n)(\n    {ports}\n);\n'
    if right: s += "    logic fill;\n    assign fill = ARITH ? in[N-1] : fill_val;\n"
    s += f'''    generate
        if (N < 1 || SHIFT_W < 1) begin : g_invalid
            initial $fatal(1, "{name}: invalid parameters");
        end
'''
    pad = 'fill' if right else "1'b0"
    if variant == 'native':
        if right:
            s += '''        // Transform custom-fill shift into a zero-fill shift.
        // The sign/custom pad is recovered after shifting, including overshift.
        wire [N-1:0] data_zero;
        wire [N-1:0] shifted_zero;
        assign data_zero = in ^ {N{fill}};
        assign shifted_zero = data_zero >> b;
        assign out = shifted_zero ^ {N{fill}};
'''
        else: s += '        assign out = in << b;\n'
    else:
        s += f'''        if (N == 1) begin : g_single
            assign out = (|b) ? {pad} : in;
        end else begin : g_multi
            localparam int S = $clog2(N);
            localparam int EFF_S = (SHIFT_W < S) ? SHIFT_W : S;
'''
        if variant == 'reverse':
            s += '            localparam int STAGES = EFF_S;\n'
        else: s += '            localparam int STAGES = (EFF_S + 1) / 2;\n'
        s += '''            wire [N-1:0] stage [STAGES:0] /* verilator split_var */;
            assign stage[0] = in;
            for (genvar i = 0; i < STAGES; i++) begin : g_stages
'''
        def constant_shift(step):
            return f'{{{{{step}{{{pad}}}}}, stage[i][N-1:{step}]}}' if right else f'{{stage[i][N-1-{step}:0], {{{step}{{1\'b0}}}}}}'
        if variant == 'reverse':
            s += '''                localparam int BIT_INDEX = EFF_S - 1 - i;
                localparam int STEP = 1 << BIT_INDEX;
'''
            s += f'                assign stage[i+1] = b[BIT_INDEX] ? {constant_shift("STEP")} : stage[i];\n'
        else:
            s += '''                localparam int BIT_INDEX = 2 * i;
                localparam int STEP = 1 << BIT_INDEX;
                wire [N-1:0] shift1;
'''
            for k in (1,):
                s += f'''                if ({k}*STEP < N) begin : g_shift{k}
                    assign shift{k} = {constant_shift(f'{k}*STEP')};
                end else begin : g_pad{k}
                    assign shift{k} = {{N{{{pad}}}}};
                end
'''
            s += '''                if (BIT_INDEX + 1 < EFF_S) begin : g_pair
                    wire [N-1:0] shift2;
                    wire [N-1:0] shift3;
'''
            for k in (2,3):
                s += f'''                    if ({k}*STEP < N) begin : g_shift{k}
                        assign shift{k} = {constant_shift(f'{k}*STEP')};
                    end else begin : g_pad{k}
                        assign shift{k} = {{N{{{pad}}}}};
                    end
'''
            s += '''
                    logic [N-1:0] selected;
                    always_comb begin
                        unique case (b[BIT_INDEX +: 2])
                            2'b00: selected = stage[i];
                            2'b01: selected = shift1;
                            2'b10: selected = shift2;
                            default: selected = shift3;
                        endcase
                    end
                    assign stage[i+1] = selected;
                end else begin : g_last
                    assign stage[i+1] = b[BIT_INDEX] ? shift1 : stage[i];
                end
'''
            # Procedural assignment requires a variable rather than a net.
            s=s.replace('wire [N-1:0] stage [STAGES:0]','logic [N-1:0] stage [STAGES:0]')
        s += f'''            end
            if (SHIFT_W > S) begin : g_guard
                assign out = (|b[SHIFT_W-1:S]) ? {{N{{{pad}}}}} : stage[STAGES];
            end else begin : g_no_guard
                assign out = stage[STAGES];
            end
        end
'''
    return s+'    endgenerate\nendmodule\n// End of '+name+'.sv\n'


def main():
    OUT.mkdir(exist_ok=True)
    refresh = '--refresh-before-ppa' in sys.argv
    if refresh and list(OUT.rglob('metrics.csv')):
        raise RuntimeError('Cannot refresh sources after PPA has started')
    for variant in ('reverse','radix4','native'):
        for name in NAMES[1:]:
            p=ROOT/f'rtl/candidates/primitives_v2/{variant}/{name}.sv'
            p.parent.mkdir(parents=True,exist_ok=True)
            content=shifter(name,variant).encode()
            if p.exists() and p.read_bytes()!=content:
                raise RuntimeError(f'Candidate already edited; do not overwrite {p}')
            p.write_bytes(content)
    sources={}
    for variant in ('baseline','group4','reverse','radix4','native'):
        dst=OUT/'source'/variant;dst.mkdir(parents=True,exist_ok=True)
        for name in NAMES:
            folder='rtl/common'
            if (variant=='group4' and name==NAMES[0]) or (variant in ('reverse','radix4','native') and name!=NAMES[0]):
                folder=f'rtl/candidates/primitives_v2/{variant}'
            src=ROOT/f'{folder}/{name}.sv'
            digest=hashlib.sha256(src.read_bytes()).hexdigest()
            saved=dst/src.name
            if saved.exists() and saved.read_bytes()!=src.read_bytes() and not refresh:
                raise RuntimeError(f'Snapshot changed: {saved}')
            shutil.copyfile(src,saved);sources[src.relative_to(ROOT).as_posix()]=digest
        shutil.copyfile(ROOT/'rtl/posit_mac.vh',dst/'posit_mac.vh')
    # Start with LOD, then shift leaves at actual integration widths. Single
    # Default screening is followed by matched strategies only for Pareto cases.
    cases=[]
    for n in (12,26,27,30,31,32):
        for variant in ('baseline','group4'):
            cases.append(dict(variant=variant,n=n,kind=2,mode=0,arith=0,fill=1))
    for kind,widths in ((0,(12,26,29,31)),(1,(12,31,32,59,60))):
        for n in widths:
            fills=(0,1) if kind==1 else (0,)
            for fill in fills:
                for variant in ('baseline','reverse','radix4','native'):
                    cases.append(dict(variant=variant,n=n,kind=kind,mode=0,arith=0,fill=fill))
    manifest=dict(date='2026-10-16',seed=20261016,sources=sources,cases=cases,
        parts=['xc7a35tcpg236-1','xc7a100tcsg324-1'],period_ns=5.0,
        selection='No production replacement without bit-exact and matched post-route evidence; no target tuning.',
        scope='Known binary inputs; combinational latency unchanged; no board/Fmax sweep signoff.')
    path=OUT/'manifest.json'
    if path.exists() and json.loads(path.read_text())!=manifest and not refresh:raise RuntimeError('Frozen manifest differs')
    path.write_text(json.dumps(manifest,indent=2)+'\n')
    mixed=ROOT/'rtl/candidates/primitives_v2/group4_mixed/lod_lzd_core.sv'
    if mixed.exists():
        dst=OUT/'source/group4_mixed';dst.mkdir(exist_ok=True)
        for name in NAMES:
            src=mixed if name=='lod_lzd_core' else OUT/f'source/baseline/{name}.sv'
            target=dst/src.name
            if target.exists() and target.read_bytes()!=src.read_bytes():raise RuntimeError('Additional snapshot differs')
            shutil.copyfile(src,target)
        shutil.copyfile(ROOT/'rtl/posit_mac.vh',dst/'posit_mac.vh')
        extension=dict(source=mixed.relative_to(ROOT).as_posix(),sha256=hashlib.sha256(mixed.read_bytes()).hexdigest(),
            hypothesis='Four-way lower levels, binary root, minimal power-of-two padding; frozen before PPA.')
        ext=OUT/'mixed_manifest.json'
        if ext.exists() and json.loads(ext.read_text())!=extension:raise RuntimeError('Additional manifest differs')
        ext.write_text(json.dumps(extension,indent=2)+'\n')
    print(f'Prepared {len(cases)} screening cases and frozen source snapshots')


if __name__=='__main__':main()
