#include <iostream>
#include "paper_measurement.hpp"
using namespace l1;
uint64_t checks=0;
void check(bool ok) {++checks;if(!ok) throw std::runtime_error("measurement check "+std::to_string(checks));}
// Independent integer product, including gradual underflow and ties-to-even.
uint32_t integer_product(uint32_t a,uint32_t b) {
    auto unpack=[](uint32_t raw,uint64_t& sig,int& exponent) {
        unsigned e=(raw>>23)&255;sig=raw&0x7fffff;
        exponent=e?int(e)-150:-149;if(e) sig|=0x800000;
    };
    uint64_t x,y;int ex,ey;unpack(a,x,ex);unpack(b,y,ey);
    uint64_t p=x*y;if(!p) return 0;
    int top=0;for(uint64_t t=p;t>>=1;) ++top;
    int sf=top+ex+ey;
    int shift=sf>=-126?top-23:-149-ex-ey;
    uint64_t rounded;
    if(shift<=0) rounded=p<<(-shift);
    else if(shift>=64) rounded=0;
    else {
        rounded=p>>shift;
        uint64_t tail=p&((uint64_t(1)<<shift)-1),half=uint64_t(1)<<(shift-1);
        if(tail>half || (tail==half && (rounded&1))) ++rounded;
    }
    if(sf<-126) return uint32_t(rounded); // includes rounding into minnormal
    if(rounded==0x1000000) {rounded>>=1;++sf;}
    return uint32_t((sf+127)<<23)|uint32_t(rounded&0x7fffff);
}
int main() try {
    paper_init_fp32_rne();
    const uint32_t directed[][3]={{0x3fc00000,0x3f800001,0x3fc00002},
        {0x3fc00000,0x3f800003,0x3fc00004},{1,0x3f000000,0},
        {3,0x3f000000,2},{0x00800000,0x3f000000,0x00400000},
        {0x007fffff,0x3f800001,0x00800000}};
    for(auto& c:directed) {
        check(integer_product(c[0],c[1])==c[2]);
        check(float_bits(fp32_oracle(from_bits(c[0]),from_bits(c[1])))==c[2]);
    }
    std::mt19937_64 rng(20261004);
    for(unsigned j=0;j<1000000;++j) {
        uint32_t a=uint32_t(rng()%0x3f800000),b=uint32_t(rng()%0x3f800000);
        check(float_bits(fp32_oracle(from_bits(a),from_bits(b)))==integer_product(a,b));
    }
    for(auto d:{PaperDistribution::UniformValue,PaperDistribution::UniformBits}) {
        PaperGenerator a(314159,d),b(314159,d),other(314160,d);
        bool differs=false;PaperFingerprint hash;
        for(unsigned j=0;j<100000;++j) {
            auto raw=a.next_bits();check(raw==b.next_bits());check(raw<0x3f800000);
            differs|=raw!=other.next_bits();hash.add(raw);
            if(d==PaperDistribution::UniformValue)
                check(std::ldexp(double(from_bits(raw)),24)==std::floor(std::ldexp(double(from_bits(raw)),24)));
        }
        check(differs);check(a.draws==b.draws);
        check(d==PaperDistribution::UniformValue?a.draws==100000:a.draws>100000);
        check(hash.hash==(d==PaperDistribution::UniformValue?0xdc4294360a665d85ULL:0xe1867d3be71a8295ULL));
        std::cout<<"generator="<<int(d)<<" draws="<<a.draws<<" fingerprint="<<std::hex<<hash.hash<<std::dec<<'\n';
    }
    PaperCounters counters;
    auto reason=[&](uint32_t a,uint32_t b,PaperReject expected) {
        auto p=paper_evaluate_pair(a,b);check(p.reason==expected);counters.record(p.reason);check(counters.consistent());return p;
    };
    reason(0,0x3f000000,PaperReject::InputZero);
    reason(0x80000000,0x3f000000,PaperReject::InputZero);
    for(auto a:{0x3f800000u,0xbf000000u,0x7f800000u,0x7fc00000u}) reason(a,0,PaperReject::InvalidInput);
    reason(1,0x3f000000,PaperReject::Regime);
    reason(float_bits(std::ldexp(1.f,-100)),float_bits(std::ldexp(1.f,-100)),PaperReject::IdealZero);
    auto p=reason(float_bits(std::ldexp(1.f,-70)),float_bits(std::ldexp(1.f,-70)),PaperReject::Accepted);
    check(p.ideal_bits==512); // 2^-140, preserved subnormal
    counters.record(PaperReject::NonfiniteIdeal);check(counters.consistent());
    // Exactly equal thresholds must fail strict '<'. All values here are dyadic.
    const float ideals[]={1.953125f,1.5625f,1.5625f,1.25f};
    const float approximations[]={1.955078125f,1.5703125f,1.578125f,1.3125f};
    const unsigned den[]={1000,200,100,20};
    for(unsigned j=0;j<4;++j) {
        auto a=encode(approximations[j]),i=float_bits(ideals[j]);
        check(!paper_error_fraction(a,i).below(den[j]));
        check(paper_error_fraction(a-1,i).below(den[j]));
        check(!paper_error_fraction(a+1,i).below(den[j]));
        check(paper_error_fraction(encode(ideals[j]),i).below(den[j]));
    }
    for(unsigned j=0;j<100000;++j) {
        uint32_t ideal=uint32_t(rng()%0x3f7fffff)+1;
        uint32_t a=uint32_t(rng()&0x7fffffff);
        auto f=paper_error_fraction(a,ideal);
        long double err=std::fabs(value(a)-from_bits(ideal))/from_bits(ideal);
        for(auto d:den) check(f.below(d)==(err<1.L/d));
    }
    check(paper_error_fraction(encode(std::ldexp(1.f,-140)),512).below(1000));
    check(!paper_error_fraction(0,0x3f000000).below(20));
    std::cout<<"PASS checks="<<checks<<" seed=20261004 replay_seed=314159\n";
    return 0;
} catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}
