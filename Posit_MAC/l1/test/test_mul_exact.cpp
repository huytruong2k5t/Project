#include <iostream>
#include <iomanip>
#include <cstdint>
#include <random>
#include <chrono>
#include <array>
#include <algorithm>
#include <string>
#include <stdexcept>
#include "../include/posit_types.hpp"
#include "../include/l1_multiplier_exact.hpp"
#include "../../l0/softposit_api.h"

using namespace l1;

// 1. Exhaustive Posit8 Multiplier Test (2^16 = 65,536 pairs)
bool test_p8_exhaustive() {
    std::cout << "\n[TEST 1] Posit8 (ES=0) Exhaustive Multiplication: 65,536 pairs..." << std::endl;
    uint64_t pass = 0, fail = 0;

    for (uint32_t a = 0; a < 256; ++a) {
        for (uint32_t b = 0; b < 256; ++b) {
            uint8_t act = l1_mul<8, 0>(static_cast<uint8_t>(a), static_cast<uint8_t>(b), RoundMode::RNE);
            uint8_t exp = l0_p8_mul(static_cast<uint8_t>(a), static_cast<uint8_t>(b));

            if (act == exp) {
                pass++;
            } else {
                fail++;
                if (fail <= 10) {
                    std::cout << "  Mismatch at 0x" << std::hex << a << " * 0x" << b
                              << " -> L1=0x" << static_cast<uint32_t>(act)
                              << ", L0=0x" << static_cast<uint32_t>(exp) << std::dec << std::endl;
                }
            }
        }
    }

    if (fail == 0) {
        std::cout << "  [PASS] Posit8 Exact Mul: " << pass << "/65536 (100% Bit-Exact with SoftPosit)" << std::endl;
        return true;
    } else {
        std::cout << "  [FAIL] Posit8 Exact Mul: " << fail << " mismatches out of 65536" << std::endl;
        return false;
    }
}

// 2. Corner List Verification for Posit32 (§6.4)
bool test_p32_corners() {
    std::cout << "\n[TEST 2] Posit32 (ES=2) Mandatory Corner List (§6.4)..." << std::endl;

    uint32_t P32_ZERO   = 0x00000000;
    uint32_t P32_NAR    = 0x80000000;
    uint32_t P32_ONE    = 0x40000000;
    uint32_t P32_NEG1   = 0xC0000000;
    uint32_t P32_MINPOS = 0x00000001;
    uint32_t P32_NEGMIN = 0xFFFFFFFF;
    uint32_t P32_MAXPOS = 0x7FFFFFFF;
    uint32_t P32_NEGMAX = 0x80000001;

    struct CornerPair {
        const char* name;
        uint32_t a;
        uint32_t b;
    };

    CornerPair pairs[] = {
        {"NaR * 0", P32_NAR, P32_ZERO},
        {"0 * NaR", P32_ZERO, P32_NAR},
        {"maxpos * maxpos", P32_MAXPOS, P32_MAXPOS},
        {"minpos * minpos", P32_MINPOS, P32_MINPOS},
        {"(-maxpos) * (-maxpos)", P32_NEGMAX, P32_NEGMAX},
        {"maxpos * minpos", P32_MAXPOS, P32_MINPOS},
        {"+1 * -1", P32_ONE, P32_NEG1},
        {"-1 * -1", P32_NEG1, P32_NEG1},
        {"NaR * maxpos", P32_NAR, P32_MAXPOS},
        {"0 * minpos", P32_ZERO, P32_MINPOS},
        {"maxpos * 0", P32_MAXPOS, P32_ZERO},
        {"minpos * maxpos", P32_MINPOS, P32_MAXPOS},
        {"minpos * (-minpos)", P32_MINPOS, P32_NEGMIN}
    };

    uint64_t pass = 0, fail = 0;
    for (const auto& cp : pairs) {
        uint32_t act = l1_mul<32, 2>(cp.a, cp.b, RoundMode::RNE);
        uint32_t exp = l0_p32_mul(cp.a, cp.b);

        if (act == exp) {
            pass++;
            std::cout << "  [PASS] " << cp.name << " : 0x" << std::hex << act << " == 0x" << exp << std::dec << std::endl;
        } else {
            fail++;
            std::cout << "  [FAIL] " << cp.name << " : 0x" << std::hex << act << " != 0x" << exp << " (L0)" << std::dec << std::endl;
        }
    }

    return (fail == 0);
}

