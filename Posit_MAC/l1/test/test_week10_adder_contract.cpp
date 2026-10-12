#include <cstdint>
#include <iostream>
#include <random>
#include <stdexcept>
#include "posit_adder.hpp"

namespace {
uint64_t checks = 0;
uint64_t metadata_checks = 0;
uint64_t clamped_cases = 0;
uint64_t subtract_tail_cases = 0;
uint64_t cancellation_cases = 0;
uint64_t carry_cases = 0;

void require(bool condition, const char* message) {
    if (!condition) {
        throw std::runtime_error(message);
    }
}

template<int NB, int ES>
void check(uint32_t a, uint32_t b) {
    constexpr unsigned F = l1::posit_constants<NB, ES>::FRAC_MAX;
    constexpr unsigned Q = F + 3;
    constexpr unsigned F_OUT = 2 * F + 1;
    constexpr uint64_t H = uint64_t(1) << 63;
    constexpr uint64_t FRACTION_MASK = H - 1;
    constexpr uint64_t LOW_MASK = (uint64_t(1) << (63 - F_OUT)) - 1;
    l1::AdderTrace trace;
    const auto sum = l1::l1_add_unpacked<NB, ES>(
        l1::parse<NB, ES>(typename l1::PositAdder<NB, ES>::T(a)),
        l1::parse<NB, ES>(typename l1::PositAdder<NB, ES>::T(b)),
        &trace);
    ++checks;
    clamped_cases += trace.clamped;
    subtract_tail_cases += trace.subtract && trace.alignment_tail;
    cancellation_cases += trace.cancellation_zero;
    carry_cases += trace.carry;

    // Project L1 onto the proposed RTL ports, then reconstruct a packer input.
    // This tests interface precision; it is not an independent arithmetic oracle.
    const uint64_t fraction = (sum.frac & FRACTION_MASK) >> (63 - F_OUT);
    const bool special = sum.is_zero || sum.is_nar;
    require((sum.frac & LOW_MASK) == 0, "interface loses significant fraction");
    if (!special) {
        const uint64_t magnitude = sum.frac >> (63 - Q);
        require((sum.frac >> 63) == 1, "hidden bit not normalized");
        require((fraction & ((uint64_t(1) << (F - 2)) - 1)) == 0,
                "adapter padding is not zero");
        require(fraction == ((magnitude & ((uint64_t(1) << Q) - 1)) << (F - 2)),
                "adapter equation mismatch");
    }
    for (unsigned incoming = 0; incoming < 32; ++incoming) {
        const bool nar = sum.is_nar || (incoming & 16);
        const bool zero = !nar && sum.is_zero;
        const bool sign = nar || (!zero && sum.sign);
        const int sf = special || nar ? 0 : sum.sf;
        const uint64_t frac = special || nar ? 0 : fraction;
        const bool sticky = !special && !nar && !sum.exact;
        const unsigned flags = nar ? 16 : ((incoming & 15) | (sticky ? 2 : 0));
        require(!nar || (flags == 16 && !zero && sign && !frac && !sticky && !sf),
                "NaR canonicalization");
        require(!zero || (!sign && !frac && !sticky && !sf), "Zero canonicalization");
        require(nar || (flags & 1) == (incoming & 1), "approx_cut changed in adder");
        l1::posit_unpacked<NB, ES> restored{};
        restored.sign = sign;
        restored.is_nar = nar;
        restored.is_zero = zero;
        restored.sf = sf;
        restored.frac = nar || zero ? 0 : H | (frac << (63 - F_OUT));
        restored.exact = !sticky;
        for (auto mode : {l1::RoundMode::RNE, l1::RoundMode::TRUNC}) {
            const auto expected = nar ? typename l1::PositAdder<NB, ES>::T(uint64_t(1) << (NB - 1))
                                      : l1::pack<NB, ES>(sum, mode);
            require(l1::pack<NB, ES>(restored, mode) == expected, "packed projection differs");
            ++metadata_checks;
        }
    }
}

template<int NB, int ES>
void run(std::mt19937_64& rng) {
    constexpr uint32_t MASK = uint32_t((uint64_t(1) << NB) - 1);
    constexpr uint32_t NAR = uint32_t(uint64_t(1) << (NB - 1));
    if constexpr (NB == 8) {
        for (unsigned a = 0; a < 256; ++a) {
            for (unsigned b = 0; b < 256; ++b) {
                check<NB, ES>(a, b);
            }
        }
    } else {
        const uint32_t corners[] = {0, 1, 2, NAR - 2, NAR - 1, NAR,
                                    NAR + 1, MASK, NAR / 2, (0u - NAR / 2) & MASK};
        for (uint32_t a : corners) {
            for (uint32_t b : corners) {
                check<NB, ES>(a, b);
            }
        }
        for (unsigned i = 0; i < 100000; ++i) {
            check<NB, ES>(uint32_t(rng()) & MASK, uint32_t(rng()) & MASK);
        }
    }
}
}

int main() try {
    std::mt19937_64 rng(20261012);
    run<8, 0>(rng);
    run<16, 1>(rng);
    run<32, 2>(rng);
    run<32, 3>(rng);
    require(clamped_cases && subtract_tail_cases && cancellation_cases && carry_cases,
            "required arithmetic branches were not exercised");
    std::cout << "W10_CONTRACT_PROJECTION PASS checks=" << checks
              << " metadata_mode_checks=" << metadata_checks
              << " clamped=" << clamped_cases
              << " subtract_tail=" << subtract_tail_cases
              << " cancellation=" << cancellation_cases
              << " carry=" << carry_cases
              << " seed=20261012 mismatches=0; no RTL simulated\n";
    return 0;
} catch (const std::exception& error) {
    std::cerr << "FAIL: " << error.what() << '\n';
    return 1;
}
