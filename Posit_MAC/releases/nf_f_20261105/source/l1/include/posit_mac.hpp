#pragma once
#include "l1_multiplier_exact.hpp"
#include "l1_multiplier_iter.hpp"
#include "posit_adder.hpp"
#include "round_unpacked.hpp"
namespace l1 {
enum class MacVersion { V0, V1 };
struct MacConfig {
    MacVersion version=MacVersion::V1;
    bool exact=true;
    unsigned n=2,ops=0;
    ShiftRound scheme=ShiftRound::FLOOR;
    RoundMode rounding=RoundMode::RNE;
};
struct MacFlags {
    bool nar=false,sat_max=false,sat_min=false,inexact=false,approx_cut=false;
    uint8_t bits() const {
        return uint8_t((nar?16:0)|(sat_max?8:0)|(sat_min?4:0)|(inexact?2:0)|(approx_cut?1:0));
    }
};
template<int NB,int ES> struct MacResult {
    posit_storage_t<NB> bits{};
    MacFlags flags{};
    bool bypass=false;
    unsigned iterations=0;
};
template<int NB,int ES> inline MacFlags mac_round_flags(const posit_unpacked<NB,ES>& u,
                                                       const posit_unpacked<NB,ES>& rounded) {
    MacFlags f;
    if(u.is_nar || u.is_zero) return f;
    constexpr int S=posit_constants<NB,ES>::SF_MAX;
    constexpr uint64_t H=posit_constants<NB,ES>::HIDDEN_BIT;
    f.sat_max=u.sf>S || (u.sf==S && (u.frac>H || !u.exact));
    f.sat_min=u.sf < -S;
    f.inexact=!u.exact || u.sf!=rounded.sf || u.frac!=rounded.frac || u.sign!=rounded.sign;
    return f;
}
template<int NB,int ES,unsigned FRAC_W=12,unsigned N_MAX=8>
class PositMac {
public:
    using T=posit_storage_t<NB>;
    static void validate(const MacConfig& cfg) {
        if((cfg.version!=MacVersion::V0 && cfg.version!=MacVersion::V1) || cfg.ops>1 ||
           (!cfg.exact && cfg.n>N_MAX) ||
           (cfg.scheme!=ShiftRound::FLOOR && cfg.scheme!=ShiftRound::STICKY_ACC) ||
           (cfg.rounding!=RoundMode::RNE && cfg.rounding!=RoundMode::TRUNC))
            throw std::invalid_argument("invalid MAC configuration");
    }
    static MacResult<NB,ES> mac(T a,T b,T c,MacConfig cfg={}) {
        validate(cfg);
        constexpr T nar=T(uint64_t(1)<<(NB-1));
        MacResult<NB,ES> out;
        if(a==nar || b==nar || c==nar) {
            out.bits=nar;out.flags.nar=true;out.bypass=true;return out;
        }
        if(!a || !b) {out.bits=c;out.bypass=true;return out;}
        posit_unpacked<NB,ES> raw;
        if(cfg.exact) raw=L1MultiplierExact<NB,ES>::mul_unpacked(a,b);
        else {
            IterConfig iter;iter.n=cfg.n;iter.ops=cfg.ops;iter.scheme=cfg.scheme;iter.rounding=cfg.rounding;
            auto result=L1MultiplierIter<NB,ES,FRAC_W,N_MAX>::mul(a,b,iter);
            raw=result.unpacked;out.iterations=result.iterations;
            out.flags.inexact=result.inexact;out.flags.approx_cut=result.approx_cut;
        }
        posit_unpacked<NB,ES> product;
        if(cfg.version==MacVersion::V0) {
            product=parse<NB,ES>(pack<NB,ES>(raw,cfg.rounding));
        } else {
            product=round_unpacked<NB,ES>(raw,cfg.rounding);
        }
        auto pf=mac_round_flags(raw,product);
        out.flags.sat_max=pf.sat_max;out.flags.sat_min=pf.sat_min;out.flags.inexact|=pf.inexact;
        if(!c) {out.bits=pack<NB,ES>(product,cfg.rounding);out.bypass=true;return out;}
        auto sum=l1_add_unpacked<NB,ES>(product,parse<NB,ES>(c));
        out.bits=pack<NB,ES>(sum,cfg.rounding);
        auto sf=mac_round_flags(sum,parse<NB,ES>(out.bits));
        out.flags.sat_max|=sf.sat_max;out.flags.sat_min|=sf.sat_min;out.flags.inexact|=sf.inexact;
        return out;
    }
};
template<int NB,int ES,unsigned FRAC_W=12>
inline posit_storage_t<NB> l1_mac(posit_storage_t<NB> a,posit_storage_t<NB> b,
                                posit_storage_t<NB> c,MacConfig cfg={}) {
    return PositMac<NB,ES,FRAC_W>::mac(a,b,c,cfg).bits;
}
// Transaction-level state: step accepts, computes and commits exactly once.
// No cycle/handshake/backpressure timing is modeled by this class.
template<int NB,int ES,unsigned FRAC_W=12> class MacAccumulator {
    using T=posit_storage_t<NB>;
    T accumulator_=0;
    bool nar_=false;
    uint64_t commits_=0;
public:
    void reset() {accumulator_=0;nar_=false;commits_=0;}
    T value() const {return accumulator_;}
    bool is_nar() const {return nar_;}
    uint64_t commits() const {return commits_;}
    MacResult<NB,ES> step(T a,T b,T c,bool acc_mode,bool acc_clr,MacConfig cfg={}) {
        if(acc_clr && !acc_mode) throw std::invalid_argument("acc_clr requires acc_mode");
        T effective=acc_mode?(acc_clr?T(0):accumulator_):c;
        auto result=PositMac<NB,ES,FRAC_W>::mac(a,b,effective,cfg);
        if(acc_mode) {accumulator_=result.bits;nar_=result.flags.nar;++commits_;}
        return result;
    }
};
}
