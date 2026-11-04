#pragma once
#include <cstdint>

namespace l1 {
// Finite value: (-1)^sign * magnitude * 2^(scale - fractional_bits).
// FLOOR cuts define the approximate value, not an additional numerical tail.
struct PrepackProduct {
    uint64_t magnitude = 0;
    int32_t scale = 0;
    unsigned fractional_bits = 0;
    unsigned magnitude_bits = 0;
    bool sign = false;
    bool is_zero = false;
    bool is_nar = false;
    bool numerical_sticky = false;
    bool input_cut = false;
    bool iteration_cut = false;
    bool term_cut = false;
};
}
