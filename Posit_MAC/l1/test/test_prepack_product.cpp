#include <array>
#include <cstdint>
#include <iostream>
#include <random>
#include <string>
#include "floor_rne_profile.hpp"
#include "../../tb/week9_exact_reference.hpp"

uint64_t checks = 0, trace_checks = 0, exact_checks = 0;
bool saw_input_cut = false, saw_term_cut = false, saw_iteration_cut = false;

void require(bool condition, const char* message) {
    if (!condition) {
        throw std::runtime_error(message);
    }
}

// Independent bit-stream decoder; no L1 parser, SAC, OPS or SBM calls.
struct Decoded {
    uint64_t fraction;
    int scale;
    bool sign, cut;
};
template<int NB, int ES>
Decoded decode(uint32_t raw, unsigned width) {
    const uint64_t mask = (uint64_t(1) << NB) - 1;
    const bool sign = (raw >> (NB - 1)) != 0;
    const uint64_t magnitude = sign ? (-uint64_t(raw) & mask) : raw;
    int bit = NB - 2;
    const bool polarity = (magnitude >> bit) & 1;
    int run = 0;
    while (bit >= 0 && bool((magnitude >> bit) & 1) == polarity) {
        ++run;
        --bit;
    }
    if (bit >= 0) {
        --bit;
    }
    int exponent = 0;
    for (int i = 0; i < ES; ++i) {
        exponent <<= 1;
        if (bit >= 0) {
            exponent |= (magnitude >> bit--) & 1;
        }
    }
    uint64_t fraction = 0;
    bool cut = false;
    unsigned position = 0;
    for (; bit >= 0; --bit, ++position) {
        const bool value = (magnitude >> bit) & 1;
        if (position < width) {
            fraction |= uint64_t(value) << (width - 1 - position);
        } else {
            cut |= value;
        }
    }
    return {fraction, (polarity ? run - 1 : -run) * (1 << ES) + exponent,
            sign, cut};
}
unsigned population(uint64_t value) {
    unsigned count = 0;
    for (; value; value >>= 1) {
        count += value & 1;
    }
    return count;
}

template<int NB, int ES, unsigned FW>
void check(uint32_t a, uint32_t b, l1::IterConfig config, bool trace_enabled) {
    using Model = l1::L1MultiplierIter<NB, ES, FW>;
    constexpr uint32_t nar = uint32_t(1) << (NB - 1);
    const unsigned width = config.exact ? NB - 3 - ES : FW;
    const unsigned q = config.exact ? 2 * width :
        width + (config.scheme == l1::ShiftRound::STICKY_ACC ? 2 : 0);
    std::vector<l1::IterStep> trace;
    const auto result = Model::mul(a, b, config, trace_enabled ? &trace : nullptr);
    const auto& product = result.prepack;
    ++checks;
    require(product.fractional_bits == q && product.magnitude_bits == q + 2,
            "prepack width/grid mismatch");
    if (a == nar || b == nar || !a || !b) {
        require(product.is_nar == (a == nar || b == nar), "NaR priority");
        require(product.is_zero == (!(a == nar || b == nar) && (!a || !b)), "zero classification");
        require(product.magnitude == 0 && product.scale == 0 && !product.sign &&
                !product.numerical_sticky && trace.empty(), "special canonical metadata");
        return;
    }
    auto x = decode<NB, ES>(a, width);
    auto y = decode<NB, ES>(b, width);
    const bool swapped = config.ops == 1 && population(y.fraction) < population(x.fraction);
    const bool input_cut = !config.exact && (x.cut || y.cut);
    if (swapped) {
        std::swap(x, y);
    }
    const uint64_t y_grid = ((uint64_t(1) << width) | y.fraction) << (q - width);
    uint64_t sum = y_grid;
    unsigned terms = 0;
    bool lost = false;
    uint64_t remaining = x.fraction;
    unsigned previous_scale = 0;
    const unsigned limit = config.exact ? width : config.n;
    for (unsigned scale = 1; scale <= width && terms < limit; ++scale) {
        if (!(x.fraction & (uint64_t(1) << (width - scale)))) {
            continue;
        }
        lost |= (y_grid & ((uint64_t(1) << scale) - 1)) != 0;
        sum += y_grid >> scale;
        remaining = (x.fraction << scale) & ((uint64_t(1) << width) - 1);
        if (trace_enabled) {
            require(terms < trace.size(), "missing trace term");
            const auto& step = trace[terms];
            const bool sticky = (config.exact || config.scheme == l1::ShiftRound::STICKY_ACC) && lost;
            require(step.sa == scale - previous_scale && step.scale == scale &&
                    step.fx == remaining && step.acc == sum && step.sticky == sticky,
                    "independent per-term trace mismatch");
            ++trace_checks;
        }
        previous_scale = scale;
        ++terms;
    }
    require(!trace_enabled || trace.size() == terms, "extra trace term");
    const bool numeric_tail = (config.exact || config.scheme == l1::ShiftRound::STICKY_ACC) && lost;
    require(product.magnitude == sum && product.scale == x.scale + y.scale &&
            product.sign == (x.sign != y.sign) && !product.is_zero && !product.is_nar &&
            product.numerical_sticky == numeric_tail && product.input_cut == input_cut &&
            product.iteration_cut == (remaining != 0) && product.term_cut == (!config.exact && lost),
            "independent prepack record mismatch");
    require(result.iterations == terms && result.swapped == swapped &&
            result.remaining_fx == remaining && sum < (uint64_t(1) << (q + 2)),
            "iteration/overflow mismatch");
    if (!config.exact && config.scheme == l1::ShiftRound::FLOOR) {
        require(!product.numerical_sticky, "algorithmic FLOOR loss became rounding sticky");
    }
    if (config.exact && config.rounding == l1::RoundMode::RNE) {
        require(result.bits == exact_reference<NB, ES>(a, b), "independent exact RNE mismatch");
        ++exact_checks;
    }
    saw_input_cut |= product.input_cut;
    saw_term_cut |= product.term_cut;
    saw_iteration_cut |= product.iteration_cut;
}

