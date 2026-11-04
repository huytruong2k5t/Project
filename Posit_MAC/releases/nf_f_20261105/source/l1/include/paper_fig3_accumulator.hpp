#pragma once

#include <cstdint>
#include <stdexcept>

namespace l1 {

// Research reconstruction of Fig.3, with hidden/carry made explicit.
// W fraction bits, W+1 payload bits and one separate carry flag.
// The total magnitude has W+2 bits. No fractional guard bits are kept.
// Fig.3 omits flag circuitry; this layout is a local representation contract,
// not a claim that the authors used this exact register encoding.
class PaperFig3Accumulator {
public:
    explicit PaperFig3Accumulator(unsigned fraction_width)
        : width_(fraction_width) {
        if (width_ < 1 || width_ > 27) {
            throw std::invalid_argument("Fig3 fraction width");
        }
    }

    uint64_t value() const {
        return payload_ | (uint64_t(carry_) << (width_ + 1));
    }

    uint64_t payload() const { return payload_; }
    bool carry() const { return carry_; }

    // Shift the full significand (hidden bit included), then discard low bits.
    // Apply the coefficient after truncation: -floor(Y/2^d), not floor(-Y/2^d).
    uint64_t update(uint64_t significand, unsigned shift, int coefficient) {
        const uint64_t hidden = uint64_t(1) << width_;
        if (significand < hidden || significand >= 2 * hidden ||
            (coefficient != 1 && coefficient != -1)) {
            throw std::invalid_argument("Fig3 term");
        }

        const uint64_t term = shift >= width_ + 1 ? 0 : significand >> shift;
        const uint64_t previous = value();
        uint64_t next;
        if (coefficient == 1) {
            next = previous + term;
        } else {
            if (term > previous) {
                throw std::logic_error("Fig3 accumulator borrow");
            }
            next = previous - term;
        }

        const uint64_t payload_mask = (uint64_t(1) << (width_ + 1)) - 1;
        const uint64_t magnitude_limit = uint64_t(1) << (width_ + 2);
        if (next >= magnitude_limit) {
            throw std::logic_error("Fig3 accumulator overflow beyond carry");
        }
        payload_ = next & payload_mask;
        carry_ = (next >> (width_ + 1)) != 0;
        return term;
    }

private:
    unsigned width_;
    uint64_t payload_ = 0;
    bool carry_ = false;
};

} // namespace l1
