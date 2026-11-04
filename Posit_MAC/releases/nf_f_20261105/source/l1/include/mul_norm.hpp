#pragma once
#include "posit_types.hpp"
namespace l1 {
template<int NB, int ES>
posit_unpacked<NB, ES> mul_norm(uint64_t acc, unsigned q, int32_t sf,
                               bool sign, bool sticky) {
    if (acc & (uint64_t(1) << (q + 1))) {
        sticky = sticky || (acc & 1);
        acc >>= 1;
        ++sf;
    }
    return {sign, false, false, sf, acc << (63 - q), !sticky};
}
}
