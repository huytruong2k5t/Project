#pragma once
#include <cfenv>
#include <cmath>
#include <cstring>
#include <limits>
#include <random>
#include <stdexcept>
#include "posit_parser.hpp"
#include "posit_packer.hpp"
namespace l1 {
static_assert(sizeof(float)==4 && std::numeric_limits<float>::is_iec559 &&
              std::numeric_limits<float>::digits==24,"IEEE binary32 required");
inline uint32_t float_bits(float x) {
    uint32_t bits;std::memcpy(&bits,&x,4);return bits;
}
inline float from_bits(uint32_t bits) {
    float x;std::memcpy(&x,&bits,4);return x;
}
inline void paper_init_fp32_rne() {
    if(std::fesetround(FE_TONEAREST)!=0) throw std::runtime_error("cannot set FP32 RNE");
}
inline float fp32_oracle(float x,float y) {
    volatile float rounded=x*y;return rounded;
}
inline uint32_t encode(float x) {
    if(x==0) return 0;
    if(!std::isfinite(x) || x<0) throw std::invalid_argument("positive finite FP32 input required");
    int e;double m=std::frexp(double(x),&e)*2;
    posit_unpacked<32,3> u{false,false,false,e-1,uint64_t(std::ldexp(m,63)),true};
    return pack<32,3>(u,RoundMode::RNE);
}
inline unsigned regime(uint32_t bits) {
    unsigned m=0,bit=(bits>>30)&1;
    for(int i=30;i>=0 && ((bits>>i)&1)==bit;--i) ++m;
    return m;
}
inline long double value(uint32_t bits) {
    auto u=parse<32,3>(bits);
    return u.is_zero?0:std::ldexp(static_cast<long double>(u.frac),u.sf-63);
}
enum class PaperDistribution { UniformValue, UniformBits };
class PaperGenerator {
    std::mt19937_64 rng;
    PaperDistribution distribution;
public:
    uint64_t draws=0;
    PaperGenerator(uint64_t seed,PaperDistribution d):rng(seed),distribution(d) {
        if(d!=PaperDistribution::UniformValue && d!=PaperDistribution::UniformBits)
            throw std::invalid_argument("invalid generator distribution");
    }
    uint32_t next_bits() {
        if(distribution==PaperDistribution::UniformValue) {
            ++draws;
            return float_bits(std::ldexp(float(rng()&0xffffff),-24));
        }
        uint32_t raw;
        do {++draws;raw=uint32_t(rng()&0x3fffffff);} while(raw>=0x3f800000);
        return raw;
    }
};
enum class PaperReject { Accepted, InvalidInput, InputZero, Regime, IdealZero, NonfiniteIdeal };
struct PaperPair {
    PaperReject reason=PaperReject::InvalidInput;
    uint32_t posit_a=0,posit_b=0,ideal_bits=0;
};
inline PaperPair paper_evaluate_pair(uint32_t a,uint32_t b) {
    PaperPair r;
    // Domain [0,1), allowing signed zero for the explicit zero exclusion.
    auto domain=[](uint32_t raw) {
        uint32_t magnitude=raw&0x7fffffff;
        return magnitude<0x3f800000 && (!(raw&0x80000000) || magnitude==0);
    };
    if(!domain(a) || !domain(b)) return r;
    if(!(a&0x7fffffff) || !(b&0x7fffffff)) {r.reason=PaperReject::InputZero;return r;}
    r.posit_a=encode(from_bits(a));r.posit_b=encode(from_bits(b));
    if(regime(r.posit_a)>15 || regime(r.posit_b)>15) {r.reason=PaperReject::Regime;return r;}
    r.ideal_bits=float_bits(fp32_oracle(from_bits(a),from_bits(b)));
    if(!(r.ideal_bits&0x7fffffff)) {r.reason=PaperReject::IdealZero;return r;}
    if((r.ideal_bits&0x7f800000)==0x7f800000) {r.reason=PaperReject::NonfiniteIdeal;return r;}
    r.reason=PaperReject::Accepted;return r;
}
struct PaperCounters {
    uint64_t attempted=0,accepted=0,invalid_input=0,input_zero=0,regime=0,ideal_zero=0,nonfinite_ideal=0;
    void record(PaperReject reason) {
        ++attempted;
        switch(reason) {
            case PaperReject::Accepted:++accepted;break;
            case PaperReject::InvalidInput:++invalid_input;break;
            case PaperReject::InputZero:++input_zero;break;
            case PaperReject::Regime:++regime;break;
            case PaperReject::IdealZero:++ideal_zero;break;
            case PaperReject::NonfiniteIdeal:++nonfinite_ideal;break;
            default:throw std::invalid_argument("invalid rejection reason");
        }
    }
    bool consistent() const {
        return attempted==accepted+invalid_input+input_zero+regime+ideal_zero+nonfinite_ideal;
    }
};
struct PaperFingerprint {
    uint64_t hash=14695981039346656037ULL;
    void add(uint32_t word) {
        for(unsigned i=0;i<4;++i) {hash^=(word>>(8*i))&255;hash*=1099511628211ULL;}
    }
};
struct PaperErrorFraction {
    uint64_t difference,ideal;
    bool outside_band;
    // Threshold=1/denominator; intended denominators 1000,200,100,20.
    bool below(unsigned denominator) const {
        if(denominator<20 || denominator>1000) throw std::invalid_argument("unsupported error threshold");
        return !outside_band && difference*denominator<ideal;
    }
};
inline PaperErrorFraction paper_error_fraction(uint32_t approximate,uint32_t ideal_bits) {
    unsigned e=(ideal_bits>>23)&255;
    uint32_t sig=ideal_bits&0x7fffff;
    if((ideal_bits&0x80000000) || e==255 || (!e && !sig))
        throw std::invalid_argument("positive finite nonzero Ideal required");
    int sf;
    if(e) {sf=int(e)-127;sig|=0x800000;}
    else {sf=-126;while(sig<0x800000) {sig<<=1;--sf;}}
    if(!approximate || (approximate&0x80000000)) return {0,1,true};
    auto u=parse<32,3>(approximate);
    int delta=u.sf-sf;
    // Normalized significands in [1,2): these scale gaps imply >5% error.
    if(delta>=2 || delta<=-2) return {0,1,true};
    constexpr unsigned F=posit_constants<32,3>::FRAC_MAX;
    uint64_t a=u.frac>>(63-F),i=sig;
    if(delta>=0) {a<<=23+delta;i<<=F;}
    else {a<<=23;i<<=F-delta;}
    return {a>i?a-i:i-a,i,false};
}
}
