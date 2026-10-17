"""Isolated product magnitude bank; public NF/packer APIs are unchanged."""
from pathlib import Path
import hashlib
import json
import shutil

R = Path(__file__).resolve().parents[1]
O = R / 'results/opt09_20261018'


def main():
    if O.exists():
        raise SystemExit('Preserve existing study')
    # Independent comparison against the same OPT02b/C2 reference.
    for variant in ('baseline', 'magnitude'):
        shutil.copytree(R / 'results/opt05_20261017/source/baseline', O / 'source' / variant)
    dst = O / 'source/magnitude'
    pack = (dst / 'posit_pack.sv').read_text()
    pack = pack.replace('module posit_pack #(', 'module posit_product_pack #(')
    pack = pack.replace('    output wire [4:0] flags\n',
                        '    output wire [4:0] flags,\n    output wire sign_o\n')
    # Keep one rounded magnitude bank, not magnitude plus signed encoding.
    pack = pack.replace('            logic [4:0] flags_q;',
                        '            logic [4:0] flags_q;\n            logic sign_q;')
    pack = pack.replace('            assign flags = flags_q;',
                        '            assign flags = flags_q;\n            assign sign_o = sign_q;')
    pack = pack.replace("                    flags_q <= '0;",
                        "                    flags_q <= '0;\n                    sign_q <= 1'b0;")
    # P2's finish is deliberately unsigned; P1 sign travels beside it.
    pack = pack.replace('.sign (p1_sign_q)', ".sign (1'b0)")
    pack = pack.replace('.sign (p1_sign_d)', ".sign (1'b0)")
    pack = pack.replace('                        flags_q <= `CK2Q flags_d;',
                        '                        flags_q <= `CK2Q flags_d;\n'
                        '                        sign_q <= `CK2Q p1_sign_q;', 1)
    # Preserve the separate one-stage TRUNC branch too.
    last = pack.rfind('                        flags_q <= `CK2Q flags_d;')
    pack = pack[:last] + pack[last:].replace('                        flags_q <= `CK2Q flags_d;',
                        '                        flags_q <= `CK2Q flags_d;\n'
                        '                        sign_q <= `CK2Q p1_sign_d;', 1)
    pack = pack.replace('// File          : posit_pack.sv', '// File          : posit_product_pack.sv')
    pack = pack.replace('// Description   : Elastic RNE two-stage / TRUNC one-stage Posit packer.',
                        '// Description   : Internal magnitude packer; sign is a parallel metadata bit.')
    (dst / 'posit_product_pack.sv').write_text(pack, newline='\n')
    parser = (dst / 'posit_parser_comb.sv').read_text()
    parser = parser.replace('module posit_parser_comb #(', 'module posit_magnitude_parse #(')
    parser = parser.replace('    input logic [NB-1:0] p,',
                            '    input logic [NB-1:0] p,\n    input logic sign_i,')
    parser = parser.replace('assign s=p[NB-1];',
                            'assign s = is_nar || (!is_zero && sign_i);')
    parser = parser.replace("assign magnitude=s?(~p+{{(NB-1){1'b0}},1'b1}):p;", 'assign magnitude = p;')
    parser = parser.replace('// File          : posit_parser_comb.sv', '// File          : posit_magnitude_parse.sv')
    (dst / 'posit_magnitude_parse.sv').write_text(parser, newline='\n')
    wrapper = (dst / 'mac_nf_wrapper.sv').read_text()
    wrapper = wrapper.replace('    wire [NB-1:0] product_packed;',
                              '    wire [NB-1:0] product_magnitude;\n    wire product_sign_encoded;')
    start = wrapper.index('    posit_pack #(\n', wrapper.index('assign product_capture'))
    end = wrapper.index('    posit_add #(', start)
    block = wrapper[start:end]
    block = block.replace('posit_pack #(', 'posit_product_pack #(')
    block = block.replace('.d(product_packed),', '.d(product_magnitude),\n        .sign_o(product_sign_encoded),')
    block = block.replace('posit_parser_comb #(', 'posit_magnitude_parse #(')
    block = block.replace('.p(product_packed),', '.p(product_magnitude),\n        .sign_i(product_sign_encoded),')
    wrapper = wrapper[:start] + block + wrapper[end:]
    (dst / 'mac_nf_wrapper.sv').write_text(wrapper, newline='\n')
    canonical = R / 'rtl/candidates/mac_nf/opt09'
    canonical.mkdir(parents=True)
    for name in ('mac_nf_wrapper.sv', 'posit_product_pack.sv', 'posit_magnitude_parse.sv'):
        shutil.copy2(dst / name, canonical / name)
    manifest = {v: {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in sorted((O / 'source' / v).iterdir())}
                for v in ('baseline', 'magnitude')}
    (O / 'freeze.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(O)


if __name__ == '__main__':
    main()
