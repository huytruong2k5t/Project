#pragma once
#include <cstdint>
#include <stdexcept>
namespace l1 {
struct SacState {
    uint64_t fx;
    unsigned width, scale = 0, iterations = 0;
    SacState(uint64_t fraction, unsigned w) : fx(fraction), width(w) {
        if (!w || w > 27 || fraction >= (uint64_t(1) << w))
            throw std::invalid_argument("SAC width/fraction");
    }
    unsigned step() {
        if (!fx) throw std::logic_error("SAC has no remaining term");
        unsigned sa = 1;
        while (!(fx & (uint64_t(1) << (width - sa)))) ++sa;
        scale += sa;
        fx = (fx << sa) & ((uint64_t(1) << width) - 1);
        ++iterations;
        return sa;
    }
};
}