// 3. Posit16 random smoke sampling (not exhaustive acceptance).
bool test_p16_sampled(uint64_t num_pairs = 1000000) {
    std::cout << "\n[TEST 3] Posit16 (ES=1) Sampled Multiplication: " << num_pairs << " pairs..." << std::endl;
    std::mt19937_64 rng(2026);
    uint64_t pass = 0, fail = 0;

    for (uint64_t i = 0; i < num_pairs; ++i) {
        uint16_t a = static_cast<uint16_t>(rng());
        uint16_t b = static_cast<uint16_t>(rng());

        uint16_t act = l1_mul<16, 1>(a, b, RoundMode::RNE);
        uint16_t exp = l0_p16_mul(a, b);

        if (act == exp) {
            pass++;
        } else {
            fail++;
            if (fail <= 10) {
                std::cout << "  Mismatch at 0x" << std::hex << a << " * 0x" << b
                          << " -> L1=0x" << act << ", L0=0x" << exp << std::dec << std::endl;
            }
        }
    }

    if (fail == 0) {
        std::cout << "  [PASS] Posit16 Sampled Mul: " << pass << "/" << num_pairs << " (100% Bit-Exact with SoftPosit)" << std::endl;
        return true;
    } else {
        std::cout << "  [FAIL] Posit16 Sampled Mul: " << fail << " mismatches out of " << num_pairs << std::endl;
        return false;
    }
}

// 4. Posit32 Stratified & Random Multiplication (§6.3)
// Regime measured independently from the L1 parser, on positive magnitude.
int regime_length(uint32_t p) {
    uint32_t mag = (p >> 31) ? (0u - p) : p;
    bool first = ((mag >> 30) & 1u) != 0;
    int m = 0;
    for (int b = 30; b >= 0 && bool((mag >> b) & 1u) == first; --b) ++m;
    return m;
}

constexpr int group_low[8] = {1, 4, 8, 12, 16, 18, 23, 28};
constexpr int group_high[8] = {3, 7, 11, 15, 17, 22, 27, 31};
int regime_group(int m) {
    for (int g = 0; g < 8; ++g) if (m <= group_high[g]) return g;
    throw std::runtime_error("Invalid regime length");
}

uint32_t generate_p32(std::mt19937_64& rng, int group, bool negative, uint64_t serial) {
    // Alternate regime polarity and cycle every legal length in each group.
    bool rc = (serial & 1u) != 0;
    int hi = std::min(group_high[group], rc ? 31 : 30);
    int m = group_low[group] + int((serial / 2) % uint64_t(hi - group_low[group] + 1));
    uint32_t mag = 0;
    for (int b = 30; b > 30 - m; --b) if (rc) mag |= uint32_t(1) << b;
    int remaining = 31 - m;
    if (remaining > 0) {
        if (!rc) mag |= uint32_t(1) << (remaining - 1); // terminator
        --remaining;
    }
    int exp_bits = std::min(2, remaining);
    int frac_bits = remaining - exp_bits;
    uint32_t frac_mask = frac_bits ? ((uint32_t(1) << frac_bits) - 1u) : 0u;
    uint32_t fraction = uint32_t(rng()) & frac_mask;
    switch ((serial / 8) % 10) {
        case 0: fraction = 0; break;
        case 1: fraction = frac_mask; break;
        case 2: fraction = 0xaaaaaaaau & frac_mask; break;
        case 3: fraction = 0x55555555u & frac_mask; break;
        case 4: fraction = frac_bits ? uint32_t(1) << (rng() % frac_bits) : 0; break;
        case 5: fraction = frac_bits ? ((uint32_t(1) << (rng() % frac_bits)) |
                                       (uint32_t(1) << (rng() % frac_bits))) : 0; break;
        case 6:
        case 7: {
            int target = std::min(frac_bits, int((serial / 8) % 10) == 6 ?
                                  3 + int(rng() % 2) : 5 + int(rng() % 4));
            fraction = 0;
            for (int set = 0; set < target;) {
                uint32_t bit = uint32_t(1) << (rng() % frac_bits);
                if (!(fraction & bit)) { fraction |= bit; ++set; }
            }
            break;
        }
        default: break;
    }
    uint32_t exp_mask = exp_bits ? ((uint32_t(1) << exp_bits) - 1u) : 0u;
    mag |= ((uint32_t(rng()) & exp_mask) << frac_bits) | fraction;
    uint32_t p = negative ? 0u - mag : mag;
    if (mag == 0 || mag == 0x80000000u || regime_group(regime_length(p)) != group ||
        bool(p >> 31) != negative)
        throw std::runtime_error("Generator violated regime/sign contract");
    return p;
}

