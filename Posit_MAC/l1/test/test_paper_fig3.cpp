#include <algorithm>
#include <array>
#include <fstream>
#include <iostream>
#include <random>
#include <vector>

#include "paper_multiplier.hpp"

using namespace l1;
using Wide = unsigned __int128;

namespace {
uint64_t checks = 0;
uint64_t exhaustive_pairs = 0;
uint64_t carry_states = 0;
uint64_t cleared_carries = 0;
uint64_t discarded_terms = 0;
uint64_t maximum_accumulator = 0;

void check(bool condition, const char* message) {
    ++checks;
    if (!condition) {
        throw std::runtime_error(message);
    }
}

struct OracleTerm {
    int power;
    int coefficient;
};

// Independent Q96 signed residual, no PaperSac normalization recurrence.
std::vector<OracleTerm> oracle_terms(unsigned significand) {
    Wide residual = Wide(significand) << 84;
    int coefficient = 1;
    std::vector<OracleTerm> terms;
    while (residual && terms.size() < 8) {
        unsigned top = 0;
        for (Wide bits = residual; bits >>= 1;) {
            ++top;
        }
        if (top < 12) {
            throw std::runtime_error("Q96 oracle precision exhausted");
        }
        const bool round_up = residual >= (Wide(3) << (top - 1));
        terms.push_back({int(top) - 96 + int(round_up), coefficient});
        if (round_up) {
            residual = (Wide(1) << (top + 1)) - residual - (Wide(1) << (top - 12));
            coefficient = -coefficient;
        } else {
            residual -= Wide(1) << top;
        }
    }
    return terms;
}

uint64_t oracle_shift(unsigned y, unsigned shift) {
    // Integer division makes the cut location explicit and independent of >>.
    return shift >= 32 ? 0 : y / (uint64_t(1) << shift);
}

posit_unpacked<32, 3> oracle_output(uint32_t a, uint32_t b, unsigned n) {
    const auto ua = parse<32, 3>(a);
    const auto ub = parse<32, 3>(b);
    if (ua.is_nar || ub.is_nar) {
        return {true, false, true, 0, 0, true};
    }
    if (ua.is_zero || ub.is_zero) {
        return {false, true, false, 0, 0, true};
    }
    unsigned x = unsigned(ua.frac >> 51);
    unsigned y = unsigned(ub.frac >> 51);
    // OPS was independently audited in test_journal2024_pt2; width test freezes it.
    if (paper_ops_select_pattern(x - 4096, y - 4096).swapped) {
        std::swap(x, y);
    }
    const auto terms = oracle_terms(x);
    const int anchor = terms.front().power;
    int64_t sum = 0;
    for (unsigned k = 0; k < std::min<unsigned>(n, terms.size()); ++k) {
        const unsigned shift = unsigned(anchor - terms[k].power);
        sum += terms[k].coefficient * int64_t(oracle_shift(y, shift));
    }
    int sf = ua.sf + ub.sf + anchor;
    uint64_t magnitude = uint64_t(sum);
    bool sticky = false;
    while (magnitude >= 8192) {
        sticky |= magnitude % 2;
        magnitude /= 2;
        ++sf;
    }
    while (magnitude < 4096) {
        magnitude *= 2;
        --sf;
    }
    return {bool(ua.sign ^ ub.sign), false, false, sf, magnitude << 51, !sticky};
}

void test_exhaustive_core() {
    for (unsigned x = 4096; x < 8192; ++x) {
        const auto terms = oracle_terms(x);
        for (unsigned y = 4096; y < 8192; ++y) {
            PaperFig3Accumulator accumulator(12);
            PaperSac sac(x, 12);
            int64_t oracle_sum = 0;
            const int anchor = terms.front().power;
            for (unsigned k = 0; k < terms.size(); ++k) {
                const bool up = sac.mantissa >= 6144;
                const int power = sac.exponent + int(up);
                check(power == terms[k].power && sac.coefficient == terms[k].coefficient,
                      "independent SAC term");
                check(anchor >= power, "nonnegative Fig3 right shift");
                const unsigned shift = unsigned(anchor - power);
                const uint64_t expected_term = oracle_shift(y, shift);
                const bool previous_carry = accumulator.carry();
                const uint64_t actual_term = accumulator.update(y, shift, sac.coefficient);
                oracle_sum += terms[k].coefficient * int64_t(expected_term);
                check(actual_term == expected_term && oracle_sum > 0 &&
                      accumulator.value() == uint64_t(oracle_sum), "finite accumulator oracle");
                check(accumulator.payload() < 8192 &&
                      accumulator.value() < 16384, "13 payload plus carry bound");
                carry_states += accumulator.carry();
                cleared_carries += previous_carry && !accumulator.carry();
                maximum_accumulator = std::max(maximum_accumulator, accumulator.value());
                discarded_terms += shift >= 13;
                sac.advance(up);
            }
            ++exhaustive_pairs;
        }
    }
}

void test_width_and_cut() {
    for (unsigned width : {1u, 7u, 12u, 23u, 27u}) {
        const uint64_t hidden = uint64_t(1) << width;
        for (unsigned shift : {0u, 1u, width, width + 1, 63u, 64u, 127u}) {
            PaperFig3Accumulator accumulator(width);
            accumulator.update(2 * hidden - 1, 0, 1);
            const uint64_t expected = shift >= 64 ? 0 : (2 * hidden - 1) / (uint64_t(1) << shift);
            const auto actual = accumulator.update(2 * hidden - 1, shift, -1);
            check(actual == expected && accumulator.value() == 2 * hidden - 1 - expected,
                  "shift saturation and unsigned term cut");
        }
    }
    PaperFig3Accumulator accumulator(12);
    accumulator.update(6144, 0, 1);
    accumulator.update(4096, 1, 1);
    check(accumulator.carry() && accumulator.value() == 8192, "carry set");
    accumulator.update(4096, 2, -1);
    check(!accumulator.carry() && accumulator.value() == 7168, "carry clear after subtraction");

    PaperFig3Accumulator odd(12);
    odd.update(4097, 0, 1);
    odd.update(4097, 1, -1);
    check(odd.value() == 2049, "negative coefficient after floor, not arithmetic signed shift");
    bool rejected = false;
    try { odd.update(8191, 0, -1); }
    catch (const std::logic_error&) { rejected = true; }
    check(rejected, "borrow rejected instead of wrap");
}

void test_integration() {
    std::mt19937_64 generator(20261008);
    const std::array<uint32_t, 10> corners = {
        0, 1, 0x80000000, 0x7fffffff, 0xffffffff,
        0x40000000, 0xc0000000, 0x48000000, 0x47ffffff, 0x48000001
    };
    for (unsigned i = 0; i < 100100; ++i) {
        const uint32_t a = i < 100 ? corners[i / 10] : uint32_t(generator());
        const uint32_t b = i < 100 ? corners[i % 10] : uint32_t(generator());
        for (unsigned n = 1; n <= 8; ++n) {
            auto cfg = paper_fig3_config();
            cfg.n = n;
            cfg.rounding = i % 2 ? RoundMode::RNE : RoundMode::TRUNC;
            const auto actual = PaperMultiplier<>::mul(a, b, cfg);
            const auto expected = oracle_output(a, b, n);
            check(actual.bits == pack<32, 3>(expected, cfg.rounding), "Fig3 packed integration");
            check(actual.unpacked.sign == expected.sign && actual.unpacked.sf == expected.sf &&
                  actual.unpacked.frac == expected.frac && actual.unpacked.is_zero == expected.is_zero &&
                  actual.unpacked.is_nar == expected.is_nar && actual.unpacked.exact == expected.exact,
                  "Fig3 unpacked integration");
        }
    }
    auto cfg = paper_fig3_config();
    cfg.ops = PaperOps::FixedA;
    const uint32_t x = (1u << 28) | (6u << 25) | (0x480u << 13);
    const uint32_t y = (1u << 29) | (7u << 26) | (0x208u << 14);
    check(PaperMultiplier<>::mul(x, y, cfg).bits ==
          ((1u << 28) | (5u << 25) | (0x71au << 13)), "2021 Fig4 fixture");
}

void write_trace(const char* path) {
    std::ofstream csv(path);
    if (!csv) { throw std::runtime_error("trace output"); }
    csv << "case,x,y,k,power,coefficient,shift,term,acc,payload13,carry,tail\n";
    const unsigned examples[][2] = {{5248, 4616}, {6144, 4097}, {6143, 8191}, {4097, 8191}};
    for (unsigned j = 0; j < 4; ++j) {
        PaperSac sac(examples[j][0], 12);
        PaperFig3Accumulator accumulator(12);
        const int anchor = int(examples[j][0] >= 6144);
        for (unsigned k = 0; k < 8 && sac.mantissa; ++k) {
            const bool up = sac.mantissa >= 6144;
            const int power = sac.exponent + int(up);
            const unsigned shift = unsigned(anchor - power);
            const unsigned y = examples[j][1];
            const uint64_t term = accumulator.update(y, shift, sac.coefficient);
            const bool tail = shift >= 13 ? true : y % (1u << shift) != 0;
            csv << j << ',' << examples[j][0] << ',' << y << ',' << k + 1 << ','
                << power << ',' << sac.coefficient << ',' << shift << ',' << term << ','
                << accumulator.value() << ',' << accumulator.payload() << ',' << accumulator.carry()
                << ',' << tail << '\n';
            sac.advance(up);
        }
    }
    csv.close();
    if (!csv) { throw std::runtime_error("trace write failed"); }
}
} // namespace

int main(int argc, char** argv) try {
    test_width_and_cut();
    test_exhaustive_core();
    test_integration();
    if (argc > 1) { write_trace(argv[1]); }
    check(carry_states != 0 && cleared_carries != 0 && discarded_terms != 0,
          "carry/carry-clear/large-shift coverage");
    std::cout << "FIG3_WIDTH PASS checks=" << checks << " exhaustive_pairs=" << exhaustive_pairs
              << " carry_states=" << carry_states << " cleared_carries=" << cleared_carries
              << " discarded_terms=" << discarded_terms << " max_acc=" << maximum_accumulator
              << " raw_seed=20261008\n";
    return 0;
} catch (const std::exception& error) {
    std::cerr << "FIG3_WIDTH FAIL " << error.what() << '\n';
    return 1;
}
