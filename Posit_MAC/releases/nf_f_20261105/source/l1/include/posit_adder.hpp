#pragma once
#include <algorithm>
#include <stdexcept>
#include "posit_parser.hpp"
#include "posit_packer.hpp"
namespace l1 {
struct AdderTrace {
    int delta_sf=0,alignment_shift=0,left_shift=0;
    bool swapped=false,subtract=false,clamped=false,alignment_tail=false;
    bool carry=false,cancellation_zero=false,guard=false,round=false,sticky=false;
};
template<int NB,int ES> class PositAdder {
public:
    using T=posit_storage_t<NB>;
    static constexpr int F=posit_constants<NB,ES>::FRAC_MAX;
    static constexpr int Q=F+3; // hidden + fraction + guard/round/jammed sticky
    static_assert(NB>=4 && NB<=32 && ES>=0 && ES<=6 && F>=1,"supported posit adder format");
    // Inputs must be exact normalized operands at <=F fractional precision.
    // For MAC v1, round_unpacked(product) supplies this contract.
    static posit_unpacked<NB,ES> add_unpacked(posit_unpacked<NB,ES> a,
                                            posit_unpacked<NB,ES> b,AdderTrace* trace=nullptr) {
        if(trace) *trace=AdderTrace{};
        posit_unpacked<NB,ES> out{};out.exact=true;
        if(a.is_nar || b.is_nar) {out.is_nar=true;out.sign=true;return out;}
        if(a.is_zero && b.is_zero) {out.is_zero=true;return out;}
        const uint64_t precision_mask=(uint64_t(1)<<(63-F))-1;
        for(const auto& u:{a,b}) if(!u.is_zero &&
            (!u.exact || !(u.frac>>63) || (u.frac&precision_mask) ||
             u.sf < -posit_constants<NB,ES>::SF_MAX || u.sf > posit_constants<NB,ES>::SF_MAX))
            throw std::invalid_argument("adder requires exact normalized operands; round product first");
        if(a.is_zero) return b;
        if(b.is_zero) return a;
        bool swapped=a.sf<b.sf || (a.sf==b.sf && a.frac<b.frac);
        if(swapped) std::swap(a,b);
        const int d=a.sf-b.sf;
        uint64_t x=a.frac>>(63-Q),y=b.frac>>(63-Q);
        bool tail=false,clamped=d>F+2;
        if(clamped) {y=1;tail=true;} // bypass smaller operand directly to sticky
        else if(d) {
            tail=(y&((uint64_t(1)<<d)-1))!=0;
            y=(y>>d)|uint64_t(tail);
        }
        bool subtract=a.sign!=b.sign;
        // Jammed subtraction accounts for borrowing from the discarded tail.
        // If a tail is lost, x has zero low G/R/S bits; x-jam(y) preserves
        // the required sticky class. Deep cancellation only occurs without loss.
        uint64_t magnitude=subtract?x-y:x+y;
        if(trace) {
            trace->swapped=swapped;trace->subtract=subtract;trace->delta_sf=d;
            trace->alignment_shift=std::min(d,F+2);trace->clamped=clamped;
            trace->alignment_tail=tail;
        }
        if(!magnitude) {
            out.is_zero=true;if(trace) trace->cancellation_zero=true;return out;
        }
        int sf=a.sf;unsigned left=0;
        if(magnitude>=(uint64_t(2)<<Q)) {
            tail|=(magnitude&1)!=0;
            magnitude=(magnitude>>1)|(magnitude&1);++sf;
            if(trace) trace->carry=true;
        }
        while(magnitude<(uint64_t(1)<<Q)) {magnitude<<=1;--sf;++left;}
        out={a.sign,false,false,sf,magnitude<<(63-Q),!tail};
        if(trace) {
            trace->left_shift=int(left);trace->guard=(magnitude&4)!=0;
            trace->round=(magnitude&2)!=0;trace->sticky=(magnitude&1)!=0 || tail;
        }
        return out;
    }
    static T add(T a,T b,RoundMode mode=RoundMode::RNE,AdderTrace* trace=nullptr) {
        if(mode!=RoundMode::RNE && mode!=RoundMode::TRUNC) throw std::invalid_argument("adder rounding mode");
        return pack<NB,ES>(add_unpacked(parse<NB,ES>(a),parse<NB,ES>(b),trace),mode);
    }
};
template<int NB,int ES>
inline posit_storage_t<NB> l1_add(posit_storage_t<NB> a,posit_storage_t<NB> b,
                                RoundMode mode=RoundMode::RNE,AdderTrace* trace=nullptr) {
    return PositAdder<NB,ES>::add(a,b,mode,trace);
}
template<int NB,int ES>
inline posit_unpacked<NB,ES> l1_add_unpacked(const posit_unpacked<NB,ES>& a,
                                          const posit_unpacked<NB,ES>& b,AdderTrace* trace=nullptr) {
    return PositAdder<NB,ES>::add_unpacked(a,b,trace);
}
}
