#pragma once
#include <algorithm>
#include <cstdint>
#include <stdexcept>
#include "l1_multiplier_iter.hpp"
#include "posit_mac.hpp"

// F_W: one addition after FLOOR prepack, before the only Posit rounding.
// W includes signed retained sum only; signed/nonzero residual is separate metadata.
// Precision bound is part of the admitted contract, not a claim about arbitrary sums.
namespace l1 {
template<int NB,int ES,unsigned FW=12,unsigned W=32> class FusedWindow {
public:
    using u128=unsigned __int128;
    using T=posit_storage_t<NB>;
    static constexpr unsigned F=NB-3-ES, Q=W-3;
    static constexpr uint32_t NAR=uint32_t(1)<<(NB-1);
    static_assert(W<=96 && Q>=F+3 && Q>=FW+4,"fused window precision bound");
    struct Trace {
        int anchor=0;
        int p_sf=0,c_sf=0;
        u128 p_retained=0,c_retained=0,magnitude=0;
        bool residual=false,residual_sign=false,borrow=false;
        bool sign=false,zero=true;
        int sf=0;
        unsigned left_normalize=0;
        bool guard=false,round=false,sticky=false,retained_lsb=false;
        bool near_before=false,near_after=false;
    };
    struct Result { uint32_t bits=0; unsigned flags=0; Trace trace{}; uint32_t c_eff=0; };
    static unsigned top(u128 value) {
        if (!value) throw std::invalid_argument("top of zero");
        unsigned h=0;
        while (value>>=1) ++h;
        return h;
    }
    static u128 align(uint64_t coefficient,int shift,bool& tail) {
        if (!coefficient) return 0;
        if (shift>=0) {
            if (shift>=128) throw std::overflow_error("window shift left");
            return u128(coefficient)<<unsigned(shift);
        }
        const unsigned d=unsigned(-shift);
        tail=d>=64 ? coefficient!=0 : (coefficient&((uint64_t(1)<<d)-1))!=0;
        return d>=64 ? 0 : u128(coefficient>>d);
    }
    static Result add(const PrepackProduct& p,T c) {
        if (p.numerical_sticky) throw std::invalid_argument("F_W requires FLOOR dyadic prepack");
        Result out;
        if (p.is_nar || uint32_t(c)==NAR) {out.bits=NAR;out.flags=16;out.trace.zero=false;out.trace.sign=true;return out;}
        const auto cv=parse<NB,ES>(c);
        const bool pzero=p.is_zero || !p.magnitude;
        if (!pzero && (p.fractional_bits!=FW || p.magnitude<(uint64_t(1)<<FW)
            || p.magnitude>=(uint64_t(1)<<(FW+2)))) throw std::invalid_argument("F_W prepack profile");
        out.flags=pzero ? 0 : ((p.input_cut||p.iteration_cut||p.term_cut)?2u:0u)|(p.iteration_cut?1u:0u);
        if (pzero && cv.is_zero) return out;
        auto& t=out.trace;
        t.p_sf=pzero ? 0 : p.scale+int(top(p.magnitude))-int(p.fractional_bits);
        t.c_sf=cv.sf;
        t.anchor=pzero ? cv.sf : cv.is_zero ? t.p_sf : std::max(t.p_sf,cv.sf);
        bool ptail=false,ctail=false;
        t.p_retained=align(pzero?0:p.magnitude,int(Q)+p.scale-int(p.fractional_bits)-t.anchor,ptail);
        t.c_retained=align(cv.is_zero?0:cv.frac>>(63-F),int(Q)+cv.sf-int(F)-t.anchor,ctail);
        if (ptail && ctail) throw std::logic_error("precision bound: two residuals");
        t.residual=ptail||ctail;
        t.residual_sign=ptail ? p.sign : cv.sign;
        t.near_before=!pzero&&!cv.is_zero&&(p.sign!=cv.sign)&&std::abs(t.p_sf-cv.sf)<=4;
        if (t.p_retained && t.c_retained) {
            const int ps=int(top(t.p_retained)),cs=int(top(t.c_retained));
            t.near_after=(p.sign!=cv.sign)&&std::abs(ps-cs)<=4;
        }
        if (p.sign==cv.sign) {t.magnitude=t.p_retained+t.c_retained;t.sign=p.sign;}
        else if (t.p_retained>=t.c_retained) {t.magnitude=t.p_retained-t.c_retained;t.sign=p.sign;}
        else {t.magnitude=t.c_retained-t.p_retained;t.sign=cv.sign;}
        if (!t.magnitude) {
            if (t.residual) throw std::logic_error("zero retained with signed residual");
            t.sign=false;return out;
        }
        if (t.residual && t.residual_sign!=t.sign) {--t.magnitude;t.borrow=true;}
        if (!t.magnitude) throw std::logic_error("borrow exhausted retained sum");
        if (t.magnitude>=(u128(1)<<(W-1))) throw std::overflow_error("signed retained window");
        t.zero=false;
        const unsigned h=top(t.magnitude);
        t.sf=t.anchor+int(h)-int(Q);
        t.left_normalize=h<Q?Q-h:0;
        if (t.residual && t.left_normalize>1) throw std::logic_error("residual deep cancellation");
        bool low=t.residual;
        uint64_t mantissa;
        if (h>63) {
            const unsigned d=h-63;
            low|=(t.magnitude&((u128(1)<<d)-1))!=0;
            mantissa=uint64_t(t.magnitude>>d);
        } else mantissa=uint64_t(t.magnitude)<<(63-h);
        const posit_unpacked<NB,ES> u{t.sign,false,false,t.sf,mantissa,!low};
        out.bits=uint32_t(pack<NB,ES>(u,RoundMode::RNE));
        const auto rounded=parse<NB,ES>(T(out.bits));
        const auto rf=mac_round_flags(u,rounded);
        out.flags|=(rf.sat_max?8u:0u)|(rf.sat_min?4u:0u)|(rf.inexact?2u:0u);
        // Final encoding G/R/S, for debug; clamp reports no fabricated round bits.
        const int limit=(NB-2)*(1<<ES);
        if (t.sf>=-limit && t.sf<limit) {
            int k=t.sf/(1<<ES);
            if (t.sf<0 && t.sf%(1<<ES)) --k;
            const int exponent=t.sf-k*(1<<ES);
            const unsigned run=unsigned(k>=0?k+1:-k),header=run+1+ES;
            auto stream_bit=[&](unsigned index) {
                if (index<run) return k>=0;
                if (index==run) return k<0;
                if (index<header) return bool((exponent>>(header-1-index))&1);
                const int pos=int(h)-1-int(index-header);
                return pos>=0 && bool((t.magnitude>>unsigned(pos))&1);
            };
            t.retained_lsb=stream_bit(NB-2);
            t.guard=stream_bit(NB-1);t.round=stream_bit(NB);
            t.sticky=t.residual;
            for (unsigned i=NB+1;i<header+h;++i) t.sticky|=stream_bit(i);
        }
        return out;
    }
    static Result mac(T a,T b,T c,IterConfig config) {
        if (config.exact || config.scheme!=ShiftRound::FLOOR || config.rounding!=RoundMode::RNE)
            throw std::invalid_argument("F_W approximate FLOOR/RNE only");
        const auto m=L1MultiplierIter<NB,ES,FW>::mul(a,b,config);
        return add(m.prepack,c);
    }
};
template<int NB,int ES,unsigned FW=12,unsigned W=32> class FusedWindowAccumulator {
    using T=posit_storage_t<NB>;
    using Model=FusedWindow<NB,ES,FW,W>;
    T value_=0;
    uint64_t commits_=0;
public:
    void reset() {value_=0;commits_=0;}
    T value() const {return value_;}
    uint64_t commits() const {return commits_;}
    typename Model::Result step(T a,T b,T c,bool acc_mode,bool acc_clr,IterConfig config) {
        if (acc_clr && !acc_mode) throw std::invalid_argument("acc_clr requires acc_mode");
        const T effective=acc_mode ? (acc_clr?T(0):value_) : c;
        auto result=Model::mac(a,b,effective,config);
        result.c_eff=uint32_t(effective);
        if (acc_mode) value_=T(result.bits);
        ++commits_;
        return result;
    }
};
}
