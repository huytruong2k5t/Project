#pragma once
#include "l1_multiplier_iter.hpp"

namespace l1 {
// Explicit comparison profile; legacy IterConfig defaults remain unchanged.
inline IterConfig floor_rne_profile(unsigned n) {
    if (n > 8) {
        throw std::invalid_argument("FLOOR/RNE comparison profile requires n<=8");
    }
    IterConfig config;
    config.exact = false;
    config.n = n;
    config.ops = 1;
    config.scheme = ShiftRound::FLOOR;
    config.rounding = RoundMode::RNE;
    return config;
}
using FloorRneMultiplier = L1MultiplierIter<32, 3, 12, 8, true, true>;
}
