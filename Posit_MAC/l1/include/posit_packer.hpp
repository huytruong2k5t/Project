#ifndef POSIT_PACKER_HPP
#define POSIT_PACKER_HPP

#include "posit_types.hpp"

namespace l1 {

template <int NB, int ES>
class PositPacker {
public:
    using storage_t = posit_storage_t<NB>;
    static constexpr int SF_MAX = posit_constants<NB, ES>::SF_MAX;

    static storage_t pack(const posit_unpacked<NB, ES>& u, RoundMode mode = RoundMode::RNE) {
        // 0. Special Values (§5.3)
        if (u.is_nar) {
            return static_cast<storage_t>(1ULL << (NB - 1));
        }
        if (u.is_zero || u.frac == 0) {
            return static_cast<storage_t>(0);
        }

        storage_t maxpos = static_cast<storage_t>((1ULL << (NB - 1)) - 1);
        storage_t minpos = static_cast<storage_t>(1);

        // 1. Pre-clamping (§5.9-A)
        if (u.sf >= SF_MAX) {
            return u.sign ? static_cast<storage_t>(-maxpos) : maxpos;
        }
        if (u.sf < -SF_MAX) {
            return u.sign ? static_cast<storage_t>(-minpos) : minpos;
        }

        // 2. Split Scale Factor
        uint32_t expF = static_cast<uint32_t>(u.sf & ((1 << ES) - 1));
        int32_t regF = u.sf >> ES;
        bool rc = (u.sf < 0);

        // 3. Wide buffer (unsigned __int128)
        constexpr int M = 120;
        using uint128_t = unsigned __int128;
        uint128_t buf = 0;
        uint64_t frac_no_hidden = u.frac & 0x7FFFFFFFFFFFFFFFULL;
        int shift_left_frac = (M - 2 - ES) - 62;

        uint128_t shifted = 0;
        if (!rc) {
            // k >= 0: inshift starts with '10'
            buf |= (static_cast<uint128_t>(1) << M);
            if constexpr (ES > 0) {
                buf |= (static_cast<uint128_t>(expF) << (M - 1 - ES));
            }
            buf |= (static_cast<uint128_t>(frac_no_hidden) << shift_left_frac);

            int shift = regF;
            shifted = buf >> shift;
            if (shift > 0) {
                uint128_t ones_mask = ((static_cast<uint128_t>(1) << shift) - 1) << (M - shift + 1);
                shifted |= ones_mask;
            }
        } else {
            // k < 0: inshift starts with '01'
            buf |= (static_cast<uint128_t>(1) << (M - 1));
            if constexpr (ES > 0) {
                buf |= (static_cast<uint128_t>(expF) << (M - 1 - ES));
            }
            buf |= (static_cast<uint128_t>(frac_no_hidden) << shift_left_frac);

            int shift = (-regF) - 1;
            shifted = buf >> shift;
        }

        // 4. Extract Magnitude and RNE fields
        int shift_out = M - (NB - 2);
        storage_t mag_raw = static_cast<storage_t>((shifted >> shift_out) & ((1ULL << (NB - 1)) - 1));
        
        storage_t mag_rounded = mag_raw;
        if (mode == RoundMode::RNE) {
            uint32_t lsb = mag_raw & 1;
            uint32_t g = static_cast<uint32_t>((shifted >> (shift_out - 1)) & 1);
            uint32_t r_bit = static_cast<uint32_t>((shifted >> (shift_out - 2)) & 1);
            uint128_t s_mask = (static_cast<uint128_t>(1) << (shift_out - 2)) - 1;
            uint32_t sticky = ((shifted & s_mask) != 0 || !u.exact) ? 1 : 0;

            uint32_t round_bit = g & (lsb | r_bit | sticky);
            mag_rounded = static_cast<storage_t>(mag_raw + round_bit);
            if (mag_rounded > maxpos) {
                mag_rounded = maxpos;
            }
        }

        // 5. Apply sign
        storage_t p_out = u.sign ? static_cast<storage_t>(-mag_rounded) : mag_rounded;
        return p_out;
    }
};

template <int NB, int ES>
inline posit_storage_t<NB> pack(const posit_unpacked<NB, ES>& u, RoundMode mode = RoundMode::RNE) {
    return PositPacker<NB, ES>::pack(u, mode);
}

} // namespace l1

#endif // POSIT_PACKER_HPP
