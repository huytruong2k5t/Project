#pragma once
#include <vector>
#include <utility>
#include "posit_parser.hpp"
#include "posit_packer.hpp"
#include "ops_sel.hpp"
#include "sac.hpp"
#include "sbm.hpp"
#include "mul_norm.hpp"
namespace l1 {
struct IterConfig {
    bool exact = false;
    unsigned n = 2, ops = 0;
    ShiftRound scheme = ShiftRound::FLOOR;
    RoundMode rounding = RoundMode::TRUNC;
};
struct IterStep { unsigned sa, scale; uint64_t fx, acc; bool sticky; };
template<int NB, int ES> struct IterResult {
    posit_storage_t<NB> bits{};
    posit_unpacked<NB, ES> unpacked{};
    unsigned iterations = 0;
    bool swapped = false, approx_cut = false, input_cut = false;
    bool inexact = false, saturated = false;
    uint64_t remaining_fx = 0;
};
template<int NB, int ES, unsigned FRAC_W = 12, unsigned N_MAX = 8,
         bool EXACT_EN = true, bool OPS_EN = true>
class L1MultiplierIter {
public:
    static constexpr unsigned F = posit_constants<NB, ES>::FRAC_MAX;
    static_assert(NB >= 4 && NB <= 32 && ES >= 0 && ES <= NB - 4,
                  "unsupported posit configuration");
    static_assert(FRAC_W >= 1 && FRAC_W <= 27, "unsupported FRAC_W");
    static_assert(F >= 1 && F <= 27, "supported exact fraction width is 1..27");
    using storage_t = posit_storage_t<NB>;
    static IterResult<NB, ES> mul(storage_t a, storage_t b,
                                IterConfig cfg = {}, std::vector<IterStep>* trace = nullptr) {
        if (cfg.ops > 1 || (!OPS_EN && cfg.ops != 0))
            throw std::invalid_argument("unsupported OPS policy");
        if ((cfg.exact && !EXACT_EN) || (!cfg.exact && cfg.n > N_MAX))
            throw std::invalid_argument("unsupported multiplier mode/iteration limit");
        if (cfg.scheme != ShiftRound::FLOOR && cfg.scheme != ShiftRound::STICKY_ACC)
            throw std::invalid_argument("unsupported shift rounding scheme");
        if (cfg.rounding != RoundMode::RNE && cfg.rounding != RoundMode::TRUNC)
            throw std::invalid_argument("unsupported final rounding mode");
        if (trace) trace->clear();
        auto ua = parse<NB, ES>(a), ub = parse<NB, ES>(b);
        IterResult<NB, ES> result;
        if (ua.is_nar || ub.is_nar || ua.is_zero || ub.is_zero) {
            result.bits = (ua.is_nar || ub.is_nar) ? storage_t(uint64_t(1) << (NB - 1)) : 0;
            result.unpacked = parse<NB, ES>(result.bits);
            return result;
        }
        const unsigned w = cfg.exact ? F : FRAC_W;
        const uint64_t mask = (uint64_t(1) << w) - 1;
        uint64_t xa = (ua.frac >> (63 - w)) & mask;
        uint64_t xb = (ub.frac >> (63 - w)) & mask;
        const uint64_t low = (uint64_t(1) << (63 - w)) - 1;
        result.input_cut = !cfg.exact && ((ua.frac | ub.frac) & low);
        result.swapped = ops_swap(xa, xb, cfg.ops);
        if (result.swapped) std::swap(xa, xb);
        SacState sac(xa, w);
        const unsigned q = cfg.exact ? 2 * F : w + (cfg.scheme == ShiftRound::STICKY_ACC ? 2 : 0);
        SbmState sbm((uint64_t(1) << w) | xb, w, q);
        const unsigned limit = cfg.exact ? F : cfg.n;
        bool floor_tail = false;
        while (sac.fx && sac.iterations < limit) {
            unsigned sa = sac.step();
            floor_tail = floor_tail || (sbm.y & ((uint64_t(1) << sac.scale) - 1));
            sbm.add(sac.scale, cfg.exact || cfg.scheme == ShiftRound::STICKY_ACC);
            if (trace) trace->push_back({sa, sac.scale, sac.fx, sbm.acc, sbm.sticky});
        }
        result.iterations = sac.iterations;
        result.remaining_fx = sac.fx;
        result.approx_cut = sac.fx != 0;
        // Input truncation and omitted terms are algorithmic approximations;
        // only SBM's numerical tail participates in final RNE sticky.
        result.unpacked = mul_norm<NB, ES>(sbm.acc, q, ua.sf + ub.sf,
                                           ua.sign ^ ub.sign, sbm.sticky);
        result.bits = pack<NB, ES>(result.unpacked, cfg.rounding);
        auto canonical = parse<NB, ES>(result.bits);
        result.saturated = result.unpacked.sf < -posit_constants<NB, ES>::SF_MAX ||
            result.unpacked.sf > posit_constants<NB, ES>::SF_MAX ||
            (result.unpacked.sf == posit_constants<NB, ES>::SF_MAX &&
             result.unpacked.frac > posit_constants<NB, ES>::HIDDEN_BIT);
        result.inexact = result.input_cut || result.approx_cut || floor_tail ||
            !result.unpacked.exact || canonical.sf != result.unpacked.sf ||
            canonical.frac != result.unpacked.frac;
        return result;
    }
};
}
