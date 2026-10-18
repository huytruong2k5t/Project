"""Prepare isolated parser candidates; never edit the locked production tree."""
from pathlib import Path
import hashlib
import json
import re
import shutil
from audit_rtl_release import validate

R = Path(__file__).resolve().parents[1]
O = R / 'results/opt120_20261018'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()


def transform(text, pipelined, sentinel, negate):
    if pipelined:
        text = text.replace('    wire [NB-3:0] regime_tail;\n', '')
        text = text.replace('    assign regime_tail      = magnitude[NB-3:0];\n', '')
        text = text.replace('regime_tail ^ {(NB-2){first_regime_bit}}',
                            'magnitude[NB-3:0] ^ magnitude[NB-2:1]')
    else:
        text = text.replace('magnitude[NB-3:0] ^ {(NB-2){r}}',
                            'magnitude[NB-3:0] ^ magnitude[NB-2:1]')
    if sentinel:
        text = re.sub(r'    typedef logic \[CNT_W-1:0\] count_value_t;\n', '', text)
        text = re.sub(r'    localparam logic \[CNT_W-1:0\] MAX_COUNT = count_value_t\x27\(NB-2\);\n', '', text)
        text = text.replace('    wire [CNT_W-1:0] terminator_count;\n', '')
        text = text.replace('    wire terminator_valid;\n',
                            '    wire unused_terminator_valid;\n    wire [NB-2:0] detector_in;\n')
        text = text.replace('    lod_lzd_core #(\n',
                            "    // Sentinel supplies the no-terminator count NB-2.\n"
                            "    assign detector_in = {terminator_bits, 1'b1};\n\n    lod_lzd_core #(\n", 1)
        text = text.replace('.N    (NB - 2)', '.N    (NB - 1)')
        text = text.replace('.in  (terminator_bits)', '.in  (detector_in)')
        text = text.replace('.K   (terminator_count)', '.K   (cnt_d)' if pipelined else '.K   (cnt)')
        text = text.replace('.vld (terminator_valid)', '.vld (unused_terminator_valid)')
        if pipelined:
            start = text.index('    always_comb begin\n        // No terminator:')
            end = text.index('    // Empty slots', start)
            text = text[:start] + text[end:]
        else:
            text = re.sub(r'    // The detector returns K=0 on invalid; parser no-terminator means NB-2\.\n'
                          r'    assign cnt = terminator_valid \? terminator_count : MAX_COUNT;\n', '', text)
        assert 'MAX_COUNT' not in text and 'terminator_count' not in text
    if negate:
        if pipelined:
            text = text.replace("    assign magnitude = s_d\n                     ? (~p + {{(NB-1){1'b0}}, 1'b1})\n                     : p;",
                                "    assign magnitude = (p ^ {NB{s_d}})\n"
                                "                     + {{(NB-1){1'b0}}, s_d};")
        else:
            text = text.replace("    assign magnitude=s?(~p+{{(NB-1){1'b0}},1'b1}):p;",
                                "    assign magnitude = (p ^ {NB{s}})\n"
                                "                     + {{(NB-1){1'b0}}, s};")
    text = text.replace('// Search only AFTER the first regime bit: a 1 marks a terminator.\n'
                        '    // r=0 keeps the tail; r=1 inverts it to turn the first zero into a one.',
                        '// Adjacent XOR marks transitions; the first one is the terminator.')
    text = text.replace('// Exclude the first regime bit; XOR maps either terminator polarity to 1.',
                        '// Adjacent XOR preserves the first transition for either regime polarity.')
    return text


def main():
    lock = json.loads((R/'rtl/production_freeze.json').read_text())
    validate(lock)
    variants = {}
    for name in ('adjacent', 'sentinel', 'negate'):
        dest = O/'source'/name
        assert not dest.exists(), 'Preserve existing candidate sources'
        shutil.copytree(O/'source/reference', dest)
        for leaf in ('posit_parser', 'posit_parser_comb'):
            path = next(dest.rglob(leaf+'.sv'))
            original = path.read_text()
            changed = transform(original, leaf=='posit_parser', name!='adjacent', name=='negate')
            assert changed != original
            path.write_text(changed, encoding='utf-8', newline='\n')
        hashes = {p.relative_to(dest).as_posix():sha(p) for p in dest.rglob('*') if p.is_file()}
        assert set(k for k,v in hashes.items() if v!=lock['rtl_sha256'][k]) == {
            'rtl/parser/posit_parser.sv','rtl/parser/posit_parser_comb.sv'}
        variants[name] = hashes
    (O/'variants.json').write_text(json.dumps({
        'reference_release':lock['release_id'],'reference':lock['rtl_sha256'],
        'variants':variants,'interface':'unchanged public parser parameters/ports, two elastic stages',
        'precision':'unchanged, no unused x_frac bits removed',
        'scope':'OPT12 only; no OPT13/14 or common LOD changes'
    },indent=2)+'\n', encoding='utf-8')
    print('Prepared adjacent/sentinel/negate; only the two parser files differ')


if __name__ == '__main__':
    main()
