#include <iostream>
#include <iomanip>
#include <vector>
#include <cmath>
#include <random>
#include <cstdint>
#include <cstring>
#include <algorithm>
#include <stdexcept>
#include <cfenv>

// Independent, clean implementation of Kim 2019 algorithms and ablations.
namespace kim_study {

inline float from_bits(uint32_t b) { float f; std::memcpy(&f, &b, 4); return f; }
inline uint32_t to_bits(float f) { uint32_t b; std::memcpy(&b, &f, 4); return b; }

// SPFP components
struct Spfp {
    uint32_t sign;
    int exp; // biased 0..255
    uint32_t frac; // 23 bits
    uint32_t mantissa; // 24 bits: (1 << 23) | frac
    float val;
};

inline Spfp unpack_spfp(uint32_t bits) {
    Spfp s;
    s.sign = bits >> 31;
    s.exp = int((bits >> 23) & 0xFF);
    s.frac = bits & 0x7FFFFF;
    s.mantissa = (1u << 23) | s.frac;
    s.val = from_bits(bits);
    return s;
}

inline uint32_t pack_spfp(uint32_t sign, int exp, uint32_t mantissa_aligned) {
    // mantissa_aligned has hidden bit at bit 23
    if (exp <= 0) return 0; // underflow to zero
    if (exp >= 255) return (sign << 31) | 0x7F800000;
    return (sign << 31) | (uint32_t(exp) << 23) | (mantissa_aligned & 0x7FFFFF);
}

// -------------------------------------------------------------
// 1. BASE: Pure Mitchell Iterative (Eq. 8-9)
// AP_n(X) = sum_{i=1}^n 2^{l_i(X)}
// -------------------------------------------------------------
inline uint32_t mul_base(const Spfp& X, const Spfp& Y, unsigned n) {
    // Extract powers of two from X
    // In BASE, l_1 = expX - 127. The first term is 2^{l_1}.
    // Remaining terms are just extracting the successive leading 1s of X's fraction.
    uint32_t mx = X.mantissa; // bit 23 is 1
    uint32_t my = Y.mantissa; // bit 23 is 1
    
    // Accumulator starts with Y shifted by 0 (corresponding to term 1 at l1)
    // To maintain full precision in adder, use 64-bit integer
    uint64_t acc = uint64_t(my) << 24; // scale up by 24 bits for guard bits
    
    // Remaining terms: find subsequent 1-bits of mx
    uint32_t rem = mx & ~(1u << 23); // remove leading 1
    unsigned terms_found = 1;
    
    while (rem > 0 && terms_found < n) {
        // Leading zero counter of rem in 23-bit space
        // bit 22 down to 0
        int lz = 0;
        while ((rem & (1u << (22 - lz))) == 0) {
            ++lz;
        }
        int shift = lz + 1; // shift relative to bit 23
        acc += (uint64_t(my) << 24) >> shift;
        rem &= ~(1u << (22 - lz)); // clear this bit
        ++terms_found;
    }
    
    // Product exponent is initially: expX + expY - 127
    int exp_out = X.exp + Y.exp - 127;
    // Normalize acc: acc has initial hidden bit at bit 47 (23 + 24)
    uint64_t hidden_pos = uint64_t(1) << 47;
    if (acc >= (hidden_pos << 1)) {
        acc >>= 1;
        exp_out += 1;
    }
    // Extract 24-bit mantissa (bit 47 is hidden bit)
    uint32_t final_mantissa = uint32_t(acc >> 24);
    return pack_spfp(X.sign ^ Y.sign, exp_out, final_mantissa);
}

// -------------------------------------------------------------
// 2. BASE + RND: Algorithm 1
// Threshold can be 1.5 (hardware) or sqrt(2) (math)
// Complement can be ones-complement or exact subtraction
// -------------------------------------------------------------
struct RndOptions {
    bool use_sqrt2_threshold = false;
    bool use_ones_complement = true; // Section 3.1: "approximately implemented using a complement operator"
};

inline uint32_t mul_base_rnd(const Spfp& X, const Spfp& Y, unsigned n, RndOptions opt) {
    uint32_t mx = X.mantissa; // 24 bits: [23:0]
    uint32_t my = Y.mantissa;
    
    int64_t acc = 0;
    int exp_X = X.exp - 127;
    int cur_exp = exp_X;
    
    uint64_t cur_mant = mx; // normalized mantissa in [1, 2), bit 23 is 1
    int coeff = 1; // +1 or -1
    
    int l1 = 0;
    bool first = true;
    
    for (unsigned k = 0; k < n && cur_mant > 0; ++k) {
        // Determine f
        bool f = false;
        if (opt.use_sqrt2_threshold) {
            // sqrt(2) * 2^23 = 11863283.
            f = cur_mant >= 11863283ULL;
        } else {
            // 1.5 * 2^23 = (1 << 23) | (1 << 22) = 12582912 (bit 22 is 1)
            f = (cur_mant & (1u << 22)) != 0;
        }
        
        int l = cur_exp + (f ? 1 : 0);
        if (first) {
            l1 = l;
            first = false;
        }
        
        // Term value: Y shifted by (l1 - l)
        int shift = l1 - l;
        int64_t term = 0;
        if (shift >= 0 && shift < 60) {
            term = int64_t((uint64_t(my) << 24) >> shift);
        }
        acc += coeff * term;
        
        // Advance residual
        // hidden bit is (1 << 23)
        uint64_t hidden = 1u << 23;
        uint64_t tail = 0;
        if (f) {
            if (opt.use_ones_complement) {
                // Section 3.1: one's complement of mantissa: 2*hidden - cur_mant - 1
                tail = 2 * hidden - cur_mant - 1;
            } else {
                tail = 2 * hidden - cur_mant; // exact two's complement
            }
            coeff = -coeff;
        } else {
            tail = cur_mant - hidden;
        }
        
        if (tail == 0) {
            cur_mant = 0;
            break;
        }
        
        // Normalize tail to [1, 2)
        int lz = 0;
        while (tail < hidden) {
            tail <<= 1;
            ++lz;
        }
        cur_mant = tail;
        cur_exp -= lz;
    }
    
    if (acc <= 0) acc = 1; // safety guard
    
    int exp_out = l1 + Y.exp; // l1 + (expY - 127) + 127
    uint64_t hidden_pos = uint64_t(1) << 47;
    while (uint64_t(acc) >= (hidden_pos << 1)) {
        acc >>= 1;
        exp_out += 1;
    }
    while (uint64_t(acc) < hidden_pos && exp_out > 0) {
        acc <<= 1;
        exp_out -= 1;
    }
    
    uint32_t final_mantissa = uint32_t(acc >> 24);
    return pack_spfp(X.sign ^ Y.sign, exp_out, final_mantissa);
}

// -------------------------------------------------------------
// 3. BASE + RND + TRNC (11-bit truncation)
// -------------------------------------------------------------
struct TrncOptions {
    bool truncate_both = true; // Section 3.2: "two input operands"
    bool truncate_output = true; // Fig. 4: o[30:11]
    RndOptions rnd_opt;
};

inline uint32_t mul_base_rnd_trnc(const Spfp& X, const Spfp& Y, unsigned n, TrncOptions opt) {
    // 11-bit truncation leaves 12 bits of fraction + 1 hidden bit = 13 bits of mantissa
    // Truncate X
    uint32_t mx = (X.mantissa >> 11) << 11;
    uint32_t my = opt.truncate_both ? ((Y.mantissa >> 11) << 11) : Y.mantissa;
    
    Spfp X_trnc = X; X_trnc.mantissa = mx;
    Spfp Y_trnc = Y; Y_trnc.mantissa = my;
    
    uint32_t res = mul_base_rnd(X_trnc, Y_trnc, n, opt.rnd_opt);
    
    if (opt.truncate_output) {
        // Truncate lower 11 bits of result mantissa as shown in Fig. 4 o[30:11]
        res &= ~0x7FFu;
    }
    return res;
}

// -------------------------------------------------------------
// 4. BASE + RND + TRNC + SEL (Table 2 Prediction Table)
// -------------------------------------------------------------
inline unsigned kim_predict_error_7bit(uint32_t mantissa13) {
    // Top 7 bits of fraction (bits 11..5 of fraction12, i.e. bits 22..16 of SPFP)
    unsigned f7 = (mantissa13 >> 5) & 0x7F;
    unsigned m = 128 + f7;
    // Simulate n=2 error using Table 2 logic (or reconstructed 7-bit predictor)
    int exponent = 0, sign = 1, approximation = 0;
    for (unsigned i = 0; i < 2 && m > 0; ++i) {
        bool up = m >= 192; // 1.5 * 128
        approximation += sign * (1 << (7 + exponent + int(up)));
        unsigned residual = up ? 255 - m : m - 128;
        if (up) sign = -sign;
        if (!residual) break;
        while (residual < 128) { residual *= 2; --exponent; }
        m = residual;
    }
    int err = int(128 + f7) - approximation;
    return unsigned(err < 0 ? -err : err);
}

inline uint32_t mul_base_rnd_trnc_sel(const Spfp& A, const Spfp& B, unsigned n, TrncOptions opt) {
    uint32_t ma13 = A.mantissa >> 11;
    uint32_t mb13 = B.mantissa >> 11;
    
    unsigned errA = kim_predict_error_7bit(ma13);
    unsigned errB = kim_predict_error_7bit(mb13);
    
    bool swap = errB < errA; // smaller error operand is selected as X to approximate
    const Spfp& X = swap ? B : A;
    const Spfp& Y = swap ? A : B;
    
    return mul_base_rnd_trnc(X, Y, n, opt);
}

} // namespace kim_study
