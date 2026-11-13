#pragma once
#include <algorithm>
#include <array>
#include <cstdint>
#include <stdexcept>
#include "../l1/include/prepack_product.hpp"

// Independent raw decoder, full-grid integer arithmetic and serial RNE encoder.
// No L1 parser/packer, window alignment, floating point, or host long-double oracle.
namespace week12_reference {
using u128 = unsigned __int128;
template<int NB, int ES> class Oracle {
public:
    static constexpr int F = NB-3-ES;
    static constexpr int LIMIT = (NB-2)*(1<<ES);
    static constexpr int BASE = 2*LIMIT+2*F;
    static constexpr unsigned WORDS = (4*LIMIT+2*F+4+63)/64;
    static constexpr uint32_t NAR = uint32_t(1)<<(NB-1);
    static constexpr uint32_t MASK = uint32_t((uint64_t(1)<<NB)-1);
    using Wide = std::array<uint64_t, WORDS>;
    struct Decoded { bool sign; uint64_t coefficient; int sf; };
    struct Result {
        uint32_t bits = 0;
        unsigned flags = 0;
        bool sign = false;
        bool zero = true;
        int sf = 0;
        bool guard = false, round = false, sticky = false;
        Wide magnitude{};
    };
    struct Slice { u128 magnitude; bool tail; int anchor; };

    static Decoded decode(uint32_t raw) {
        raw &= MASK;
        const bool negative = (raw&NAR)!=0;
        const uint32_t code = negative ? (0u-raw)&MASK : raw;
        if (!code) return {false,0,0};
        if (code==NAR) throw std::invalid_argument("oracle decode NaR");
        int position=NB-2, run=0;
        const bool regime=(code>>position)&1;
        while (position>=0 && bool((code>>position)&1)==regime) {++run;--position;}
        if (position>=0) --position;
        int exponent=0;
        for (int i=0;i<ES;++i) {
            exponent*=2;
            if (position>=0) exponent|=(code>>position--)&1;
        }
        const unsigned available=unsigned(position+1);
        const uint64_t low=code&((uint64_t(1)<<available)-1);
        return {negative,(uint64_t(1)<<F)|(low<<(F-available)),
                (regime?run-1:-run)*(1<<ES)+exponent};
    }
    static int highest(uint64_t value) {
        int h=-1;
        while (value) {++h;value>>=1;}
        return h;
    }
    static Wide expand(uint64_t coefficient,int exponent) {
        Wide out{};
        if (!coefficient) return out;
        const int shift=BASE+exponent;
        if (shift<0 || unsigned(shift)/64>=WORDS) throw std::overflow_error("oracle grid");
        const unsigned word=unsigned(shift)/64, bit=unsigned(shift)%64;
        out[word]=coefficient<<bit;
        if (bit && word+1<WORDS) out[word+1]=coefficient>>(64-bit);
        return out;
    }
    static bool bit(const Wide& v,int position) {
        return position>=0 && unsigned(position)/64<WORDS && ((v[unsigned(position)/64]>>(unsigned(position)%64))&1);
    }
    static bool below(const Wide& v,int high) {
        if (high<0) return false;
        const unsigned word=std::min(unsigned(high)/64,WORDS-1);
        for (unsigned i=0;i<word;++i) if (v[i]) return true;
        const unsigned count=unsigned(high)%64+1;
        return (v[word] & (count==64 ? UINT64_MAX : (uint64_t(1)<<count)-1))!=0;
    }
    static int top(const Wide& v) {
        for (int i=int(WORDS)-1;i>=0;--i) {
            if (v[unsigned(i)]) return 64*i+highest(v[unsigned(i)]);
        }
        return -1;
    }
    static l1::PrepackProduct product(uint32_t a,uint32_t b) {
        l1::PrepackProduct p;
        p.fractional_bits=2*F;
        p.magnitude_bits=2*F+2;
        if (a==NAR || b==NAR) {p.is_nar=true;return p;}
        if (!a || !b) {p.is_zero=true;return p;}
        const auto x=decode(a),y=decode(b);
        p.magnitude=x.coefficient*y.coefficient;
        p.scale=x.sf+y.sf;
        p.sign=x.sign!=y.sign;
        return p;
    }
    static Result add(const l1::PrepackProduct& p,uint32_t c,unsigned incoming=0) {
        if (p.numerical_sticky) throw std::invalid_argument("oracle requires dyadic prepack");
        Result out;
        if (p.is_nar || c==NAR || (incoming&16)) {
            out.bits=NAR;out.flags=16;out.zero=false;out.sign=true;return out;
        }
        const auto cv=decode(c);
        auto x=expand(p.is_zero?0:p.magnitude,p.scale-int(p.fractional_bits));
        auto y=expand(cv.coefficient,cv.sf-F);
        int comparison=0;
        for (int i=int(WORDS)-1;i>=0;--i) {
            if (x[unsigned(i)]!=y[unsigned(i)]) {comparison=x[unsigned(i)]>y[unsigned(i)]?1:-1;break;}
        }
        out.sign=p.sign;
        if (p.sign==cv.sign) {
            uint64_t carry=0;
            for (unsigned i=0;i<WORDS;++i) {
                const u128 total=u128(x[i])+y[i]+carry;
                out.magnitude[i]=uint64_t(total);carry=uint64_t(total>>64);
            }
            if (carry) throw std::overflow_error("oracle sum");
        } else {
            if (comparison<0) {std::swap(x,y);out.sign=cv.sign;}
            uint64_t borrow=0;
            for (unsigned i=0;i<WORDS;++i) {
                const u128 sub=u128(y[i])+borrow;
                out.magnitude[i]=x[i]-uint64_t(sub);
                borrow=u128(x[i])<sub;
            }
            if (borrow) throw std::logic_error("oracle borrow");
        }
        const int h=top(out.magnitude);
        out.flags=incoming&15;
        if (h<0) {out.sign=false;return out;}
        out.zero=false;
        out.sf=h-BASE;
        uint32_t code;
        if (out.sf>=LIMIT) code=NAR-1;
        else if (out.sf < -LIMIT) code=1;
        else {
            int k=out.sf/(1<<ES);
            if (out.sf<0 && out.sf%(1<<ES)) --k;
            const int exponent=out.sf-k*(1<<ES);
            const unsigned run=unsigned(k>=0?k+1:-k),header=run+1+ES;
            auto stream_bit=[&](unsigned index) {
                if (index<run) return k>=0;
                if (index==run) return k<0;
                if (index<header) return bool((exponent>>(header-1-index))&1);
                return bit(out.magnitude,h-1-int(index-header));
            };
            code=0;
            for (unsigned i=0;i<unsigned(NB-1);++i) code=2*code+stream_bit(i);
            out.guard=stream_bit(NB-1);out.round=stream_bit(NB);
            for (unsigned i=NB+1;i<header;++i) out.sticky|=stream_bit(i);
            const unsigned fraction_used=unsigned(NB+1)>header?unsigned(NB+1)-header:0;
            out.sticky|=below(out.magnitude,h-1-int(fraction_used));
            if (out.guard && ((code&1)||out.round||out.sticky)) ++code;
            code=std::max(1u,std::min(NAR-1,code));
        }
        out.bits=(out.sign?0u-code:code)&MASK;
        const auto rounded=decode(out.bits);
        Wide hidden{};
        hidden[unsigned(h)/64]=uint64_t(1)<<(unsigned(h)%64);
        const bool sat_max=out.sf>LIMIT || (out.sf==LIMIT && out.magnitude!=hidden);
        const bool sat_min=out.sf < -LIMIT;
        const bool inexact=expand(rounded.coefficient,rounded.sf-F)!=out.magnitude || rounded.sign!=out.sign;
        out.flags|=(sat_max?8u:0u)|(sat_min?4u:0u)|(inexact?2u:0u);
        return out;
    }
    static Slice slice(const l1::PrepackProduct& p,uint32_t c,const Result& result,unsigned width) {
        const auto cv=decode(c);
        const bool pzero=p.is_zero || !p.magnitude;
        const int psf=pzero ? -2*LIMIT-2*F-1 : p.scale+highest(p.magnitude)-int(p.fractional_bits);
        const int anchor=pzero ? cv.sf : (!cv.coefficient ? psf : std::max(psf,cv.sf));
        const int low=BASE+anchor-int(width-3);
        u128 retained=0;
        for (unsigned i=0;i<width-1;++i) if (bit(result.magnitude,low+int(i))) retained|=u128(1)<<i;
        return {retained,below(result.magnitude,low-1),anchor};
    }
};
}
