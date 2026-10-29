#include <fstream>
#include <iostream>
#include <random>
#include "full_term_reference.hpp"
int main(int argc, char** argv) try {
    if (argc != 3) throw std::invalid_argument("count output.json");
    const uint64_t count = std::stoull(argv[1]);
    constexpr uint64_t seed = 20261029;
    std::mt19937_64 rng(seed);
    full_term32::Config cfg;
    const uint32_t p1 = 0x40000000u;
    const auto check_m = [&](uint32_t fx, uint32_t fy, unsigned n, uint64_t expected) {
        cfg.n = n; cfg.ops = 0;
        const auto p = full_term32::multiply(p1 | (fx << 14), p1 | (fy << 14),cfg);
        if (p.value.magnitude != expected) throw std::runtime_error("FT contract magnitude");
    };
    check_m(0,0,12,16777216);
    check_m(1,4095,0,33550336);
    check_m(1,4095,1,33558527);
    check_m(4095,4095,12,67092481);
    cfg.n = 12;
    for (bool fused : {false,true}) {
        const auto p = opt17_reference::checked(0x1c900000,0x3c820000,0,cfg,fused);
        if (p.bits != 0x1ae34800 || p.product.value.magnitude != 24224768)
            throw std::runtime_error("FT-05");
    }
    uint64_t checks = 0;
    for (uint64_t i = 0; i < count; ++i) {
        cfg.approximate = i % 4 != 0;
        cfg.n = unsigned(i % 13);
        cfg.ops = unsigned((i / 13) % 2);
        uint32_t a = uint32_t(rng()), b = uint32_t(rng()), c = uint32_t(rng());
        if (i % 11 == 0) c = 0;
        if (i % 37 == 0) a = 0;
        if (i % 53 == 0) b = full_term32::NAR;
        if (i % 71 == 0) c = full_term32::NAR;
        if (i % 19 == 0) { a = 0x40000000u | (uint32_t(rng() % 4096) << 14); b = a; c = 0u-a; }
        opt17_reference::checked(a,b,c,cfg,false); ++checks;
        cfg.approximate = true;
        opt17_reference::checked(a,b,c,cfg,true); ++checks;
    }
    // Every X fraction, each n; sparse/deep/full masks are not left to RNG.
    for (unsigned fx = 0; fx < 4096; ++fx) {
        for (unsigned n = 0; n <= 12; ++n) {
            cfg.n = n; cfg.ops = 0;
            opt17_reference::checked(p1 | (fx << 14),0x43ffc000u,0,cfg,true);
            ++checks;
        }
    }
    std::ofstream out(argv[2]);
    out << "{\"status\":\"PASS\",\"seed\":" << seed << ",\"random_pairs\":" << count
        << ",\"independent_checks\":" << checks << ",\"contract_vectors\":5,\"mismatches\":0}\n";
    std::cout << "FULL_TERM_GOLDEN_PASS independent_checks=" << checks << " mismatch=0\n";
} catch (const std::exception& e) { std::cerr << e.what() << '\n'; return 1; }
