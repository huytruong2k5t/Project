"""Add a missing *reachable* carry bin without changing any frozen corpus."""
import json
from audit_week14 import R,O,sha


def main():
    out=O/'nf_carry'
    assert not out.exists();out.mkdir()
    source=(R/'tb/nf_coverage_corpus.hpp').read_text()
    needle='switch (serial % 128) {'
    source=source.replace(needle,needle+'''
            // (2-2^-F) + 2^-8 crosses two: same-sign delta8, carry.
            case 24:
                v.acc_mode=false;v.acc_clr=false;v.mode=0;
                v.a=uint32_t(l1::pack<NB,ES>({false,false,false,0,
                      uint64_t(0)-(uint64_t(1)<<(63-F)),true}));
                v.b=ONE;v.c=power(-8);break;
''')
    (out/'nf_carry.hpp').write_text(source,encoding='utf-8',newline='\n')
    driver=(R/'tb/nf_coverage_harness.cpp').read_text().replace('"nf_coverage_corpus.hpp"','"nf_carry.hpp"')
    (out/'nf_carry.cpp').write_text(driver,encoding='utf-8',newline='\n')
    plan=dict(status='PREPARED_BEFORE_RUN',parent_matrix_sha256=sha(O/'matrix_freeze.json'),
        profiles=['nf32_3','nf32_2'],completed_each=20000,
        target='adder_bins[49], d=8..F same-sign overflow; exact A=2-2^-F B=1 C=2^-8',
        original_corpus_sha256=sha(R/'tb/nf_coverage_corpus.hpp'),
        source_sha256={p.name:sha(p) for p in out.iterdir()})
    (out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')


if __name__=='__main__':main()
