#ifndef L1_MULTIPLIER_EXACT_HPP
#define L1_MULTIPLIER_EXACT_HPP

#include "posit_types.hpp"
#include "posit_parser.hpp"
#include "posit_packer.hpp"

namespace l1 {

template <int NB, int ES>
class L1MultiplierExact {
public:
    using storage_t = posit_storage_t<NB>;

    static storage_t mul(storage_t a, storage_t b, RoundMode mode = RoundMode::RNE) {
        auto uA = parse<NB, ES>(a);
        auto uB = parse<NB, ES>(b);

        // 1. Zero & NaR Bypass (§5.3)
        if (uA.is_nar || uB.is_nar) {
            return static_cast<storage_t>(1ULL << (NB - 1));
        }
        if (uA.is_zero || uB.is_zero) {
            return static_cast<storage_t>(0);
        }

        // 2. Sign and Scale Factor addition (§5.4)
        bool sign_prod = uA.sign ^ uB.sign;
        int32_t sf_prod = uA.sf + uB.sf;

        // 3. Exact 128-bit Mantissa Multiplication
        using uint128_t = unsigned __int128;
        uint128_t prod = static_cast<uint128_t>(uA.frac) * static_cast<uint128_t>(uB.frac);

        // 4. Normalization (§5.7 mul_norm)
        // uA.frac has bit 63 as hidden bit (val in [1.0, 2.0))
        // prod has bit 127 or 126 as MSB (val in [1.0, 4.0))
        uint64_t frac_prod = 0;
        bool exact = true;

        if ((prod >> 127) & 1) {
            // Product in [2.0, 4.0) -> normalize by right shift 1 and increment sf
            sf_prod++;
            frac_prod = static_cast<uint64_t>(prod >> 64);
            exact = ((prod & 0xFFFFFFFFFFFFFFFFULL) == 0);
        } else {
            // Product in [1.0, 2.0) -> bit 126 is hidden bit
            frac_prod = static_cast<uint64_t>(prod >> 63);
            exact = ((prod & 0x7FFFFFFFFFFFFFFFULL) == 0);
        }

        // 5. Construct unpacked result
        posit_unpacked<NB, ES> uP{};
        uP.sign = sign_prod;
        uP.is_zero = false;
        uP.is_nar = false;
        uP.sf = sf_prod;
        uP.frac = frac_prod;
        uP.exact = exact;

        // 6. Round and Pack
        return pack<NB, ES>(uP, mode);
    }

    // Helper returning unpacked result for MAC v1
    static posit_unpacked<NB, ES> mul_unpacked(storage_t a, storage_t b) {
        auto uA = parse<NB, ES>(a);
        auto uB = parse<NB, ES>(b);

        posit_unpacked<NB, ES> uP{};
        if (uA.is_nar || uB.is_nar) {
            uP.is_nar = true;
            uP.sign = true;
            return uP;
        }
        if (uA.is_zero || uB.is_zero) {
            uP.is_zero = true;
            return uP;
        }

        uP.sign = uA.sign ^ uB.sign;
        uP.sf = uA.sf + uB.sf;

        using uint128_t = unsigned __int128;
        uint128_t prod = static_cast<uint128_t>(uA.frac) * static_cast<uint128_t>(uB.frac);

        if ((prod >> 127) & 1) {
            uP.sf++;
            uP.frac = static_cast<uint64_t>(prod >> 64);
            uP.exact = ((prod & 0xFFFFFFFFFFFFFFFFULL) == 0);
        } else {
            uP.frac = static_cast<uint64_t>(prod >> 63);
            uP.exact = ((prod & 0x7FFFFFFFFFFFFFFFULL) == 0);
        }

        return uP;
    }
};

template <int NB, int ES>
inline posit_storage_t<NB> l1_mul(posit_storage_t<NB> a, posit_storage_t<NB> b, RoundMode mode = RoundMode::RNE) {
    return L1MultiplierExact<NB, ES>::mul(a, b, mode);
}

} // namespace l1

#endif // L1_MULTIPLIER_EXACT_HPP
