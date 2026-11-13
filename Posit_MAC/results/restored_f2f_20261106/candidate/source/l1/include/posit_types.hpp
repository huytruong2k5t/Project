#ifndef POSIT_TYPES_HPP
#define POSIT_TYPES_HPP

#include <cstdint>
#include <type_traits>

namespace l1 {

// Helper to choose storage integer type based on bit-width NB
template <int NB>
struct posit_storage {
    using type = typename std::conditional<
        (NB <= 8), uint8_t,
        typename std::conditional<
            (NB <= 16), uint16_t,
            typename std::conditional<(NB <= 32), uint32_t, uint64_t>::type
        >::type
    >::type;
};

template <int NB>
using posit_storage_t = typename posit_storage<NB>::type;

// Unpacked Posit Representation
template <int NB, int ES>
struct posit_unpacked {
    bool sign;        // false: positive, true: negative
    bool is_zero;     // true if value is zero
    bool is_nar;      // true if value is Not-a-Real
    int32_t sf;       // Combined Scale Factor: sf = k * 2^ES + e
    uint64_t frac;    // Mantissa aligned with hidden bit at MSB (bit 63)
    bool exact;       // true: no discarded numerical tail; false supplies packer's sticky
};

// Rounding Modes (§5.9)
enum class RoundMode {
    RNE,   // Round-to-Nearest-Even (FloPoCo 10-step, standard default)
    TRUNC  // Truncation / Round-toward-Zero (Norris & Kim [P])
};

// Posit architectural constants
template <int NB, int ES>
struct posit_constants {
    static constexpr int SF_MAX = (NB - 2) << ES;
    static constexpr int FRAC_MAX = NB - 3 - ES; // Maximum fraction bits without hidden bit
    static constexpr uint64_t HIDDEN_BIT = 1ULL << 63;
};

} // namespace l1

#endif // POSIT_TYPES_HPP