bool test_p32_sampled(uint64_t num_pairs = 1000000, uint64_t seed = 314159, bool acceptance = false) {
    std::cout << "\n[TEST 4] Posit32 STRATIFIED: " << num_pairs << " pairs; seed=" << seed << std::endl;
    std::mt19937_64 rng(seed);
    uint64_t pass = 0, fail = 0;
    std::array<uint64_t, 256> cells{};
    uint64_t lengths[2][32]{};
    uint64_t density[6]{}, polarity_pairs[4]{}, identity_failures = 0;

    auto start_time = std::chrono::high_resolution_clock::now();

    for (uint64_t i = 0; i < num_pairs; ++i) {
        int cell = int(i % 256);
        int ga = cell / 32, gb = (cell / 4) % 8, signs = cell % 4;
        uint64_t serial = i / 256;
        uint32_t a = generate_p32(rng, ga, (signs & 2) != 0, serial);
        uint32_t b = generate_p32(rng, gb, (signs & 1) != 0, serial + (serial / 64) % 4);
        ++cells[cell];
        ++polarity_pairs[(((a >> 31) ? 0u-a : a) >> 30 & 1u)*2 +
                         (((b >> 31) ? 0u-b : b) >> 30 & 1u)];
        for (uint32_t p : {a, b}) {
            uint32_t mag = (p >> 31) ? 0u - p : p;
            int m = regime_length(p);
            ++lengths[(mag >> 30) & 1u][m];
            int frac_bits = std::max(0, 30-m-2);
            uint32_t fraction = mag & (frac_bits ? ((uint32_t(1) << frac_bits)-1) : 0u);
            int pop = 0;
            while (fraction) { fraction &= fraction-1; ++pop; }
            ++density[pop <= 2 ? pop : pop <= 4 ? 3 : pop <= 8 ? 4 : 5];
            if (pack<32,2>(parse<32,2>(p), RoundMode::RNE) != p) ++identity_failures;
        }

        uint32_t act = l1_mul<32, 2>(a, b, RoundMode::RNE);
        uint32_t exp = l0_p32_mul(a, b);

        if (act == exp) {
            pass++;
        } else {
            fail++;
            if (fail <= 10) {
                std::cout << "  Mismatch at 0x" << std::hex << a << " * 0x" << b
                          << " -> L1=0x" << act << ", L0=0x" << exp << std::dec << std::endl;
            }
        }
    }

    auto end_time = std::chrono::high_resolution_clock::now();
    double elapsed_sec = std::chrono::duration<double>(end_time - start_time).count();

    uint64_t min_cell = *std::min_element(cells.begin(), cells.end());
    std::cout << "COVERAGE cells=256 min_cell=" << min_cell << std::endl;
    for (int ga = 0; ga < 8; ++ga) {
        std::cout << "CELL_COUNTS G" << ga + 1;
        for (int gb = 0; gb < 8; ++gb) {
            std::cout << " [";
            for (int s = 0; s < 4; ++s) std::cout << (s ? "," : "") << cells[ga*32+gb*4+s];
            std::cout << "]";
        }
        std::cout << std::endl;
    }
    bool coverage_ok = !acceptance || (num_pairs >= 10000000 && min_cell >= 4000);
    for (int d = 0; d < 6; ++d) {
        std::cout << "FRACTION_DENSITY bucket=" << d << " operands=" << density[d] << std::endl;
        if (acceptance && !density[d]) coverage_ok = false;
    }
    for (int p = 0; p < 4; ++p) {
        std::cout << "REGIME_POLARITY_PAIR pair=" << p << " vectors=" << polarity_pairs[p] << std::endl;
        if (acceptance && !polarity_pairs[p]) coverage_ok = false;
    }
    std::cout << "STRATIFIED_IDENTITY operands=" << num_pairs*2 << " failures=" << identity_failures << std::endl;
    for (int rc = 0; rc < 2; ++rc) {
        for (int m = 1; m <= (rc ? 31 : 30); ++m) {
            std::cout << "REGIME rc=" << rc << " m=" << m << " operands=" << lengths[rc][m] << std::endl;
            if (acceptance && lengths[rc][m] < 10000) coverage_ok = false;
        }
    }
    std::cout << "NOTE: rc=0,m=31 is zero, not a finite nonzero posit; checked separately by corner suite.\n";
    if (fail == 0 && identity_failures == 0 && coverage_ok) {
        std::cout << "  [PASS] Posit32 Sampled Mul: " << pass << "/" << num_pairs
                  << " (100% Bit-Exact with SoftPosit in " << std::fixed << std::setprecision(2) << elapsed_sec << "s)" << std::endl;
        return true;
    } else {
        std::cout << "  [FAIL] Posit32: mismatches=" << fail << " coverage_ok=" << coverage_ok << std::endl;
        return false;
    }
}

