#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include "full_term_reference.hpp"

static uint64_t mix(uint64_t x) {
    x+=0x9e3779b97f4a7c15ull;
    x=(x^(x>>30))*0xbf58476d1ce4e5b9ull;
    x=(x^(x>>27))*0x94d049bb133111ebull;
    return x^(x>>31);
}
int main(int argc,char** argv) {
    try {
        full_term32::Config defaults;
        if (!defaults.approximate || defaults.n!=12 || defaults.ops!=1) throw std::runtime_error("model defaults");
        uint64_t checks=0,checkpoints=0,fixture_rows=0;
        for (uint64_t i=0;i<200000;++i) {
            const uint32_t a=uint32_t(mix(20261102+3*i)),b=uint32_t(mix(20261103+3*i)),c=uint32_t(mix(20261104+3*i));
            const full_term32::Config cfg{true,unsigned(i%13),unsigned((i/13)%2)};
            const auto p=full_term32::multiply(a,b,cfg);
            for (unsigned j=0;j<p.iterations;++j) {
                const auto reference=opt17_reference::product(a,b,{true,j+1,cfg.ops});
                if (p.checkpoints[j]!=reference.magnitude) throw std::runtime_error("L1 checkpoint");
                ++checkpoints;
            }
            for (bool fused:{false,true}) { opt17_reference::checked(a,b,c,cfg,fused); ++checks; }
        }
        if (argc>1) for (bool fused:{false,true}) {
            std::ifstream input(std::string(argv[1])+(fused?"/f.txt":"/nf.txt"));
            if (!input) throw std::runtime_error("missing Python fixture");
            uint32_t a,b,c,bits,flags,state=0;unsigned n,ops,mode,clear,abort;
            while (input>>std::hex>>a>>b>>c>>std::dec>>n>>ops>>mode>>clear>>std::hex>>bits>>flags>>std::dec>>abort) {
                const uint32_t ce=mode?(clear?0:state):c;
                const auto r=opt17_reference::checked(a,b,ce,{true,n,ops},fused);
                if (r.bits!=bits || r.flags!=flags) throw std::runtime_error("Python/L1/oracle fixture mismatch at "+std::to_string(fixture_rows));
                if (abort) state=0; else if (mode) state=bits;
                ++fixture_rows;
            }
        }
        std::cout<<"{\"status\":\"PASS\",\"mismatches\":0,\"model_golden_checks\":"<<checks
                 <<",\"checkpoint_checks\":"<<checkpoints<<",\"python_fixture_rows\":"<<fixture_rows<<"}\n";
    } catch(const std::exception& e) { std::cerr<<e.what()<<'\n';return 1; }
}
