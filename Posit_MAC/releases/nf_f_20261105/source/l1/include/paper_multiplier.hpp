#pragma once
#include <array>
#include <stdexcept>
#include <vector>
#include "posit_parser.hpp"
#include "posit_packer.hpp"
#include "ops_sel.hpp"
#include "paper_ops.hpp"
#include "paper_fig3_accumulator.hpp"
namespace l1 {
// Separate research profile: n includes the first power-of-two term.
enum class PaperOps { PredictN2, MinPopcount, FixedA, PredictN2Relative, PredictN2Pattern };
struct PaperStep {
    unsigned iteration;
    uint64_t mantissa;
    int exponent, power;
    bool round_up;
    int coefficient;
    uint64_t next_mantissa;
    int next_exponent;
    int64_t accumulator;
    bool term_tail;
};
struct PaperSac {
    uint64_t mantissa;
    unsigned width;
    int exponent = 0, coefficient = 1;
    bool complement;
    PaperSac(uint64_t m, unsigned w, bool use_complement = true)
        : mantissa(m), width(w), complement(use_complement) {
        if (w < 1 || w > 27 || m < (uint64_t(1) << w) || m >= (uint64_t(2) << w))
            throw std::invalid_argument("paper mantissa/width");
    }
    void advance(bool up) {
        const uint64_t hidden = uint64_t(1) << width;
        uint64_t tail = up ? (2 * hidden - mantissa - (complement ? 1 : 0))
                           : mantissa - hidden;
        if (up) coefficient = -coefficient;
        if (!tail) { mantissa = 0; return; }
        unsigned shift = 0;
        while (tail < hidden) { tail <<= 1; ++shift; }
        mantissa = tail;
        exponent -= int(shift);
    }
};
struct PaperConfig {
    unsigned n = 3;
    PaperOps ops = PaperOps::PredictN2;
    bool complement = true;
    RoundMode rounding = RoundMode::TRUNC;
    bool anchor_first = false;
    unsigned accumulator_guard = 0;
};
// Reconstruction candidate, separately selectable; legacy defaults stay fixed.
inline PaperConfig paper_source_config() {
    PaperConfig cfg;cfg.ops=PaperOps::PredictN2Pattern;
    cfg.anchor_first=true;cfg.accumulator_guard=12;
    return cfg;
}
// Fig.3-informed finite-width reconstruction, distinct from guard12 source.
// PT2 padding and tie-A remain local reconstruction assumptions.
inline PaperConfig paper_fig3_config() {
    PaperConfig cfg = paper_source_config();
    cfg.accumulator_guard = 0;
    return cfg;
}
template<int NB, int ES> struct PaperResult {
    posit_storage_t<NB> bits{};
    posit_unpacked<NB, ES> unpacked{};
    unsigned iterations = 0;
    bool swapped = false, input_cut = false, remainder = false, shift_tail = false;
};
template<int NB = 32, int ES = 3, unsigned W = 12>
class PaperMultiplier {
    static_assert(W >= 7 && W <= 27, "paper width supports seven-bit OPS");
public:
    using T = posit_storage_t<NB>;
    static PaperResult<NB, ES> mul(T a, T b, PaperConfig cfg = {},
                                  std::vector<PaperStep>* trace = nullptr) {
        if (!cfg.n || cfg.n > 8 ||
            (cfg.ops != PaperOps::PredictN2 && cfg.ops != PaperOps::MinPopcount &&
             cfg.ops != PaperOps::FixedA && cfg.ops != PaperOps::PredictN2Relative &&
             cfg.ops != PaperOps::PredictN2Pattern) ||
            cfg.accumulator_guard>12 || W+cfg.accumulator_guard>39 ||
            (cfg.rounding != RoundMode::TRUNC && cfg.rounding != RoundMode::RNE))
            throw std::invalid_argument("paper profile configuration");
        if (trace) trace->clear();
        auto ua = parse<NB, ES>(a), ub = parse<NB, ES>(b);
        PaperResult<NB, ES> out;
        if (ua.is_nar || ub.is_nar || ua.is_zero || ub.is_zero) {
            out.bits = ua.is_nar || ub.is_nar ? T(uint64_t(1) << (NB - 1)) : T(0);
            out.unpacked = parse<NB, ES>(out.bits);
            return out;
        }
        const uint64_t hidden = uint64_t(1) << W;
        uint64_t x = ua.frac >> (63 - W), y = ub.frac >> (63 - W);
        out.input_cut = (ua.frac | ub.frac) & ((uint64_t(1) << (63 - W)) - 1);
        if (cfg.ops == PaperOps::PredictN2) {
            out.swapped = paper_ops_select<W>(uint32_t(x - hidden), uint32_t(y - hidden)).swapped;
        } else if(cfg.ops==PaperOps::PredictN2Relative) {
            out.swapped = paper_ops_select_relative<W>(uint32_t(x-hidden),uint32_t(y-hidden)).swapped;
        } else if(cfg.ops==PaperOps::PredictN2Pattern) {
            out.swapped=paper_ops_select_pattern<W>(uint32_t(x-hidden),uint32_t(y-hidden)).swapped;
        } else if (cfg.ops == PaperOps::MinPopcount)
            out.swapped = fraction_popcount(y - hidden) < fraction_popcount(x - hidden);
        if (out.swapped) std::swap(x, y);
        PaperSac sac(x, W, cfg.complement);
        const int anchor=cfg.anchor_first?int(x>=hidden+(hidden>>1)):0;
        const uint64_t acc_hidden=hidden<<cfg.accumulator_guard;
        int64_t acc = 0;
        PaperFig3Accumulator finite_acc(W);
        const bool finite_profile = cfg.anchor_first && cfg.accumulator_guard == 0;
        while (sac.mantissa && out.iterations < cfg.n) {
            uint64_t before = sac.mantissa;
            int exponent = sac.exponent, coefficient = sac.coefficient;
            bool up = (before & (hidden >> 1)) != 0;
            int power = exponent + int(up);
            uint64_t term;
            bool tail = false;
            const int aligned=power-anchor+int(cfg.accumulator_guard);
            if (aligned >= 0) term = y << aligned;
            else {
                unsigned shift = unsigned(-aligned);
                term = shift >= 64 ? 0 : y >> shift;
                tail = shift >= 64 ? y != 0 : (y & ((uint64_t(1) << shift) - 1)) != 0;
            }
            if (finite_profile) {
                if (aligned > 0) {
                    throw std::logic_error("Fig3 shift must be nonnegative");
                }
                const uint64_t finite_term = finite_acc.update(y, unsigned(-aligned), coefficient);
                if (finite_term != term) {
                    throw std::logic_error("Fig3 term alignment");
                }
                acc = int64_t(finite_acc.value());
            } else {
                acc += coefficient * int64_t(term);
            }
            out.shift_tail |= tail;
            ++out.iterations;
            sac.advance(up);
            if (trace) trace->push_back({out.iterations, before, exponent, power, up,
                coefficient, sac.mantissa, sac.exponent, acc, tail});
        }
        out.remainder = sac.mantissa != 0;
        if (acc <= 0) throw std::logic_error("nonpositive approximate mantissa");
        int sf = ua.sf + ub.sf + anchor;
        bool sticky = false;
        while (uint64_t(acc) >= 2 * acc_hidden) { sticky |= acc & 1; acc >>= 1; ++sf; }
        while (uint64_t(acc) < acc_hidden) { acc <<= 1; --sf; }
        // Per-term FLOOR is an explicit local accumulator assumption. Omitted
        // algorithmic residual is not reintroduced as final-pack sticky.
        out.unpacked = {bool(ua.sign ^ ub.sign), false, false, sf,
                        uint64_t(acc) << (63 - W - cfg.accumulator_guard), !sticky};
        out.bits = pack<NB, ES>(out.unpacked, cfg.rounding);
        return out;
    }
};
}
