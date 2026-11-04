#pragma once
#include <cstdint>
namespace l1 {
enum class ShiftRound { FLOOR, STICKY_ACC };
struct SbmState {
    uint64_t acc, y;
    unsigned fractional_bits;
    bool sticky = false;
    SbmState(uint64_t mantissa, unsigned source_bits, unsigned q)
        : acc(mantissa << (q - source_bits)), y(acc), fractional_bits(q) {}
    void add(unsigned scale, bool track_tail) {
        // Supported fraction widths imply scale <= 27.
        if (track_tail && (y & ((uint64_t(1) << scale) - 1))) sticky = true;
        acc += y >> scale;
    }
};
}
