#pragma once

#include <array>
#include <vector>

#include "paper_measurement.hpp"
#include "paper_multiplier.hpp"

namespace discriminator {
using namespace l1;
using Wide = unsigned __int128;
using SignedWide = __int128;

enum class Candidate {
    Fig3, TieB, Legacy7, InputAnchor, ExactResidual,
    Guard1Pack12, Guard12Pack12, SourceUncut, PostSumPack12, SignedFloor
};
constexpr unsigned candidate_count = 10;
constexpr const char* names[] = {
    "fig3", "tie_b", "legacy7", "input_anchor", "exact_residual",
    "guard1_pack12", "guard12_pack12", "source_uncut", "post_sum_pack12", "signed_floor"
};

struct Evaluation {
    PaperResult<32, 3> result;
    std::vector<PaperStep> steps;
    std::vector<SignedWide> extended_accumulators;
    unsigned accumulator_fraction = 12;
    unsigned index_a = 0, index_b = 0, score_a = 0, score_b = 0;
    bool tie = false;
    int anchor = 0;
    unsigned selected_y = 0;
};

inline PaperConfig config(Candidate candidate, unsigned n) {
    auto cfg = paper_fig3_config();
    cfg.n = n;
    if (candidate == Candidate::Legacy7) { cfg.ops = PaperOps::PredictN2; }
    if (candidate == Candidate::InputAnchor) { cfg.anchor_first = false; }
    if (candidate == Candidate::ExactResidual) { cfg.complement = false; }
    if (candidate == Candidate::Guard1Pack12) { cfg.accumulator_guard = 1; }
    if (candidate == Candidate::Guard12Pack12 || candidate == Candidate::SourceUncut) {
        cfg.accumulator_guard = 12;
    }
    return cfg;
}

inline posit_unpacked<32, 3> normalized(uint64_t magnitude, int sf, unsigned guard) {
    const uint64_t hidden = uint64_t(4096) << guard;
    if (!magnitude) { throw std::runtime_error("zero study accumulator"); }
    bool sticky = false;
    while (magnitude >= 2 * hidden) {
        sticky |= magnitude & 1;
        magnitude >>= 1;
        ++sf;
    }
    while (magnitude < hidden) {
        magnitude <<= 1;
        --sf;
    }
    return {false, false, false, sf, magnitude << (51 - guard), !sticky};
}

inline void cut_output12(PaperResult<32, 3>& result) {
    const uint64_t mask = (uint64_t(1) << 51) - 1;
    result.unpacked.exact &= (result.unpacked.frac & mask) == 0;
    result.unpacked.frac &= ~mask;
    result.bits = pack<32, 3>(result.unpacked, RoundMode::TRUNC);
}

inline Evaluation evaluate(uint32_t a, uint32_t b, unsigned n, Candidate candidate,
                           bool force_a = false, bool capture = true) {
    auto cfg = config(candidate, n);
    Evaluation out;
    const auto ua = parse<32, 3>(a);
    const auto ub = parse<32, 3>(b);
    if (ua.is_zero || ub.is_zero || ua.is_nar || ub.is_nar) {
        out.result = PaperMultiplier<>::mul(a, b, cfg);
        return out;
    }
    unsigned x = unsigned(ua.frac >> 51), y = unsigned(ub.frac >> 51);
    auto selection = candidate == Candidate::Legacy7
        ? paper_ops_select(x - 4096, y - 4096)
        : paper_ops_select_pattern(x - 4096, y - 4096);
    out.index_a = selection.index_a;
    out.index_b = selection.index_b;
    out.score_a = selection.error_a * (candidate == Candidate::Legacy7 ? 32 : 1);
    out.score_b = selection.error_b * (candidate == Candidate::Legacy7 ? 32 : 1);
    out.tie = selection.tie;
    const bool swapped = !force_a && (selection.swapped ||
        (candidate == Candidate::TieB && selection.tie));
    if (swapped) { std::swap(x, y); }
    out.selected_y = y;
    out.anchor = cfg.anchor_first ? int(x >= 6144) : 0;
    out.accumulator_fraction = 12 + cfg.accumulator_guard;

    // Freeze selection explicitly so tie-B does not alter the recurrence/API.
    cfg.ops = PaperOps::FixedA;
    const bool special_accumulator = candidate == Candidate::PostSumPack12 ||
                                     candidate == Candidate::SignedFloor;
    out.result = PaperMultiplier<>::mul(swapped ? b : a, swapped ? a : b, cfg,
        capture || special_accumulator ? &out.steps : nullptr);
    out.result.swapped = swapped;

    if (special_accumulator) {
        SignedWide sum = 0;
        int64_t signed_floor_sum = 0;
        for (auto& step : out.steps) {
            const unsigned shift = unsigned(out.anchor - step.power);
            if (shift > 96) { throw std::runtime_error("study Q96 precision exhausted"); }
            sum += step.coefficient * SignedWide(Wide(y) << (96 - shift));
            const unsigned integer_term = shift >= 32 ? 0 : y / (1u << shift);
            const bool tail = shift >= 32 || y % (1u << shift) != 0;
            signed_floor_sum += step.coefficient * int64_t(integer_term);
            if (step.coefficient < 0 && tail) { --signed_floor_sum; }
            if (candidate == Candidate::PostSumPack12) {
                step.accumulator = int64_t(sum >> 96);
                out.extended_accumulators.push_back(sum);
            } else {
                step.accumulator = signed_floor_sum;
            }
        }
        const uint64_t accumulator = candidate == Candidate::PostSumPack12
            ? uint64_t(sum >> 96) : uint64_t(signed_floor_sum);
        out.result.unpacked = normalized(accumulator, ua.sf + ub.sf + out.anchor, 0);
        out.result.unpacked.sign = ua.sign ^ ub.sign;
        out.result.bits = pack<32, 3>(out.result.unpacked, RoundMode::TRUNC);
    }
    if (candidate != Candidate::SourceUncut) { cut_output12(out.result); }
    if (!capture) { out.steps.clear(); out.extended_accumulators.clear(); }
    return out;
}

// Independent signed residual on a Q96 grid; never calls PaperSac.
inline std::vector<std::pair<int, int>> reference_terms(unsigned x, unsigned n, bool complement) {
    Wide residual = Wide(x) << 84;
    int coefficient = 1;
    std::vector<std::pair<int, int>> terms;
    while (residual && terms.size() < n) {
        unsigned top = 0;
        for (Wide value = residual; value >>= 1;) { ++top; }
        if (top < 12) { throw std::runtime_error("reference Q96 exhausted"); }
        const bool up = residual >= (Wide(3) << (top - 1));
        terms.emplace_back(int(top) - 96 + int(up), coefficient);
        if (up) {
            residual = (Wide(1) << (top + 1)) - residual -
                (complement ? Wide(1) << (top - 12) : 0);
            coefficient = -coefficient;
        } else {
            residual -= Wide(1) << top;
        }
    }
    return terms;
}

inline bool verify_trace(uint32_t a, uint32_t b, unsigned n, Candidate candidate,
                         const Evaluation& actual) {
    const auto ua = parse<32, 3>(a), ub = parse<32, 3>(b);
    if (ua.is_zero || ub.is_zero || ua.is_nar || ub.is_nar) {
        const uint32_t expected = ua.is_nar || ub.is_nar ? 0x80000000 : 0;
        return actual.result.bits == expected;
    }
    unsigned x = unsigned(ua.frac >> 51), y = unsigned(ub.frac >> 51);
    if (actual.result.swapped) { std::swap(x, y); }
    const auto cfg = config(candidate, n);
    const auto terms = reference_terms(x, n, cfg.complement);
    if (terms.size() != actual.steps.size()) { return false; }
    int64_t integer_sum = 0;
    SignedWide exact_sum = 0;
    for (unsigned k = 0; k < terms.size(); ++k) {
        const int power = terms[k].first;
        const int coefficient = terms[k].second;
        const int aligned = power - actual.anchor + int(cfg.accumulator_guard);
        const uint64_t term = aligned >= 0 ? uint64_t(y) * (uint64_t(1) << aligned)
            : aligned <= -64 ? 0 : uint64_t(y) / (uint64_t(1) << -aligned);
        const bool tail = aligned < 0 &&
            (aligned <= -64 || uint64_t(y) % (uint64_t(1) << -aligned) != 0);
        integer_sum += coefficient * int64_t(term);
        if (candidate == Candidate::SignedFloor && coefficient < 0 && tail) { --integer_sum; }
        const int exact_alignment = power - actual.anchor + 96;
        if (exact_alignment < 0) { throw std::runtime_error("exact reference precision"); }
        exact_sum += coefficient * SignedWide(Wide(y) << exact_alignment);
        const int64_t expected_accumulator = candidate == Candidate::PostSumPack12
            ? int64_t(exact_sum / (SignedWide(1) << 96)) : integer_sum;
        const auto& step = actual.steps[k];
        if (step.power != power || step.coefficient != coefficient ||
            step.accumulator != expected_accumulator) { return false; }
    }
    const uint64_t last = uint64_t(candidate == Candidate::PostSumPack12
        ? exact_sum / (SignedWide(1) << 96) : integer_sum);
    auto reference = normalized(last, ua.sf + ub.sf + actual.anchor, cfg.accumulator_guard);
    reference.sign = ua.sign ^ ub.sign;
    if (candidate != Candidate::SourceUncut) {
        reference.frac = (reference.frac / (uint64_t(1) << 51)) * (uint64_t(1) << 51);
    }
    return actual.result.bits == pack<32, 3>(reference, RoundMode::TRUNC);
}
} // namespace discriminator
