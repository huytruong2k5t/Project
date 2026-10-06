#include <iostream>
#include <cmath>
#include <random>
#include <vector>
#include "paper_multiplier.hpp"
using namespace l1;
using U = unsigned __int128;
static uint64_t checks = 0;
void check(bool ok, const char* message) {
    ++checks;
    if (!ok) throw std::runtime_error(message);
}
struct Reference { int64_t acc; unsigned used; std::vector<int> powers, signs; };
// Independent signed residual on a Q96 grid, no normalization/complement
// recurrence from PaperSac; subtract power-of-two and current-grid ULP.
Reference reference(unsigned m, unsigned y, unsigned n, bool complement) {
    U residual = U(m) << 84;
    int sign = 1;
    Reference r{0, 0, {}, {}};
    while (residual && r.used < n) {
        unsigned top = 0;
        for (U t = residual; t >>= 1;) ++top;
        bool up = residual >= (U(3) << (top - 1));
        int power = int(top) - 96 + int(up);
        uint64_t term = power >= 0 ? uint64_t(y) << power :
            (-power >= 64 ? 0 : uint64_t(y) / (uint64_t(1) << -power));
        r.acc += sign * int64_t(term);
        r.powers.push_back(power); r.signs.push_back(sign); ++r.used;
        if (up) {
            residual = (U(1) << (top + 1)) - residual -
                       (complement ? U(1) << (top - 12) : 0);
            sign = -sign;
        } else residual -= U(1) << top;
    }
    return r;
}
int main() try {
    PaperConfig cfg; cfg.ops = PaperOps::FixedA;
    std::vector<PaperStep> trace;
    // FP32 example from Table 1, converted to posit32 ES3.
    float xf = 0.4656868f;
    int e;
    double m = std::frexp(double(xf), &e) * 2;
    posit_unpacked<32,3> u{false,false,false,e-1,uint64_t(std::ldexp(m,63)),true};
    uint32_t a = pack<32,3>(u), b = 0x40000000;
    auto got = PaperMultiplier<>::mul(a,b,cfg,&trace);
    auto decoded = parse<32,3>(got.bits);
    check(std::ldexp(static_cast<long double>(decoded.frac),decoded.sf-63) == 0.46484375L,
          "paper Table 1 AP3");
    check(trace.size()==3 && trace[0].power+u.sf==-1 && trace[1].power+u.sf==-5 && trace[2].power+u.sf==-8 &&
          trace[0].coefficient==1 && trace[1].coefficient==-1 && trace[2].coefficient==-1,
          "Table 1 signed-power trace");
    uint32_t px=(uint32_t(1)<<28)|(uint32_t(6)<<25)|(uint32_t(0x480)<<13);
    uint32_t py=(uint32_t(1)<<29)|(uint32_t(7)<<26)|(uint32_t(0x208)<<14);
    auto figure4=PaperMultiplier<>::mul(px,py,cfg,&trace);
    check(figure4.bits==((uint32_t(1)<<28)|(uint32_t(5)<<25)|(uint32_t(0x71a)<<13)) &&
          trace.size()==3 && trace[0].power==0 && trace[1].power==-2 && trace[2].power==-5,
          "posit Fig4: two fraction iterations equal three total signed terms");
    for (unsigned comp=0;comp<2;++comp)
    for (unsigned x=0;x<4096;++x)
    for (unsigned n=1;n<=8;++n) {
        cfg.n=n; cfg.complement=comp;
        got=PaperMultiplier<>::mul(0x40000000|(x<<14),b,cfg,&trace);
        auto ref=reference(4096+x,4096,n,comp);
        check(got.iterations==ref.used && trace.back().accumulator==ref.acc,"exhaustive RND residual");
        for (unsigned i=0;i<ref.used;++i)
            check(trace[i].power==ref.powers[i] && trace[i].coefficient==ref.signs[i],"independent signed trace");
    }
    for (unsigned x=0;x<128;++x) {
        // Scale seven-bit input to twelve bits; compensation complement is
        // deliberately seven-bit here, so validate table using direct integers.
        unsigned m7=128+x; int approximation=0, coeff=1, exponent=0;
        for(unsigned i=0;i<2 && m7;++i) {
            bool up=m7>=192;
            approximation+=coeff*(1<<(7+exponent+int(up)));
            unsigned tail=up?255-m7:m7-128;
            if(up) coeff=-coeff;
            if(!tail) {m7=0;break;}
            while(tail<128) {tail*=2;--exponent;}
            m7=tail;
        }
        int error=int(128+x)-approximation;
        check(paper_prediction_lut()[x]==unsigned(std::abs(error)),"128-entry OPS truth table");
    }
    std::mt19937_64 rng(314159);
    for(unsigned i=0;i<100000;++i) {
        unsigned x=rng()&4095,y=rng()&4095;
        cfg.n=1+i%8; cfg.complement=true;
        cfg.ops=i%2?PaperOps::PredictN2:PaperOps::MinPopcount;
        bool swap=cfg.ops==PaperOps::PredictN2 ? paper_prediction_lut()[y>>5]<paper_prediction_lut()[x>>5] :
                  fraction_popcount(y)<fraction_popcount(x);
        got=PaperMultiplier<>::mul(0x40000000|(x<<14),0x40000000|(y<<14),cfg,&trace);
        if(swap) std::swap(x,y);
        auto ref=reference(4096+x,4096+y,cfg.n,true);
        check(got.swapped==swap && got.iterations==ref.used && trace.back().accumulator==ref.acc,
              "random SBM / single-change OPS comparison");
        int sf=0; uint64_t acc=ref.acc; bool sticky=false;
        while(acc>=8192) {sticky|=acc&1;acc>>=1;++sf;}
        while(acc<4096) {acc<<=1;--sf;}
        posit_unpacked<32,3> expected{false,false,false,sf,acc<<51,!sticky};
        check(got.bits==pack<32,3>(expected,cfg.rounding),"independent result encoding");
    }
    cfg=PaperConfig{};
    check(PaperMultiplier<>::mul(0x80000000,0,cfg).bits==0x80000000,"NaR priority");
    check(PaperMultiplier<>::mul(0,0x40000000,cfg).bits==0,"zero");
    check(PaperMultiplier<>::mul(0x40000000,0x40000000,cfg).iterations==1,"early stop");
    check(PaperMultiplier<>::mul(0xc0000000,0x40000000,cfg).bits==0xc0000000,"negative sign");
    check(PaperMultiplier<>::mul(0x7fffffff,0x7fffffff,cfg).bits==0x7fffffff,"max saturation");
    check(PaperMultiplier<>::mul(1,1,cfg).bits==1,"min saturation");
    bool rejected=false;cfg.n=0;
    try {PaperMultiplier<>::mul(a,b,cfg);} catch(const std::invalid_argument&) {rejected=true;}
    check(rejected,"n=0 rejects");
    std::cout<<"Table 1 example, all 4096 fractions n=1..8, 128 OPS entries, 100000 pairs PASS\n"
             <<"checks="<<checks<<" seed=314159 PASS\n";
    return 0;
} catch(const std::exception& e) {std::cerr<<"FAIL "<<e.what()<<'\n';return 1;}
