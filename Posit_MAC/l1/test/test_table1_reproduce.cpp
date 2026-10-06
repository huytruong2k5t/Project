#include <array>
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include "l1_multiplier_iter.hpp"
using namespace l1;
struct Input { uint32_t bits; long double value; };
unsigned regime_length(uint32_t bits) {
    unsigned count = 0, first = (bits >> 30) & 1;
    for (int i = 30; i >= 0 && ((bits >> i) & 1) == first; --i) ++count;
    return count;
}
Input sample(std::mt19937_64& rng) {
    for (;;) {
        unsigned e;
        do { e = unsigned(rng() & 255); } while (e >= 240);
        int sf = int(e) - 120;
        uint32_t fraction = uint32_t(rng()) & 0x7fffff;
        posit_unpacked<32, 3> u{false, false, false, sf,
            (uint64_t(0x800000 | fraction) << 40), true};
        uint32_t bits = pack<32, 3>(u, RoundMode::RNE);
        if (regime_length(bits) <= 15)
            return {bits, std::ldexp(static_cast<long double>(0x800000 | fraction), sf - 23)};
    }
}
long double value(uint32_t bits) {
    auto u = parse<32, 3>(bits);
    return std::ldexp(static_cast<long double>(u.frac), u.sf - 63);
}
Input stratified(std::mt19937_64& rng, unsigned m, unsigned polarity) {
    // Positive finite operands: Cartesian product of 15 run lengths and
    // both regime polarities; random exponent and available fraction bits.
    unsigned f = 27 - m;
    uint32_t regime = polarity ? uint32_t(((uint64_t(1) << m) - 1) << (31 - m))
                               : uint32_t(1) << (30 - m);
    uint32_t bits = regime | (uint32_t(rng() & 7) << f) |
                    (uint32_t(rng()) & ((uint32_t(1) << f) - 1));
    return {bits, value(bits)};
}
int main(int argc, char** argv) try {
    uint64_t samples = 10000000, seed = 314159;
    unsigned ops = 0;
    bool require_match = false, posit_ideal = false, strat = false;
    ShiftRound scheme = ShiftRound::FLOOR;
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--require-match") { require_match = true; continue; }
        if (i + 1 >= argc) throw std::invalid_argument("missing argument value");
        std::string val = argv[++i];
        if (arg == "--samples") samples = std::stoull(val);
        else if (arg == "--seed") seed = std::stoull(val);
        else if (arg == "--ops") ops = unsigned(std::stoul(val));
        else if (arg == "--scheme" && (val == "floor" || val == "sticky"))
            scheme = val == "floor" ? ShiftRound::FLOOR : ShiftRound::STICKY_ACC;
        else if (arg == "--ideal" && (val == "fp32" || val == "posit")) posit_ideal = val == "posit";
        else if (arg == "--distribution" && (val == "fp32" || val == "stratified")) strat = val == "stratified";
        else throw std::invalid_argument("unknown argument/value: " + arg);
    }
    if (!samples || ops > 1 || (require_match && samples < 10000000))
        throw std::invalid_argument("invalid samples/OPS or insufficient acceptance samples");
    if (strat && !posit_ideal) throw std::invalid_argument("stratified posit inputs require --ideal posit");
    const std::array<long double, 4> limits{0.001L, 0.005L, 0.01L, 0.05L};
    const double paper[3][4] = {{9.87,32.19,50.03,95.57},
                              {44.69,83.17,95.05,99.99},
                              {87.09,99.79,99.99,99.99}};
    std::array<std::array<uint64_t, 4>, 6> counts{};
    std::mt19937_64 rng(seed);
    IterConfig cfg; cfg.ops = ops; cfg.scheme = scheme;
    std::cout << "NB=32 ES=3 FRAC_W=12 N_MAX=8 seed=" << seed << " samples/row=" << samples
              << " OPS=" << ops << " scheme=" << (scheme == ShiftRound::FLOOR ? "FLOOR" : "STICKY_ACC")
              << " rounding=TRUNC ideal=" << (posit_ideal ? "unrounded decoded posit product" : "unrounded original FP32 product")
              << " distribution=" << (strat ? "stratified" : "fp32") << '\n';
    if (strat) std::cout << "ASSUMPTION: positive posit inputs; 900 balanced cells of regime run"
                        << " mA,mB=1..15 and both regime polarities; uniform exponent/fraction bits.\n";
    else std::cout << "ASSUMPTION: independent positive normal FP32, uniform sf [-120,119], uniform 23-bit fraction;"
                   << " convert RNE to posit32 ES3 and reject regime run m>15.\n";
    std::cout << "No filter on product exponent. Paper does not fully specify sampling distribution.\n";
    auto start = std::chrono::steady_clock::now();
    for (uint64_t i = 0; i < samples; ++i) {
        unsigned cell = unsigned(i % 900);
        Input a = strat ? stratified(rng, 1 + cell % 15, (cell / 225) % 2) : sample(rng);
        Input b = strat ? stratified(rng, 1 + (cell / 15) % 15, cell / 450) : sample(rng);
        long double ideal = posit_ideal ? value(a.bits) * value(b.bits) : a.value * b.value;
        for (unsigned n = 1; n <= 6; ++n) {
            cfg.n = n;
            auto r = L1MultiplierIter<32, 3, 12>::mul(a.bits, b.bits, cfg);
            long double err = std::fabs(value(r.bits) - ideal) / ideal;
            for (unsigned j = 0; j < 4; ++j) if (err < limits[j]) ++counts[n - 1][j];
        }
    }
    double max_delta = 0;
    std::cout << "n,Err<0.1%,Err<0.5%,Err<1%,Err<5%,max_delta_pp_n2_to_n4\n" << std::fixed << std::setprecision(6);
    for (unsigned n = 1; n <= 6; ++n) {
        std::cout << n;
        double delta = 0;
        for (unsigned j = 0; j < 4; ++j) {
            double pct = 100.0 * double(counts[n - 1][j]) / double(samples);
            std::cout << ',' << pct;
            if (n >= 2 && n <= 4) delta = std::max(delta, std::fabs(pct - paper[n - 2][j]));
        }
        max_delta = std::max(max_delta, delta);
        std::cout << ',' << delta << '\n';
    }
    bool matched = max_delta <= 1.0 && samples >= 10000000;
    std::cout << "Table I acceptance=" << (matched ? "PASS" : "NOT_REPRODUCED")
              << " max_delta_pp=" << max_delta << " elapsed_seconds="
              << std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count() << '\n';
    if (strat) std::cout << "coverage_cells=900 min_pairs=" << samples / 900
                         << " max_pairs=" << (samples + 899) / 900 << '\n';
    return require_match && !matched ? 1 : 0;
} catch (const std::exception& e) { std::cerr << e.what() << '\n'; return 2; }
