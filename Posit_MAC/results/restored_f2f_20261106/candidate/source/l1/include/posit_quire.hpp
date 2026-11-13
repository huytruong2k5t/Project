#pragma once
#include <array>
#include <cstdint>
#include <stdexcept>
#include "posit_mac_full_term.hpp"

// Fixed Q12-1024 model: signed972, grid2^-480. No RNE in mac().
namespace quire32 {
using Words = std::array<uint32_t,31>;
struct Response { uint32_t bits=0; unsigned flags=0; bool overflow=false; };
class Model {
public:
    Words q{};
    unsigned count=0;
    bool nar=false, invalid=false, overflow=false, loss=false, cut=false;
    void clear() { *this=Model{}; }
    static bool bit(const Words& v,int i) {
        return i>=0 && i<972 && ((v[unsigned(i)/32]>>(unsigned(i)%32))&1);
    }
    static Words negate(Words v) {
        uint64_t carry=1;
        for (auto& word:v) { const uint64_t s=uint64_t(~word)+carry; word=uint32_t(s); carry=s>>32; }
        v[30]&=4095;
        return v;
    }
    void mac(uint32_t a,uint32_t b,unsigned n=12,unsigned ops=1) {
        if (count==1024 || n>12 || ops>1) throw std::invalid_argument("quire MAC rejected");
        const auto p=full_term32::multiply(a,b,{true,n,ops}).value;
        ++count;
        nar|=p.is_nar;
        loss|=p.input_cut||p.iteration_cut;
        cut|=p.iteration_cut;
        if (nar||invalid||p.is_zero) return;
        Words term{};
        int shift=p.scale+456;
        uint64_t m=p.magnitude;
        if (shift<0) {
            if (-shift>=64 || (m&((uint64_t(1)<<unsigned(-shift))-1)))
                throw std::logic_error("quire grid loses product bit");
            m>>=unsigned(-shift); shift=0;
        }
        for(unsigned i=0;i<26;++i) if((m>>i)&1) {
            const unsigned at=unsigned(shift)+i;
            if(at>=971) throw std::overflow_error("quire term bound");
            term[at/32]|=uint32_t(1)<<(at%32);
        }
        if(p.sign) term=negate(term);
        Words sum{}; uint64_t carry=0;
        for(unsigned i=0;i<31;++i) {
            const uint64_t s=uint64_t(q[i])+term[i]+carry;
            sum[i]=uint32_t(s); carry=s>>32;
        }
        sum[30]&=4095;
        if(bit(q,971)==bit(term,971) && bit(sum,971)!=bit(q,971)) {
            invalid=true;overflow=true;return;
        }
        q=sum;
    }
    Response ack() const {
        return {0,(nar||invalid)?16u:((loss?2u:0u)|(cut?1u:0u)),overflow};
    }
    Response read() const {
        auto r=ack(); if(nar||invalid){r.bits=0x80000000u;return r;}
        const bool negative=bit(q,971);
        const Words mag=negative?negate(q):q;
        int h=971;while(h>=0&&!bit(mag,h))--h;
        if(h<0)return r;
        l1::posit_unpacked<32,3> u{};
        u.sign=negative;u.sf=h-480;u.exact=true;
        for(int i=0;i<64;++i) if(bit(mag,h-i))u.frac|=uint64_t(1)<<(63-i);
        for(int i=0;i<h-63;++i) if(bit(mag,i))u.exact=false;
        r.bits=l1::pack<32,3>(u,l1::RoundMode::RNE);
        const auto flags=l1::mac_round_flags(u,l1::parse<32,3>(r.bits));
        r.flags|=(flags.sat_max?8u:0u)|(flags.sat_min?4u:0u)|(flags.inexact?2u:0u);
        return r;
    }
};
}
