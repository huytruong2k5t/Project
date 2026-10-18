"""Freeze production and the tested OPT8.28 reference before OPT02c work."""
from pathlib import Path
import hashlib
import json
import shutil

R=Path(__file__).resolve().parents[1]
O=R/'results/opt02c_20261018'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    if O.exists():raise RuntimeError('Preserve existing study')
    paths=(R/'rtl/production.f').read_text().splitlines()
    assert len(paths)==36 and len({Path(p).name for p in paths})==36
    production=O/'source/production'
    production.mkdir(parents=True)
    for name in paths+['rtl/posit_mac.vh']:
        shutil.copy2(R/name,production/Path(name).name)
    shutil.copy2(R/'rtl/production.f',O/'reference_production.f')
    previous=R/'results/optcombo_20261018'
    assert (previous/'acceptance_status.txt').read_text().strip()=='COMPLETE'
    assert (previous/'modelsim/status.txt').read_text().strip()=='COMPLETE'
    old=json.loads((previous/'freeze.json').read_text())['source_sha256']['combined']
    source=previous/'source/combined'
    assert all(sha(source/name)==digest for name,digest in old.items())
    shutil.copytree(source,O/'source/reference')
    shutil.copytree(source,O/'source/candidate')
    p=O/'source/candidate/posit_add_align.sv'
    text=p.read_text()
    text=text.replace('$Revision: OPT-02b candidate $','$Revision: OPT-02c candidate $')
    text=text.replace('$Log: 2026-10-17 parallel deltas, sf-only shifter, prefix-OR jam. $',
        '$Log: 2026-10-18 raw low shifts, branch-parallel lookup, bitwise clamp. $')
    start=text.index('    assign clamp_ab =')
    end=text.index('    assign shift_amount',start)
    text=text[:start]+'''    // The unselected negative difference must never assert clamp.
    // F+2 fits SHIFT_W because F+2 < ADD_W <= 2**SHIFT_W.
    assign clamp_ab = !diff_ab[SF_W]
                    && ((|diff_ab[SF_W-1:SHIFT_W])
                        || (diff_ab[SHIFT_W-1:0] > shift_t'(F+2)));
    assign clamp_ba = !diff_ba[SF_W]
                    && ((|diff_ba[SF_W-1:SHIFT_W])
                        || (diff_ba[SHIFT_W-1:0] > shift_t'(F+2)));

    // A clamped result is overridden at the output; do not put clamp
    // on either the shifter-control path or the parallel table lookups.
    assign shift_ab = diff_ab[SHIFT_W-1:0];
    assign shift_ba = diff_ba[SHIFT_W-1:0];
'''+text[end:]
    text=text.replace('wire lost_tail;', '''wire tail_ab;
    wire tail_ba;
    wire jam_ab;
    wire jam_ba;
    wire lost_tail;''')
    text=text.replace('assign lost_tail = sf_a_lt_b ? tail_a[shift_amount] : tail_b[shift_amount];\n    assign jam_bit = sf_a_lt_b ? jam_a[shift_amount] : jam_b[shift_amount];',
'''// Each lookup waits only for its own low subtraction bits.
    // The full-width sign selects results after both branches run in parallel.
    assign tail_ab = tail_b[shift_ab];
    assign tail_ba = tail_a[shift_ba];
    assign jam_ab = jam_b[shift_ab];
    assign jam_ba = jam_a[shift_ba];
    assign lost_tail = sf_a_lt_b ? tail_ba : tail_ab;
    assign jam_bit = sf_a_lt_b ? jam_ba : jam_ab;''')
    text=text.replace('Legal shift <=F+2; jam needs the prefix through F+3.',
                      'Effective nonclamped shift <=F+2; larger raw shifts are overridden.')
    text=text.replace('(OPT-02b candidate).','(OPT-02c candidate).')
    p.write_text(text,encoding='utf-8',newline='\n')
    canonical=R/'rtl/candidates/adder/opt02c'
    canonical.mkdir(parents=True)
    shutil.copy2(p,canonical/p.name)
    inputs={}
    for directory,extensions in [('l1/include',{'.hpp','.h'}),('tb',{'.cpp','.hpp','.sv','.vlt'}),
                                 ('syn/constraints',{'.xdc'})]:
        for p in (R/directory).glob('*'):
            if p.suffix in extensions:inputs[p.relative_to(R).as_posix()]=sha(p)
    frozen={'production_f':paths,'variants':{v:{p.name:sha(p) for p in sorted((O/'source'/v).iterdir())}
              for v in ('production','reference','candidate')},'verification_inputs':inputs,
            'rounding':'FLOOR/RNE unchanged','seed_NF':20264217,
            'policy':'Default screening, then matched three strategies; no new latency/II; no W14 main'}
    (O/'freeze.json').write_text(json.dumps(frozen,indent=2)+'\n')
    print(O)


if __name__=='__main__':main()
