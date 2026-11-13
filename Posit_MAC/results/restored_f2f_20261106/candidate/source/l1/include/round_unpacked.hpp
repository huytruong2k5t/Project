#ifndef ROUND_UNPACKED_HPP
#define ROUND_UNPACKED_HPP

#include "posit_types.hpp"

namespace l1 {

template <int NB, int ES>
class RoundUnpacked {
public:
    static constexpr int SF_MAX = posit_constants<NB, ES>::SF_MAX;
    static constexpr int FRAC_MAX = posit_constants<NB, ES>::FRAC_MAX;

    // Canonical Posit-grid result, equivalent to parse(pack(in, mode)).
    // Bounded payload stream; no pack/parse calls or 128-bit buffer.
    static posit_unpacked<NB, ES> round(const posit_unpacked<NB, ES>& in,
                                        RoundMode mode = RoundMode::RNE) {
        static_assert(NB >= 4 && NB <= 32, "round_unpacked supports 4..32 bits");
        static_assert(ES >= 0 && ES <= 6 && ES <= NB - 3,
                      "Unsupported exponent size for L1 integer scale");
        posit_unpacked<NB, ES> out{};
        out.exact = true; // No numerical remainder is passed to the adder.
        if (in.is_nar) {
            out.is_nar = true;
            out.sign = true;
            return out;
        }
        if (in.is_zero || in.frac == 0) {
            out.is_zero = true;
            return out;
        }
        out.sign = in.sign;
        constexpr uint64_t hidden = uint64_t(1) << 63;
        constexpr uint64_t max_mag = (uint64_t(1) << (NB - 1)) - 1;
        if (in.sf >= SF_MAX || in.sf < -SF_MAX) {
            out.sf = in.sf >= SF_MAX ? SF_MAX : -SF_MAX;
            out.frac = hidden;
            return out;
        }

        // Floor division of signed scale without shifting a negative integer.
        constexpr int useed_exp = 1 << ES;
        int k = in.sf / useed_exp;
        int e = in.sf % useed_exp;
        if (e < 0) { --k; e += useed_exp; }
        const bool rc = k >= 0;
        const int run = rc ? k + 1 : -k;
        auto bit = [&](int position) -> bool {
            if (position < run) return rc;
            if (position == run) return !rc;
            int tail = position - run - 1;
            if (tail < ES) return ((e >> (ES - 1 - tail)) & 1) != 0;
            tail -= ES;
            return tail < 63 && ((in.frac >> (62 - tail)) & 1) != 0;
        };

        uint64_t mag = 0;
        for (int i = 0; i < NB - 1; ++i) mag = (mag << 1) | bit(i);
        if (mode == RoundMode::RNE) {
            const bool guard = bit(NB - 1);
            const bool round_bit = bit(NB);
            bool sticky = !in.exact;
            for (int i = NB + 1; i < run + 1 + ES + 63; ++i) sticky |= bit(i);
            if (guard && ((mag & 1) || round_bit || sticky)) ++mag;
            if (mag > max_mag) mag = max_mag;
        }

        // Recover canonical fields after carries and shortened exponent fields.
        int index = NB - 2;
        const bool rounded_rc = ((mag >> index) & 1) != 0;
        int rounded_run = 0;
        while (index >= 0 && bool((mag >> index) & 1) == rounded_rc) {
            ++rounded_run;
            --index;
        }
        const int rounded_k = rounded_rc ? rounded_run - 1 : -rounded_run;
        if (index >= 0) --index; // Drop terminator, if present.
        int rounded_e = 0;
        for (int i = 0; i < ES; ++i, --index)
            rounded_e = (rounded_e << 1) | (index >= 0 ? ((mag >> index) & 1) : 0);
        out.sf = rounded_k * useed_exp + rounded_e;
        out.frac = hidden;
        for (int target = 62; index >= 0; --index, --target)
            out.frac |= ((mag >> index) & 1) << target;
        return out;
    }
};

template <int NB, int ES>
inline posit_unpacked<NB, ES> round_unpacked(const posit_unpacked<NB, ES>& u,
                                           RoundMode mode = RoundMode::RNE) {
    return RoundUnpacked<NB, ES>::round(u, mode);
}

} // namespace l1

#endif // ROUND_UNPACKED_HPP
