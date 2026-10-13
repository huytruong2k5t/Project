#pragma once
#include <array>
#include "week11_model.hpp"

// Software full-sum reference. This is not the proposed finite RTL window.
namespace week11 {
template<int NB, int ES> class FusedFullSum {
    static constexpr int F=NB-3-ES, LIMIT=(NB-2)*(1<<ES);
    static constexpr int BASE=2*LIMIT+2*F;
    static constexpr unsigned WORDS=(4*LIMIT+2*F+4+63)/64;
    static constexpr uint32_t NAR=uint32_t(1)<<(NB-1);
    static constexpr uint32_t MASK=uint32_t((uint64_t(1)<<NB)-1);
    using Wide=std::array<uint64_t,WORDS>;
    static Wide expand(uint64_t magnitude, int shift) {
        if (shift<0) throw std::runtime_error("F full-sum grid too small");
        Wide value{};
        const unsigned word=unsigned(shift)/64, bit=unsigned(shift)%64;
        if(word>=WORDS) throw std::runtime_error("F full-sum overflow");
        value[word]=magnitude<<bit;
        if(bit && word+1<WORDS) value[word+1]=magnitude>>(64-bit);
        return value;
    }
public:
    struct Result {uint32_t bits; bool sign; int top; bool zero;};
    static Result add(const l1::PrepackProduct& p, uint32_t c) {
        if(p.numerical_sticky) throw std::invalid_argument("FLOOR/exact dyadic required");
        if(p.is_nar || c==NAR) return {NAR,true,0,false};
        const auto u=l1::parse<NB,ES>(l1::posit_storage_t<NB>(c));
        Wide x=expand(p.is_zero?0:p.magnitude,BASE+p.scale-int(p.fractional_bits));
        Wide y=u.is_zero ? Wide{} : expand(u.frac>>(63-F),BASE+u.sf-F);
        Wide sum{};
        bool sign=p.sign;
        int comparison=0;
        for(int i=int(WORDS)-1;i>=0;--i) {
            if(x[unsigned(i)]!=y[unsigned(i)]) {
                comparison=x[unsigned(i)]>y[unsigned(i)]?1:-1; break;
            }
        }
        if(p.sign==u.sign) {
            uint64_t carry=0;
            for(unsigned i=0;i<WORDS;++i) {
                const unsigned __int128 total=static_cast<unsigned __int128>(x[i])+y[i]+carry;
                sum[i]=uint64_t(total); carry=uint64_t(total>>64);
            }
            if(carry) throw std::runtime_error("F sum overflow");
        } else {
            if(comparison<0) {std::swap(x,y);sign=u.sign;}
            uint64_t borrow=0;
            for(unsigned i=0;i<WORDS;++i) {
                const unsigned __int128 sub=static_cast<unsigned __int128>(y[i])+borrow;
                sum[i]=x[i]-uint64_t(sub);
                borrow=static_cast<unsigned __int128>(x[i])<sub;
            }
        }
        int top=int(WORDS*64)-1;
        while(top>=0 && !((sum[unsigned(top)/64]>>(unsigned(top)%64))&1)) --top;
        if(top<0) return {0,false,0,true};
        const int sf=top-BASE;
        uint32_t code;
        if(sf>=LIMIT) code=NAR-1;
        else if(sf < -LIMIT) code=1;
        else {
            int k=sf/(1<<ES);
            if(sf<0 && sf%(1<<ES)) --k;
            const int exponent=sf-k*(1<<ES);
            std::vector<bool> bits;
            bits.insert(bits.end(),k>=0?k+1:-k,k>=0);
            bits.push_back(k<0);
            for(int i=ES-1;i>=0;--i) bits.push_back((exponent>>i)&1);
            for(int i=top-1;i>=0;--i)
                bits.push_back((sum[unsigned(i)/64]>>(unsigned(i)%64))&1);
            while(bits.size()<unsigned(NB+1)) bits.push_back(false);
            code=0;
            for(int i=0;i<NB-1;++i) code=2*code+bits[unsigned(i)];
            bool tail=false;
            for(unsigned i=NB;i<bits.size();++i) tail|=bits[i];
            if(bits[NB-1] && ((code&1)||tail)) ++code;
            code=std::max(1u,std::min(NAR-1,code));
        }
        return {(sign?0u-code:code)&MASK,sign,top,false};
    }
};
}
