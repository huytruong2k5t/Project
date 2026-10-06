#include <iostream>
#include "paper_ops.hpp"
#include "paper_multiplier.hpp"
using namespace l1;
static uint64_t checks=0;
void check(bool ok,const char* message) {
    ++checks;
    if(!ok) throw std::runtime_error(message);
}
// Independent Q24 residual oracle. No PaperSac, LUT or normalization recurrence.
unsigned reference_error(unsigned fraction) {
    uint32_t residual=(128+fraction)*131072;
    int sign=1,ap=0;
    for(unsigned i=0;i<2 && residual;++i) {
        unsigned top=0;
        for(uint32_t v=residual;v/=2;) ++top;
        bool up=uint64_t(residual)*2>=uint64_t(3)*(uint64_t(1)<<top);
        int power=int(top)-24+int(up);
        ap+=sign*(1<<(7+power));
        if(up) {
            residual=(uint32_t(1)<<(top+1))-residual-(uint32_t(1)<<(top-7));
            sign=-sign;
        } else residual-=uint32_t(1)<<top;
    }
    int error=int(128+fraction)-ap;
    return unsigned(error<0?-error:error);
}
int main() try {
    static_assert(PaperOpsFormat::FP32_FRACTION-PaperOpsFormat::TRUNCATED_FRACTION==12,"cut11");
    static_assert(PaperOpsFormat::PREDICTION_N==2,"predict n=2");
    unsigned ref[128];
    for(unsigned i=0;i<128;++i) {
        ref[i]=reference_error(i);
        check(paper_prediction_lut()[i]==ref[i],"128-entry n2 oracle");
    }
    for(unsigned a=0;a<4096;++a) for(unsigned b=0;b<4096;++b) {
        auto s=paper_ops_select(a,b);
        check(s.index_a==a/32 && s.index_b==b/32 && s.error_a==ref[a/32] &&
              s.error_b==ref[b/32] && s.swapped==(ref[b/32]<ref[a/32]) &&
              s.tie==(ref[b/32]==ref[a/32]),"all 16777216 OPS pairs / tie-A / low5 invariance");
    }
    for(unsigned kept=0;kept<4096;++kept) for(unsigned discarded=0;discarded<2048;++discarded) {
        uint32_t prefix=((kept&1)<<31)|((1+kept%254)<<23);
        uint32_t raw=prefix|(kept<<11)|discarded;
        auto u=paper_prepare_fp32(raw);
        check(u.original_bits==raw && u.truncated_bits==(prefix|(kept<<11)) &&
              u.fraction12==kept && u.prediction7==kept/32 && u.classification==PaperFp32Class::Normal,
              "all 8388608 fraction23 patterns: cut exactly11, preserve sign/exponent");
        auto s=paper_ops_fp32(raw,0x3fc00000);
        check(!s.bypass && s.selection.swapped==(ref[64]<ref[kept/32]),"FP32 OPS decision");
    }
    const uint32_t specials[]={0,0x80000000,1,0x807fffff,0x7f800000,0xff800000,0x7fc00001,0xff800001};
    const PaperFp32Class classes[]={PaperFp32Class::Zero,PaperFp32Class::Zero,
        PaperFp32Class::Subnormal,PaperFp32Class::Subnormal,PaperFp32Class::Infinity,
        PaperFp32Class::Infinity,PaperFp32Class::NaN,PaperFp32Class::NaN};
    for(unsigned i=0;i<8;++i) {
        auto s=paper_ops_fp32(specials[i],0x3f800000);
        check(s.bypass && s.a.classification==classes[i] && s.a.truncated_bits==specials[i],
              "special bypass keeps signed zero/NaN payload");
    }
    PaperConfig cfg;
    for(unsigned a=0;a<4096;++a) for(unsigned n=1;n<=8;++n) {
        unsigned b=a^0xaaa;
        cfg.n=n;
        auto result=PaperMultiplier<>::mul(0x40000000|(a<<14),0x40000000|(b<<14),cfg);
        check(result.swapped==(ref[b/32]<ref[a/32]),"predictor remains n2 for all multiply n1..8");
    }
    bool rejected=false;
    try {paper_ops_select(4096,0);} catch(const std::invalid_argument&) {rejected=true;}
    check(rejected,"invalid fraction12 rejected");
    std::cout<<"OPS n2/7bit; FP32 cut11; exhaustive fraction23 and 4096x4096 pairs PASS\n"
             <<"checks="<<checks<<" deterministic PASS\n";
    return 0;
} catch(const std::exception& e) {std::cerr<<"FAIL "<<e.what()<<'\n';return 1;}