template<int NB, int ES, unsigned FW>
void sampled(uint64_t count) {
    std::mt19937_64 rng(20261011 + NB + ES);
    const uint32_t mask = uint32_t((uint64_t(1) << NB) - 1);
    const uint32_t nar = uint32_t(1) << (NB - 1);
    const std::array<uint32_t, 10> corner = {0, 1, 2, nar-1, nar, nar+1, mask,
                                          nar/2, nar/2+1, nar+nar/2};
    for (auto a : corner) {
        for (auto b : corner) {
            for (unsigned n = 0; n <= 8; ++n) {
                for (unsigned ops = 0; ops <= 1; ++ops) {
                    auto config = l1::floor_rne_profile(n);
                    config.ops = ops;
                    check<NB, ES, FW>(a, b, config, true);
                }
            }
        }
    }
    for (uint64_t i = 0; i < count; ++i) {
        auto config = l1::floor_rne_profile(i % 9);
        config.ops = (i / 9) % 2;
        config.exact = (i / 18) % 2;
        config.scheme = (i / 36) % 2 ? l1::ShiftRound::STICKY_ACC : l1::ShiftRound::FLOOR;
        config.rounding = (i / 72) % 2 ? l1::RoundMode::TRUNC : l1::RoundMode::RNE;
        const uint32_t a = uint32_t(rng()) & mask;
        const uint32_t b = uint32_t(rng()) & mask;
        check<NB, ES, FW>(a, b, config, true);
    }
}

int main(int argc, char** argv) try {
    const bool smoke = argc == 2 && std::string(argv[1]) == "--smoke";
    require(argc == 1 || smoke, "usage: test_prepack_product [--smoke]");
    sampled<8, 0, 5>(smoke ? 10000 : 100000);
    sampled<16, 1, 12>(smoke ? 10000 : 100000);
    sampled<32, 2, 12>(smoke ? 10000 : 100000);
    sampled<32, 3, 12>(smoke ? 10000 : 100000);
    const auto profile = l1::floor_rne_profile(2);
    const unsigned bound = smoke ? 64 : 4096;
    for (unsigned a = 0; a < bound; ++a) {
        for (unsigned b = 0; b < bound; ++b) {
            check<32, 3, 12>(0x40000000u | (a << 14),
                            0x40000000u | (b << 14), profile, false);
        }
    }
    bool rejected = false;
    try { l1::floor_rne_profile(9); }
    catch (const std::invalid_argument&) { rejected = true; }
    require(rejected && saw_input_cut && saw_term_cut && saw_iteration_cut,
            "profile rejection/loss coverage missing");
    std::cout << "PREPACK PASS checks=" << checks << " trace_checks=" << trace_checks
              << " exact_checks=" << exact_checks << " Q12_pairs=" << uint64_t(bound)*bound
              << " seed=20261011 mismatches=0\n";
} catch (const std::exception& error) {
    std::cerr << "PREPACK FAIL: " << error.what() << '\n';
    return 1;
}
