#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include "../../tb/week11_model.hpp"

int main() try {
    std::mt19937_64 rng(20261013);
    uint64_t checked = 0, differences = 0, carry_odd = 0;
    std::ofstream trace("results/week11/prepack_discriminators.csv");
    trace << "a,b,n,magnitude,scale,q,legacy,new,oracle\n";
    for (unsigned n = 0; n <= 8; ++n) {
        l1::IterConfig config;
        config.n = n;
        config.ops = 1;
        config.rounding = l1::RoundMode::RNE;
        for (unsigned i = 0; i < 100000; ++i) {
            const uint32_t a = uint32_t(rng()), b = uint32_t(rng());
            const auto m = l1::L1MultiplierIter<32, 3, 12>::mul(a, b, config);
            const auto value = l1::pack<32, 3>(week11::normalize<32, 3>(m.prepack));
            const auto oracle = week11::dyadic<32, 3>(m.prepack);
            if (value != oracle) throw std::runtime_error("new mapping mismatch");
            carry_odd += (m.prepack.magnitude >= 8192 && (m.prepack.magnitude & 1));
            if (m.bits != value) {
                if (differences < 32) {
                    trace << std::hex << a << ',' << b << std::dec << ',' << n << ','
                          << m.prepack.magnitude << ',' << m.prepack.scale << ",12,"
                          << std::hex << m.bits << ',' << value << ',' << oracle << '\n';
                }
                ++differences;
            }
            ++checked;
        }
    }
    // Every useful magnitude, both signs, scales around range and regime boundaries.
    for (int scale : {-480, -241, -240, -239, -9, -8, -1, 0, 1, 7, 8, 239, 240, 480}) {
        for (uint64_t magnitude = 4096; magnitude < 16384; ++magnitude) {
            for (bool sign : {false, true}) {
                l1::PrepackProduct p;
                p.magnitude = magnitude;
                p.scale = scale;
                p.fractional_bits = 12;
                p.sign = sign;
                if (l1::pack<32, 3>(week11::normalize<32, 3>(p)) != week11::dyadic<32, 3>(p))
                    throw std::runtime_error("boundary mapping mismatch");
                ++checked;
            }
        }
    }
    std::cout << "W11 PREPACK PASS checked=" << checked << " new_mismatches=0"
              << " legacy_differences=" << differences << " carry_odd=" << carry_odd
              << " seed=20261013\n";
} catch (const std::exception& e) {
    std::cerr << "FAIL " << e.what() << '\n'; return 1;
}
