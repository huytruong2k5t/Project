"""Freeze isolated SAC studies; never mutate production or historical evidence."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
STUDY = ROOT / 'results/opt05_20261017'
VARIANTS = ('baseline', 'a', 'ab', 'abc_sub', 'abc_tree')


def main():
    if STUDY.exists():
        raise SystemExit('Preserve existing study')
    reference = ROOT / 'results/opt02b_20261017/source/candidate'
    original = (reference / 'sac_step_comb.sv').read_text()
    controller = (reference / 'iter_ctrl.sv').read_text()
    sources = {}
    for variant in VARIANTS:
        dst = STUDY / 'source' / variant
        shutil.copytree(reference, dst)
        code = original
        ctrl = controller
        if variant != 'baseline':
            code = code.replace('    logic [S_W:0] scale_sum;',
                                '    logic [S_W:0] scale_sum;\n    wire scale_out_of_range;')
            code = code.replace('    dyn_left_shifter #(', '''    generate
        if ({1'b0, {S_W{1'b1}}} > MAX_SCALE) begin : g_scale_range
            assign scale_out_of_range = ({1'b0, scale} > MAX_SCALE);
        end else begin : g_scale_always_in_range
            assign scale_out_of_range = 1'b0;
        end
    endgenerate

    dyn_left_shifter #(''')
            code = code.replace("({1'b0, scale} > MAX_SCALE) ||", 'scale_out_of_range ||')
            code = code.replace('wire [W_X-1:0] shifted;',
                                'wire [W_X-1:0] shifted;\n    wire [W_X-1:0] pre_shifted;')
            code = code.replace('    dyn_left_shifter #(', '''    // Remove the leading one with wiring before the variable shift.
    // LOD still observes the original fraction, not pre_shifted.
    generate
        if (W_X == 1) begin : g_pre_shift_single
            assign pre_shifted = '0;
        end else begin : g_pre_shift
            assign pre_shifted = {fx[W_X-2:0], 1'b0};
        end
    endgenerate

    dyn_left_shifter #(''')
            code = code.replace('.in(fx),\n        .b(step_amount)',
                                '.in(pre_shifted),\n        .b(leading_count_extended)')
        if variant in ('ab', 'abc_sub', 'abc_tree'):
            code = code.replace("scale_sum = {1'b0, scale} + {1'b0, step_amount};",
                                "scale_sum = {1'b0, scale}\n                  + {1'b0, leading_count_extended}\n                  + scale_limit_t'(1);")
        if variant.startswith('abc'):
            code = code.replace('    logic [S_W:0] scale_sum;',
                                '    logic [S_W:0] scale_sum;\n    wire single_one;')
            if variant == 'abc_sub':
                detection = """    typedef logic [W_X-1:0] fraction_t;
    // Zero is included; exhausted still qualifies state_error below.
    assign single_one = (fx & (fx - fraction_t'(1))) == '0;

"""
            else:
                detection = """    localparam int ONE_LEVELS = $clog2(W_X);
    localparam int ONE_PAD = 1 << ONE_LEVELS;
    wire [ONE_PAD-1:0] zero_tree [ONE_LEVELS:0] /* verilator split_var */;
    wire [ONE_PAD-1:0] one_tree [ONE_LEVELS:0] /* verilator split_var */;
    generate
        for (genvar j = 0; j < ONE_PAD; j++) begin : g_one_leaves
            if (j < W_X) begin : g_used
                assign zero_tree[0][j] = !fx[j];
                assign one_tree[0][j] = fx[j];
            end else begin : g_padding
                assign zero_tree[0][j] = 1'b1;
                assign one_tree[0][j] = 1'b0;
            end
        end
        for (genvar l = 0; l < ONE_LEVELS; l++) begin : g_one_levels
            for (genvar j = 0; j < (ONE_PAD >> (l + 1)); j++) begin : g_nodes
                assign zero_tree[l+1][j] = zero_tree[l][2*j]
                                        & zero_tree[l][2*j+1];
                assign one_tree[l+1][j] = (one_tree[l][2*j] & zero_tree[l][2*j+1])
                                       | (zero_tree[l][2*j] & one_tree[l][2*j+1]);
            end
        end
    endgenerate
    assign single_one = zero_tree[ONE_LEVELS][0] | one_tree[ONE_LEVELS][0];

"""
            code = code.replace('    dyn_left_shifter #(', detection + '    dyn_left_shifter #(')
            code = code.replace('exhausted = (shifted == \'0);',
                                'exhausted = single_one;')
            ctrl = ctrl.replace('unused_exhausted_exact', 'exhausted_exact')
            ctrl = ctrl.replace('unused_exhausted_approx', 'exhausted_approx')
            ctrl = ctrl.replace('wire is_init,is_last;',
                                'wire is_init,is_last;\n    wire exhausted_selected;')
            ctrl = ctrl.replace("assign is_last=is_init || (fx_next=='0) || (next_count>=limit_q);",
                                'assign exhausted_selected = mode_q ? exhausted_approx : exhausted_exact;\n'
                                '    assign is_last = is_init || exhausted_selected || (next_count >= limit_q);')
            ctrl = ctrl.replace("(is_last && fx_next!='0)", '(is_last && !exhausted_selected)')
        (dst / 'sac_step_comb.sv').write_text(code, newline='\n')
        (dst / 'iter_ctrl.sv').write_text(ctrl, newline='\n')
        sources[variant] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in sorted(dst.iterdir())}
        if variant != 'baseline':
            canonical = ROOT / 'rtl/candidates/multiplier/opt05' / variant
            canonical.mkdir(parents=True)
            shutil.copy2(dst / 'sac_step_comb.sv', canonical)
            if variant.startswith('abc'):
                shutil.copy2(dst / 'iter_ctrl.sv', canonical)
    manifest = {'contract': 'OPT05 isolated from production; reference OPT02b',
                'seed': 20261017, 'variants': sources,
                'production_sha256': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                                      for p in (ROOT / 'rtl').rglob('*')
                                      if p.is_file() and 'candidates' not in p.parts},
                'constraints': {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                                for p in (ROOT / 'syn/constraints').glob('a35t*100mhz.xdc')}}
    (STUDY / 'freeze.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(STUDY)


if __name__ == '__main__':
    main()