bool test_p16_range(uint32_t start_a, uint32_t end_a) {
    std::cout << "P16_EXHAUSTIVE range_A=[" << start_a << "," << end_a
              << ") B=[0,65536) pairs=" << uint64_t(end_a-start_a)*65536 << std::endl;
    uint64_t failures = 0;
    auto began = std::chrono::steady_clock::now();
    for (uint32_t a = start_a; a < end_a; ++a) {
        for (uint32_t b = 0; b < 65536; ++b) {
            uint16_t actual = l1_mul<16,1>(uint16_t(a),uint16_t(b));
            uint16_t expected = l0_p16_mul(uint16_t(a),uint16_t(b));
            if (actual != expected) {
                if (++failures <= 20) std::cout << "P16_FAIL a=" << a << " b=" << b
                    << " actual=" << actual << " expected=" << expected << std::endl;
            }
        }
        if (((a+1) % 256) == 0 || a+1 == end_a) {
            std::cout << "CHECKPOINT next_A=" << a+1 << " tested_pairs="
                << uint64_t(a+1-start_a)*65536 << " failures=" << failures << " seconds="
                << std::chrono::duration<double>(std::chrono::steady_clock::now()-began).count() << std::endl;
            if (failures) return false;
        }
    }
    std::cout << "P16_RANGE PASSED start_A=" << start_a << " end_A=" << end_a << std::endl;
    return failures == 0;
}

int main(int argc, char** argv) {
    bool gate1 = false, p32_only = false, range = false;
    uint64_t samples = 1000000, seed = 314159;
    uint32_t start_a = 0, end_a = 65536;
    try {
        for (int i = 1; i < argc; ++i) {
            std::string arg = argv[i];
            if (arg == "--gate1") { gate1 = true; samples = 10000000; }
            else if (arg == "--p32-only") p32_only = true;
            else if (arg == "--help") {
                std::cout << "Options: --gate1 --p32-only --samples N --seed N --p16-start A --p16-end A\n"
                          << "P16 ranges are half-open; resume from CHECKPOINT next_A; combine logs without gaps.\n";
                return 0;
            } else {
                if (i+1 == argc) throw std::runtime_error("Missing argument value");
                std::string token = argv[++i];
                size_t consumed = 0;
                if (token.empty() || token[0] == '-') throw std::runtime_error("Expected unsigned integer");
                uint64_t value = std::stoull(token, &consumed);
                if (consumed != token.size()) throw std::runtime_error("Invalid integer");
                if (arg == "--samples") samples = value;
                else if (arg == "--seed") seed = value;
                else if (arg == "--p16-start" || arg == "--p16-end") {
                    if (value > 65536) throw std::runtime_error("P16 endpoint >65536");
                    if (arg == "--p16-start") start_a = uint32_t(value); else end_a = uint32_t(value);
                    range = true;
                } else throw std::runtime_error("Unknown option: " + arg);
            }
        }
        if (!samples || start_a >= end_a || (p32_only && (gate1 || range)) ||
            ((gate1 || p32_only) && samples < 10000000))
            throw std::runtime_error("Invalid/contradictory run configuration");
        if (p32_only) return test_p32_corners() && test_p32_sampled(samples,seed,true) ? 0 : 1;
    std::cout << "================================================================================" << std::endl;
    std::cout << "  L1 EXACT MULTIPLIER vs SOFTPOSIT L0 - GATE 1 BIT-EXACT VERIFICATION" << std::endl;
    std::cout << "================================================================================" << std::endl;

    bool ok_p8 = test_p8_exhaustive();
    bool ok_p32_corners = test_p32_corners();
    bool ok_p16 = (gate1 || range) ? test_p16_range(start_a,end_a) : test_p16_sampled(1000000);
    bool ok_p32 = test_p32_sampled(samples,seed,gate1);

    std::cout << "\n================================================================================" << std::endl;
    if (ok_p8 && ok_p32_corners && ok_p16 && ok_p32) {
        std::cout << ((gate1 && start_a == 0 && end_a == 65536) ?
            "  GATE 1 MULTIPLIER SUITE PASSED (identity must pass separately)" :
            "  SELECTED TESTS PASSED (not a full Gate 1 acceptance)") << std::endl;
        std::cout << "================================================================================" << std::endl;
        return 0;
    } else {
        std::cout << "  GATE 1 FAILED: DISCREPANCY DETECTED!" << std::endl;
        std::cout << "================================================================================" << std::endl;
        return 1;
    }
    } catch (const std::exception& e) {
        std::cerr << "CONFIG/GENERATOR ERROR: " << e.what() << std::endl;
        return 2;
    }
}
