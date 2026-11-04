#pragma once
#include <cstdint>
#include <stdexcept>
namespace l1 {
inline unsigned fraction_popcount(uint64_t x) {
    unsigned n = 0;
    while (x) { x &= x - 1; ++n; }
    return n;
}
// cfg_ops=0: X=A. cfg_ops=1: minimum fraction popcount, ties A.
inline bool ops_swap(uint64_t a, uint64_t b, unsigned policy) {
    if (policy > 1) throw std::invalid_argument("reserved cfg_ops");
    return policy == 1 && fraction_popcount(b) < fraction_popcount(a);
}
}
