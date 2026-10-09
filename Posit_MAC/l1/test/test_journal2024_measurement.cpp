#include <array>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <stdexcept>
#include <string>
#include "paper_multiplier.hpp"
#include "l1_multiplier_exact.hpp"
#include "../../l0/softposit_api.h"

// Journal 2024 Posit experiment, separate from the 2021 FP32 measurement.
// Generator, tie-A and prefix padding are declared local assumptions.
// n counts total signed-power terms; never adjust n to fit the graph.
using namespace l1;
namespace fs = std::filesystem;

uint64_t checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}

unsigned regime_length(uint32_t bits) {
    uint32_t mag = bits & 0x80000000u ? 0u - bits : bits;
    unsigned run = 0;
    const unsigned polarity = (mag >> 30) & 1;
    for (int i = 30; i >= 0 && ((mag >> i) & 1) == polarity; --i) ++run;
    return run;
}

bool below(uint32_t obtained, uint32_t reference, unsigned denominator) {
    const auto a = parse<32, 2>(obtained);
    const auto b = parse<32, 2>(reference);
    if (b.is_zero || b.is_nar) throw std::logic_error("undefined relative error");
    if (a.is_nar || a.is_zero || a.sign != b.sign) return false;
    const int delta = a.sf - b.sf;
    if (delta < -1 || delta > 1) return false;
    // Posit32 ES2 has at most 27 fraction bits. Alignment and *1000 fit u64.
    uint64_t x = a.frac >> 36;
    uint64_t y = b.frac >> 36;
    if (delta >= 0) x <<= unsigned(delta);
    else y <<= unsigned(-delta);
    const uint64_t difference = x > y ? x - y : y - x;
    return difference * denominator < y;
}

void self_test(const fs::path& output) {
    std::mt19937_64 rng(20261009);
    const uint32_t corners[] = {
        0, 1, 2, 0x7fffffff, 0x80000000, 0x80000001,
        0xffffffff, 0x40000000, 0x40000001, 0x3fffffff
    };
    for (uint32_t a : corners) {
        for (uint32_t b : corners) {
            check(L1MultiplierExact<32, 2>::mul(a, b) == l0_p32_mul(a, b),
                  "corner exact oracle mismatch");
        }
    }
    constexpr unsigned denominators[] = {1000, 200, 100, 20};
    for (unsigned i = 0; i < 100000; ++i) {
        const uint32_t a = uint32_t(rng());
        const uint32_t b = uint32_t(rng());
        const uint32_t ideal = l0_p32_mul(a, b);
        check(L1MultiplierExact<32, 2>::mul(a, b) == ideal,
              "random exact oracle mismatch");
        if (ideal && ideal != 0x80000000u) {
            const uint32_t obtained = uint32_t(rng());
            const long double ref = l0_p32_to_double(ideal);
            const long double got = l0_p32_to_double(obtained);
            for (unsigned d : denominators) {
                const bool independent = obtained != 0x80000000u &&
                    std::abs(got - ref) * d < std::abs(ref);
                check(below(obtained, ideal, d) == independent,
                      "relative threshold comparator mismatch");
            }
        }
        const double value = std::ldexp(double(rng() & 0xffffff), -24);
        int exponent = 0;
        const double significand = std::frexp(value, &exponent) * 2;
        posit_unpacked<32, 2> u{
            false, value == 0, false, exponent - 1,
            uint64_t(std::ldexp(significand, 63)), true
        };
        check(pack<32, 2>(u) == l0_double_to_p32(value), "conversion mismatch");
    }
    // Strict threshold ties: use dyadic values with exact Posit encodings.
    for (unsigned d : denominators) {
        const uint32_t ref = l0_double_to_p32(double(d));
        check(!below(l0_double_to_p32(double(d + 1)), ref, d), "upper threshold tie");
        check(!below(l0_double_to_p32(double(d - 1)), ref, d), "lower threshold tie");
        check(below(ref, ref, d), "zero error");
        check(below(0u - ref, 0u - ref, d), "negative exact result");
    }
    // Table VI: explicit X selection, no OPS inference from this fixture.
    constexpr uint32_t a = 0x1d200000;
    constexpr uint32_t b = 0x31040000;
    check((parse<32, 2>(a).frac >> 51) == 5248, "TableVI input X");
    check((parse<32, 2>(b).frac >> 51) == 4616, "TableVI input Y");
    std::ofstream trace_file(output / "table_vi_trace.csv");
    trace_file << "budget,iteration,mantissa,power,coefficient,next_mantissa,accumulator,output_hex\n";
    for (unsigned n : {2u, 3u}) {
        auto cfg = paper_fig3_config();
        cfg.ops = PaperOps::FixedA;
        cfg.n = n;
        std::vector<PaperStep> trace;
        const auto result = PaperMultiplier<32, 2>::mul(a, b, cfg, &trace);
        check(trace[0].accumulator == 4616, "TableVI first accumulator");
        check(trace[1].accumulator == 5770, "TableVI second accumulator");
        if (n == 2) {
            check(result.bits == 0x15a28000, "TableVI printed output");
            check(result.remainder && trace.back().next_mantissa != 0,
                  "TableVI prose zero residual contradicted by recurrence");
        } else {
            check(trace[2].accumulator == 5914, "TableVI third accumulator");
            check(result.bits == 0x15c68000, "TableVI three-term output");
            check(!result.remainder, "TableVI residual exhausted after third term");
        }
        for (const auto& t : trace) {
            trace_file << n << ',' << t.iteration << ',' << t.mantissa << ','
                       << t.power << ',' << t.coefficient << ',' << t.next_mantissa
                       << ',' << t.accumulator << ',' << std::hex << result.bits
                       << std::dec << '\n';
        }
    }
    std::cout << "SELF_TEST PASS checks=" << checks << " mismatches=0\n";
}

