#pragma once
#include <algorithm>
#include <array>
#include <cstdint>
#include <stdexcept>
#include "opt17/full_term_reference.hpp"

// Independent sign/magnitude oracle, grid2^-532, 1024 unsigned magnitude bits.
// Bound: |sum| <=1024*2^480 -> grid coefficient <=2^1022 <2^1024.
// All words are retained. This proves the old single-MAC grid is sufficient
// for this declared L_max; it is NOT a generic unbounded quire claim.
namespace quire_reference {
using Base=week12_reference::Oracle<32,3>;
using Wide=Base::Wide;
using U128=unsigned __int128;
class Oracle {
public:
    Wide magnitude{};
    bool negative=false,nar=false,loss=false,cut=false;
    unsigned count=0;
    void clear(){*this=Oracle{};}
    void add(Wide term,bool sign) {
        if(sign==negative) {
            uint64_t carry=0;
            for(unsigned i=0;i<Base::WORDS;++i) {
                const U128 sum=U128(magnitude[i])+term[i]+carry;
                magnitude[i]=uint64_t(sum);carry=uint64_t(sum>>64);
            }
            if(carry)throw std::overflow_error("quire oracle carry");
        } else {
            bool swap=false;
            for(int i=int(Base::WORDS)-1;i>=0;--i) {
                if(magnitude[unsigned(i)]!=term[unsigned(i)]) {
                    swap=magnitude[unsigned(i)]<term[unsigned(i)];break;
                }
            }
            if(swap){std::swap(magnitude,term);negative=sign;}
            uint64_t borrow=0;
            for(unsigned i=0;i<Base::WORDS;++i) {
                const U128 sub=U128(term[i])+borrow;
                const uint64_t before=magnitude[i];
                magnitude[i]=before-uint64_t(sub);borrow=U128(before)<sub;
            }
            if(borrow)throw std::logic_error("quire oracle borrow");
        }
        if(Base::top(magnitude)<0)negative=false;
    }
    void mac(uint32_t a,uint32_t b,unsigned n=12,unsigned ops=1,bool ideal=false) {
        if(count==1024||n>12||ops>1)throw std::invalid_argument("oracle quire rejected");
        const auto p=ideal?Base::product(a,b):opt17_reference::product(a,b,{true,n,ops});
        ++count;nar|=p.is_nar;loss|=p.input_cut||p.iteration_cut;cut|=p.iteration_cut;
        if(nar||p.is_zero)return;
        add(Base::expand(p.magnitude,p.scale-int(p.fractional_bits)),p.sign);
    }
    unsigned ack_flags() const{return nar?16u:((loss?2u:0u)|(cut?1u:0u));}
    std::array<uint32_t,31> raw() const {
        std::array<uint32_t,31> v{};
        for(unsigned i=0;i<972;++i)if(Base::bit(magnitude,int(i)+52))v[i/32]|=uint32_t(1)<<(i%32);
        if(negative) {
            uint64_t carry=1;
            for(auto& word:v){const uint64_t s=uint64_t(~word)+carry;word=uint32_t(s);carry=s>>32;}
        }
        v[30]&=4095;return v;
    }
    std::pair<uint32_t,unsigned> read() const {
        if(nar)return {0x80000000u,16};
        const int h=Base::top(magnitude);
        unsigned flags=ack_flags();
        if(h<0)return {0,flags};
        const int sf=h-Base::BASE;
        uint32_t code=0;
        if(sf>=240)code=0x7fffffffu;
        else if(sf< -240)code=1;
        else {
            const int k=sf>=0?sf/8:-((-sf+7)/8);
            const unsigned run=unsigned(k>=0?k+1:-k),header=run+4;
            const int exponent=sf-k*8;
            auto stream=[&](unsigned i) {
                if(i<run)return k>=0;
                if(i==run)return k<0;
                if(i<header)return bool((exponent>>(header-1-i))&1);
                return Base::bit(magnitude,h-1-int(i-header));
            };
            for(unsigned i=0;i<31;++i)code=(code<<1)|stream(i);
            const bool guard=stream(31),round=stream(32);
            bool sticky=false;
            for(unsigned i=33;i<header;++i)sticky|=stream(i);
            const unsigned used=33>header?33-header:0;
            sticky|=Base::below(magnitude,h-1-int(used));
            if(guard&&((code&1)||round||sticky))++code;
            code=std::max(1u,std::min(0x7fffffffu,code));
        }
        const uint32_t bits=negative?0u-code:code;
        const auto decoded=Base::decode(bits);
        const auto exact=Base::expand(decoded.coefficient,decoded.sf-26);
        Wide hidden{};hidden[unsigned(h)/64]=uint64_t(1)<<(unsigned(h)%64);
        flags|=((sf>240||(sf==240&&magnitude!=hidden))?8u:0u)
             |(sf< -240?4u:0u)|((exact!=magnitude||decoded.sign!=negative)?2u:0u);
        return {bits,flags};
    }
};
}
