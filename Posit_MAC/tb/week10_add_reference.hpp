#pragma once
#include <algorithm>
#include <array>
#include <cstdint>
#include <vector>

// Independent raw-Posit decoder and full-grid integer addition/serial encoder.
// No L1 parser, adder, alignment clamp, packer, or floating-point arithmetic.
namespace week10_reference {
struct Result {
    uint32_t rne = 0;
    uint32_t trunc = 0;
    unsigned flags_rne = 0;
    unsigned flags_trunc = 0;
};
template<int NB, int ES> class Adder {
    static constexpr int F = NB - 3 - ES;
    static constexpr int SCALE = (NB - 2) * (1 << ES);
    static constexpr unsigned WORDS = (2 * SCALE + F + 4 + 63) / 64;
    static constexpr uint32_t NAR = uint32_t(1) << (NB - 1);
    static constexpr uint32_t MASK = uint32_t((uint64_t(1) << NB) - 1);
    using Wide = std::array<uint64_t, WORDS>;
    struct Value {
        bool sign;
        uint64_t significand;
        int scale;
    };
    static Value decode(uint32_t raw) {
        const bool sign = (raw & NAR) != 0;
        const uint32_t mag = sign ? (0u - raw) & MASK : raw;
        if (!mag) {
            return {false, 0, 0};
        }
        int position = NB - 2;
        const bool polarity = (mag >> position) & 1;
        int run = 0;
        while (position >= 0 && bool((mag >> position) & 1) == polarity) {
            ++run;
            --position;
        }
        if (position >= 0) {
            --position;
        }
        int exponent = 0;
        for (int i = 0; i < ES; ++i) {
            exponent <<= 1;
            if (position >= 0) {
                exponent |= (mag >> position--) & 1;
            }
        }
        const unsigned available = unsigned(position + 1);
        const uint64_t fraction = mag & ((uint64_t(1) << available) - 1);
        return {sign, (uint64_t(1) << F) | (fraction << (F - available)),
                (polarity ? run - 1 : -run) * (1 << ES) + exponent};
    }
    static Wide expand(Value value) {
        Wide out{};
        if (value.significand) {
            const unsigned shift = unsigned(value.scale + SCALE);
            const unsigned word = shift / 64;
            const unsigned bit = shift % 64;
            out[word] = value.significand << bit;
            if (bit && word + 1 < WORDS) {
                out[word + 1] = value.significand >> (64 - bit);
            }
        }
        return out;
    }
    static uint32_t encode(const Wide& magnitude, int top, bool sign, bool rne) {
        const int sf = top - SCALE - F;
        uint32_t code;
        if (sf >= SCALE) {
            code = NAR - 1;
        } else if (sf < -SCALE) {
            code = 1;
        } else {
            int regime = sf / (1 << ES);
            if (sf < 0 && sf % (1 << ES)) {
                --regime;
            }
            const int exponent = sf - regime * (1 << ES);
            std::vector<bool> stream;
            stream.reserve(unsigned(2 * SCALE + F + NB + 8));
            stream.insert(stream.end(), regime >= 0 ? regime + 1 : -regime,
                          regime >= 0);
            stream.push_back(regime < 0);
            for (int i = ES - 1; i >= 0; --i) {
                stream.push_back((exponent >> i) & 1);
            }
            for (int i = top - 1; i >= 0; --i) {
                stream.push_back((magnitude[unsigned(i) / 64] >> (unsigned(i) % 64)) & 1);
            }
            while (stream.size() < unsigned(NB)) {
                stream.push_back(false);
            }
            code = 0;
            for (int i = 0; i < NB - 1; ++i) {
                code = (code << 1) | stream[unsigned(i)];
            }
            bool below_guard = false;
            for (unsigned i = NB; i < stream.size(); ++i) {
                below_guard |= stream[i];
            }
            if (rne && stream[NB - 1] && ((code & 1) || below_guard)) {
                ++code;
            }
            code = std::max(1u, std::min(NAR - 1, code));
        }
        return (sign ? 0u - code : code) & MASK;
    }
public:
    static Result add(uint32_t a, uint32_t b, unsigned incoming = 0) {
        a &= MASK;
        b &= MASK;
        if (a == NAR || b == NAR || (incoming & 16)) {
            return {NAR, NAR, 16, 16};
        }
        auto va = decode(a);
        auto vb = decode(b);
        Wide x = expand(va), y = expand(vb), sum{};
        bool sign = va.sign;
        int comparison = 0;
        for (int i = int(WORDS) - 1; i >= 0; --i) {
            if (x[unsigned(i)] != y[unsigned(i)]) {
                comparison = x[unsigned(i)] > y[unsigned(i)] ? 1 : -1;
                break;
            }
        }
        if (va.sign == vb.sign) {
            uint64_t carry = 0;
            for (unsigned i = 0; i < WORDS; ++i) {
                const unsigned __int128 total = static_cast<unsigned __int128>(x[i]) + y[i] + carry;
                sum[i] = uint64_t(total);
                carry = uint64_t(total >> 64);
            }
        } else {
            if (comparison < 0) {
                std::swap(x, y);
                sign = vb.sign;
            }
            uint64_t borrow = 0;
            for (unsigned i = 0; i < WORDS; ++i) {
                const unsigned __int128 sub = static_cast<unsigned __int128>(y[i]) + borrow;
                sum[i] = x[i] - uint64_t(sub);
                borrow = static_cast<unsigned __int128>(x[i]) < sub;
            }
        }
        int top = int(WORDS * 64) - 1;
        while (top >= 0 && !((sum[unsigned(top) / 64] >> (unsigned(top) % 64)) & 1)) {
            --top;
        }
        if (top < 0) {
            return {0, 0, incoming & 15, incoming & 15};
        }
        const uint32_t rne = encode(sum, top, sign, true);
        const uint32_t trunc = encode(sum, top, sign, false);
        Wide hidden{};
        hidden[unsigned(top) / 64] = uint64_t(1) << (unsigned(top) % 64);
        const int sf = top - SCALE - F;
        const bool sat_max = sf > SCALE || (sf == SCALE && sum != hidden);
        const bool sat_min = sf < -SCALE;
        auto flags = [&](uint32_t packed) {
            const auto decoded = decode(packed);
            const bool inexact = expand(decoded) != sum || decoded.sign != sign;
            return (incoming & 15) | (sat_max ? 8u : 0u) | (sat_min ? 4u : 0u) |
                   (inexact ? 2u : 0u);
        };
        return {rne, trunc, flags(rne), flags(trunc)};
    }
};
}