int main(int argc, char** argv) try {
    if (argc != 5) throw std::invalid_argument("usage: samples seed raw-posit|value01 output-directory");
    const uint64_t samples = std::stoull(argv[1]);
    const uint64_t seed = std::stoull(argv[2]);
    const std::string distribution = argv[3];
    if (!samples || (distribution != "raw-posit" && distribution != "value01"))
        throw std::invalid_argument("invalid measurement configuration");
    const fs::path output = argv[4];
    fs::create_directories(output);
    self_test(output);
    std::mt19937_64 rng(seed);
    uint64_t attempted = 0, excluded_zero = 0, excluded_nar = 0;
    uint64_t fingerprint = 14695981039346656037ULL;
    uint64_t counts[4][4] = {}, steps[4] = {};
    uint64_t ideal_ops_counts[4][4] = {};
    uint64_t regime_sum = 0, swaps = 0, early[4] = {};
    auto hash = [&](uint32_t word) {
        for (unsigned i = 0; i < 4; ++i) {
            fingerprint ^= (word >> (i * 8)) & 255;
            fingerprint *= 1099511628211ULL;
        }
    };
    const auto start = std::chrono::steady_clock::now();
    std::cout << "NB=32 ES=2 Q12 PT2=prefix7+zero5 tie=A n=total_terms2..5\n"
              << "samples=" << samples << " seed=" << seed << " distribution=" << distribution
              << " oracle=SoftPosit_p32_mul pack=TRUNC complement=ones per_term=FLOOR\n"
              << "NOT_AUTHOR_GENERATOR: distributions/seed/filter/tie/padding are local assumptions\n";
    uint64_t accepted = 0;
    while (accepted < samples) {
        auto next = [&]() {
            const uint64_t draw = rng();
            return distribution == "raw-posit" ? uint32_t(draw) :
                l0_double_to_p32(std::ldexp(double(draw & 0xffffff), -24));
        };
        const uint32_t a = next();
        const uint32_t b = next();
        ++attempted;
        hash(a);
        hash(b);
        if (a == 0x80000000u || b == 0x80000000u) { ++excluded_nar; continue; }
        if (!a || !b) { ++excluded_zero; continue; }
        const uint32_t ideal = l0_p32_mul(a, b);
        hash(ideal);
        regime_sum += regime_length(ideal);
        for (unsigned row = 0; row < 4; ++row) {
            auto cfg = paper_fig3_config();
            cfg.n = row + 2;
            const auto result = PaperMultiplier<32, 2>::mul(a, b, cfg);
            // Diagnostic upper bound within the frozen arithmetic contract:
            // allow an ideal selector to choose whichever operand meets each
            // threshold. This is not a deployable predictor or source change.
            cfg.ops = PaperOps::FixedA;
            const auto opposite = result.swapped ?
                PaperMultiplier<32, 2>::mul(a, b, cfg) :
                PaperMultiplier<32, 2>::mul(b, a, cfg);
            constexpr unsigned denominators[] = {1000, 200, 100, 20};
            for (unsigned j = 0; j < 4; ++j) {
                const bool selected_pass = below(result.bits, ideal, denominators[j]);
                counts[row][j] += selected_pass;
                ideal_ops_counts[row][j] += selected_pass ||
                    below(opposite.bits, ideal, denominators[j]);
            }
            steps[row] += result.iterations;
            early[row] += result.iterations < cfg.n;
            if (row == 0) swaps += result.swapped;
        }
        ++accepted;
        if (accepted % 1000000 == 0)
            std::cout << "CHECKPOINT accepted=" << accepted << std::endl;
    }
    std::ofstream csv(output / "measurement.csv");
    csv << "n,samples,below_0.1_count,below_0.5_count,below_1_count,below_5_count,below_0.1_pct,below_0.5_pct,below_1_pct,below_5_pct,avg_steps,early_stop,ideal_ops_0.1_pct,ideal_ops_0.5_pct,ideal_ops_1_pct,ideal_ops_5_pct\n";
    std::cout << std::fixed << std::setprecision(6);
    csv << std::fixed << std::setprecision(6);
    for (unsigned row = 0; row < 4; ++row) {
        csv << row + 2 << ',' << accepted;
        for (uint64_t count : counts[row]) csv << ',' << count;
        std::cout << "n=" << row + 2;
        for (uint64_t count : counts[row]) {
            const double rate = 100.0 * double(count) / double(accepted);
            csv << ',' << rate;
            std::cout << ',' << rate;
        }
        csv << ',' << double(steps[row]) / accepted << ',' << early[row];
        for (uint64_t count : ideal_ops_counts[row])
            csv << ',' << 100.0 * double(count) / double(accepted);
        csv << '\n';
        std::cout << '\n';
        std::cout << "ideal_ops_bound_n=" << row + 2;
        for (uint64_t count : ideal_ops_counts[row])
            std::cout << ',' << 100.0 * double(count) / double(accepted);
        std::cout << '\n';
    }
    std::cout << "attempted=" << attempted << " accepted=" << accepted
              << " excluded_zero=" << excluded_zero << " excluded_nar=" << excluded_nar
              << " swaps=" << swaps << " avg_output_regime_run=" << double(regime_sum) / accepted
              << " fingerprint=" << std::hex << fingerprint << std::dec << '\n'
              << "elapsed_seconds=" << std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count()
              << "\nJOURNAL2024_ACCEPTANCE=UNCONFIRMED_GRAPH_ONLY_AND_UNKNOWN_GENERATOR\n";
    if (!csv || !attempted || attempted != accepted + excluded_zero + excluded_nar)
        throw std::runtime_error("output/counter failure");
    return 0;
} catch (const std::exception& error) {
    std::cerr << "FAIL: " << error.what() << '\n';
    return 1;
}
