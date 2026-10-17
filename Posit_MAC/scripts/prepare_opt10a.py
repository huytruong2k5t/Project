"""Isolated prefix-OR sticky candidate, preserving the shared P1 API."""
from pathlib import Path
import hashlib
import json
import shutil

R = Path(__file__).resolve().parents[1]
O = R / 'results/opt10a_20261018'


def main():
    if O.exists():
        raise SystemExit('Preserve existing study')
    for variant in ('baseline', 'sticky'):
        shutil.copytree(R / 'results/opt05_20261017/source/baseline', O / 'source' / variant)
    p = O / 'source/sticky/posit_pack_prepare.sv'
    code = p.read_text()
    code = code.replace('    wire [PAYLOAD_W-1:0] lost_mask;\n    wire lost_sticky;', '''    localparam int LOW_W = PAYLOAD_W - NB - 1;
    localparam int OFFSETS = 1 << SHIFT_W;
    wire [OFFSETS-1:0] sticky_lookup;
    wire payload_sticky;''')
    start = code.index('    // This mask collects original bits')
    end = code.index('    always_comb begin', start)
    code = code[:start] + '''    // Union of shift-discarded bits and the retained low shifted slice:
    // original payload[LOW_W + offset - 1:0]. Fixed slices run in parallel
    // with the barrel shifter. Include exponent and regime bits, not only frac.
    generate
        for (genvar j = 0; j < OFFSETS; j++) begin : g_sticky_prefix
            if (LOW_W + j <= PAYLOAD_W) begin : g_payload_only
                assign sticky_lookup[j] = |payload[LOW_W+j-1:0];
            end else begin : g_with_fill
                // Preserve raw combinational behavior even for oversized
                // offsets that the normal finite encoding does not use.
                assign sticky_lookup[j] = (|payload) | first_regime_bit;
            end
        end
    endgenerate
    assign payload_sticky = sticky_lookup[offset];

''' + code[end:]
    code = code.replace('                   | lost_sticky\n                   | (|shifted[PAYLOAD_W-NB-2:0]);',
                        '                   | payload_sticky;')
    p.write_text(code, newline='\n')
    dst = R / 'rtl/candidates/packer/opt10a'
    dst.mkdir(parents=True)
    shutil.copy2(p, dst / p.name)
    (O / 'freeze.json').write_text(json.dumps({v: {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
        for p in sorted((O / 'source' / v).iterdir())} for v in ('baseline', 'sticky')}, indent=2)+'\n')
    print(O)


if __name__ == '__main__':
    main()
