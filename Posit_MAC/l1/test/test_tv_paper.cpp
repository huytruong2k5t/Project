#include <iostream>
#include <random>
#include <stdexcept>
#include <vector>
#include "l1_multiplier_iter.hpp"
#include "l1_multiplier_exact.hpp"
#include "softposit_api.h"
using namespace l1;
static uint64_t checks = 0;
void require(bool condition, const char* label) {
    ++checks;
    if (!condition) throw std::runtime_error(label);
}
template<int NB, int ES> void exact_checks(unsigned count, std::mt19937_64& rng) {
    IterConfig cfg; cfg.exact = true; cfg.rounding = RoundMode::RNE;
    using T = posit_storage_t<NB>;
    for (unsigned i = 0; i < count; ++i) {
        T a = T(rng()), b = T(rng());
        if constexpr (NB == 8) { a = T(i >> 8); b = T(i); }
        auto r = L1MultiplierIter<NB, ES>::mul(a, b, cfg);
        T expected = L1MultiplierExact<NB, ES>::mul(a, b);
        require(r.bits == expected && !r.approx_cut && !r.input_cut, "iterative exact vs wide product");
        if constexpr (NB == 8) require(r.bits == l0_p8_mul(a, b), "iterative vs L0 p8");
        if constexpr (NB == 16) require(r.bits == l0_p16_mul(a, b), "iterative vs L0 p16");
        if constexpr (NB == 32 && ES == 2) require(r.bits == l0_p32_mul(a, b), "iterative vs L0 p32 ES2");
        cfg.ops = i & 1;
    }
    std::cout << "exact NB=" << NB << " ES=" << ES << " pairs=" << count << " PASS\n";
}
template<int NB, int ES, unsigned W> void approximate_checks(std::mt19937_64& rng) {
    using T = posit_storage_t<NB>;
    for (unsigned i = 0; i < 200000; ++i) {
        T a = T(rng()), b = T(rng());
        auto ua = parse<NB, ES>(a), ub = parse<NB, ES>(b);
        IterConfig cfg; cfg.n = i % 9; cfg.ops = (i / 9) % 2;
        bool track = (i / 18) % 2;
        cfg.scheme = track ? ShiftRound::STICKY_ACC : ShiftRound::FLOOR;
        cfg.rounding = (i / 36) % 2 ? RoundMode::RNE : RoundMode::TRUNC;
        auto got = L1MultiplierIter<NB, ES, W>::mul(a, b, cfg);
        if (ua.is_nar || ub.is_nar || ua.is_zero || ub.is_zero) {
            require(got.bits == ((ua.is_nar || ub.is_nar) ? T(uint64_t(1) << (NB - 1)) : T(0)),
                    "approximate NaR priority/zero bypass");
            continue;
        }
        const uint64_t mask = (uint64_t(1) << W) - 1;
        uint64_t x = (ua.frac >> (63 - W)) & mask, y = (ub.frac >> (63 - W)) & mask;
        bool swap = cfg.ops && fraction_popcount(y) < fraction_popcount(x);
        if (swap) std::swap(x, y);
        unsigned q = W + (track ? 2 : 0), used = 0;
        uint64_t ym = ((uint64_t(1) << W) | y) << (q - W), sum = ym;
        bool sticky = false, tail = false;
        for (unsigned pos = 1; pos <= W; ++pos) {
            if (!(x & (uint64_t(1) << (W - pos))) || used == cfg.n) continue;
            ++used;
            sum += ym / (uint64_t(1) << pos);
            bool lost = ym % (uint64_t(1) << pos);
            tail |= lost;
            sticky |= track && lost;
        }
        int sf = ua.sf + ub.sf;
        if (sum >= (uint64_t(2) << q)) { sticky |= sum & 1; sum >>= 1; ++sf; }
        posit_unpacked<NB, ES> expected{bool(ua.sign ^ ub.sign), false, false,
                                       sf, sum << (63 - q), !sticky};
        auto packed = pack<NB, ES>(expected, cfg.rounding);
        auto grid = parse<NB, ES>(packed);
        bool input_cut = (ua.frac | ub.frac) & ((uint64_t(1) << (63 - W)) - 1);
        bool cut = used < fraction_popcount(x);
        bool inexact = input_cut || cut || tail || sticky || grid.sf != sf || grid.frac != expected.frac;
        require(got.bits == packed && got.unpacked.sf == sf && got.unpacked.frac == expected.frac &&
                got.unpacked.exact == !sticky && got.iterations == used && got.swapped == swap &&
                got.approx_cut == cut && got.input_cut == input_cut && got.inexact == inexact,
                "random approximate independent bit-position oracle / flags");
    }
    std::cout << "approximate NB=" << NB << " ES=" << ES << " W=" << W << " pairs=200000 PASS\n";
}
int main() try {
    std::mt19937_64 rng(314159);
    IterConfig cfg;
    std::vector<IterStep> trace;
    // TV-ITER-01, directly encode 1.25 and 1.375 as posit32 ES3.
    uint32_t a = 0x41000000, b = 0x41800000;
    cfg.n = 0;
    auto r = L1MultiplierIter<32, 3, 4>::mul(a, b, cfg, &trace);
    require(r.bits == b && r.approx_cut && r.iterations == 0, "TV-ITER n=0");
    cfg.n = 1;
    r = L1MultiplierIter<32, 3, 4>::mul(a, b, cfg, &trace);
    require(r.unpacked.frac == (uint64_t(27) << 59) && r.inexact && !r.approx_cut,
            "TV-ITER FLOOR 1.6875, completion does not imply exactness");
    cfg.scheme = ShiftRound::STICKY_ACC;
    r = L1MultiplierIter<32, 3, 4>::mul(a, b, cfg);
    require(r.unpacked.frac == (uint64_t(55) << 58) && !r.inexact, "TV-ITER sticky 1.71875");
    // TV-PAPER-01: use literal packed bit fields, independent of pack().
    a = (uint32_t(1) << 28) | (uint32_t(6) << 25) | (uint32_t(0x480) << 13);
    b = (uint32_t(1) << 29) | (uint32_t(7) << 26) | (uint32_t(0x208) << 14);
    cfg.scheme = ShiftRound::FLOOR; cfg.n = 2;
    r = L1MultiplierIter<32, 3, 12>::mul(a, b, cfg, &trace);
    require(trace.size() == 2 && trace[0].sa == 2 && trace[0].scale == 2 &&
            trace[0].fx == 0x200 && trace[0].acc == 0x168a &&
            trace[1].sa == 3 && trace[1].scale == 5 && trace[1].fx == 0 &&
            trace[1].acc == 0x171a, "TV-PAPER SAC/SBM trace");
    require(r.unpacked.sf == -11 && r.bits == ((uint32_t(1) << 28) |
            (uint32_t(5) << 25) | (uint32_t(0x71a) << 13)), "TV-PAPER packed output");
    require(r.inexact && !r.approx_cut, "TV-PAPER floor lost tail");
    std::cout << "TV-ITER-01 / TV-PAPER-01 PASS\n";
    // Independent fixed-point oracle sums selected original bit positions,
    // rather than SAC's accumulated shifts. Exhaust every 4-bit fraction pair.
    for (unsigned scheme = 0; scheme < 2; ++scheme)
    for (unsigned ops = 0; ops < 2; ++ops)
    for (unsigned n = 0; n <= 8; ++n)
    for (unsigned x = 0; x < 16; ++x)
    for (unsigned y = 0; y < 16; ++y) {
        cfg.n = n; cfg.ops = ops;
        cfg.scheme = scheme ? ShiftRound::STICKY_ACC : ShiftRound::FLOOR;
        auto got = L1MultiplierIter<32, 3, 4>::mul(0x40000000 | (x << 22),
                                                  0x40000000 | (y << 22), cfg);
        unsigned xx = x, yy = y;
        if (ops && fraction_popcount(y) < fraction_popcount(x)) std::swap(xx, yy);
        unsigned q = 4 + 2 * scheme, used = 0;
        uint64_t ym = (16 + yy) << (q - 4), sum = ym;
        bool sticky = false;
        for (unsigned pos = 1; pos <= 4; ++pos) {
            if (!(xx & (1u << (4 - pos))) || used == n) continue;
            ++used; sum += ym >> pos;
            if (scheme && ym % (1u << pos)) sticky = true;
        }
        int sf = 0;
        if (sum >= (2u << q)) { sticky |= sum & 1; sum >>= 1; sf = 1; }
        require(got.unpacked.sf == sf && got.unpacked.frac == (sum << (63 - q)) &&
                got.unpacked.exact == !sticky && got.iterations == used,
                "independent approximate fixed-point oracle");
    }
    bool rejected = false;
    try { cfg.ops = 2; L1MultiplierIter<32, 3>::mul(a, b, cfg); }
    catch (const std::invalid_argument&) { rejected = true; }
    require(rejected, "reserved OPS rejection");
    rejected = false; cfg.ops = 0; cfg.n = 9;
    try { L1MultiplierIter<32, 3>::mul(a, b, cfg); }
    catch (const std::invalid_argument&) { rejected = true; }
    require(rejected, "iteration overflow rejection");
    cfg.n = 0; cfg.scheme = static_cast<ShiftRound>(99); rejected = false;
    try { L1MultiplierIter<32, 3>::mul(a, b, cfg); }
    catch (const std::invalid_argument&) { rejected = true; }
    require(rejected, "invalid scheme rejection");
    cfg.scheme = ShiftRound::FLOOR; cfg.rounding = static_cast<RoundMode>(99); rejected = false;
    try { L1MultiplierIter<32, 3>::mul(a, b, cfg); }
    catch (const std::invalid_argument&) { rejected = true; }
    require(rejected, "invalid final rounding rejection");
    cfg.exact = true; cfg.rounding = RoundMode::RNE;
    auto full = L1MultiplierIter<32, 2>::mul(0x47ffffff, 0x47ffffff, cfg);
    require(full.iterations == 27 && !full.approx_cut &&
            full.bits == l0_p32_mul(0x47ffffff, 0x47ffffff), "exact bypasses N_MAX=8");
    rejected = false;
    try { L1MultiplierIter<32, 2, 12, 8, false>::mul(a, b, cfg); }
    catch (const std::invalid_argument&) { rejected = true; }
    require(rejected, "EXACT_EN=false rejection");
    cfg.exact = false; cfg.n = 0; cfg.ops = 1; rejected = false;
    try { L1MultiplierIter<32, 2, 12, 8, true, false>::mul(a, b, cfg); }
    catch (const std::invalid_argument&) { rejected = true; }
    require(rejected, "OPS_EN=false rejection");
    cfg.ops = 0;
    auto input_tail = L1MultiplierIter<32, 3>::mul(0x40000001, 0x40000000, cfg);
    require(input_tail.input_cut && input_tail.inexact && !input_tail.approx_cut &&
            input_tail.unpacked.exact, "input loss is independent of SBM sticky/completion");
    auto max = L1MultiplierIter<32, 3>::mul(0x7fffffff, 0x7fffffff, cfg);
    auto min = L1MultiplierIter<32, 3>::mul(1, 1, cfg);
    require(max.saturated && max.bits == 0x7fffffff && min.saturated && min.bits == 1,
            "max/min saturation flags");
    approximate_checks<8, 0, 5>(rng);
    approximate_checks<16, 1, 12>(rng);
    approximate_checks<32, 2, 12>(rng);
    approximate_checks<32, 3, 12>(rng);
    exact_checks<8, 0>(65536, rng);
    exact_checks<16, 1>(1000000, rng);
    exact_checks<32, 2>(1000000, rng);
    exact_checks<32, 3>(1000000, rng);
    std::cout << "checks=" << checks << " seed=314159 PASS\n";
    return 0;
} catch (const std::exception& e) { std::cerr << "FAIL: " << e.what() << '\n'; return 1; }
