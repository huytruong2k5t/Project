#ifndef POSIT_PARSER_HPP
#define POSIT_PARSER_HPP

#include "posit_types.hpp"

namespace l1 {

template <int NB, int ES> class PositParser {
public:
  using storage_t = posit_storage_t<NB>;

  static posit_unpacked<NB, ES> parse(storage_t p) {
    posit_unpacked<NB, ES> u{};
    u.exact = true;

    // 1. Identify Special Values
    if (p == 0) {
      u.is_zero = true;

      u.is_nar = false;
      u.sign = false;
      u.sf = 0;
      u.frac = 0;
      return u;
    }

    storage_t nar_val = static_cast<storage_t>(1ULL << (NB - 1));
    if (p == nar_val) {
      u.is_zero = false;
      u.is_nar = true;
      u.sign = true;
      u.sf = 0;
      u.frac = 0;
      return u;
    }

    u.is_zero = false;
    u.is_nar = false;

    // 2. Extract sign and compute two's complement magnitude
    u.sign = ((p >> (NB - 1)) & 1) != 0;
    storage_t t1 = u.sign ? static_cast<storage_t>(-p) : p;

    // 3. Extract first regime bit and count consecutive matching bits in
    // t1[NB-3:0]
    int r = (t1 >> (NB - 2)) & 1;
    storage_t t1_rest = t1 & static_cast<storage_t>((1ULL << (NB - 2)) - 1);

    int cnt = 0;
    for (int i = NB - 3; i >= 0; --i) {
      if (static_cast<int>((t1 >> i) & 1) == r) {
        cnt++;
      } else {
        break;
      }
    }

    // 4. Compute regime value k
    // If r == 1: k = cnt; if r == 0: k = -(cnt + 1)
    int32_t k = (r == 1) ? cnt : -(cnt + 1);

    // 5. Shift left by cnt to align at terminating bit
    storage_t mask_rest = static_cast<storage_t>((1ULL << (NB - 2)) - 1);
    storage_t t2 = static_cast<storage_t>(
        (static_cast<uint64_t>(t1_rest) << cnt) & mask_rest);

    // 6. Terminating bit is at bit NB-3. Shift 1 more bit to drop terminating
    // bit If cnt == NB - 2, there was no terminating bit (maximum regime)
    storage_t t_payload = 0;
    if (cnt < NB - 2) {
      t_payload =
          static_cast<storage_t>((static_cast<uint64_t>(t2) << 1) & mask_rest);
    }

    // 7. Extract Exponent e
    int32_t e = 0;
    storage_t f_bits = 0;
    if constexpr (ES > 0) {
      if (cnt < NB - 2) {
        e = static_cast<int32_t>(
            (static_cast<uint64_t>(t_payload) >> (NB - 2 - ES)) &
            ((1ULL << ES) - 1));
        f_bits = static_cast<storage_t>(
            (static_cast<uint64_t>(t_payload) << ES) & mask_rest);
      }
    } else {
      f_bits = t_payload;
    }

    // 8. Scale Factor
    u.sf = k * (int32_t(1) << ES) + e;

    // 9. Mantissa with hidden bit at bit 63
    // f_bits has MSB at bit (NB - 3)
    uint64_t frac_aligned = static_cast<uint64_t>(f_bits) << (62 - (NB - 3));
    u.frac = (1ULL << 63) | frac_aligned;

    return u;
  }
};

template <int NB, int ES>
inline posit_unpacked<NB, ES> parse(posit_storage_t<NB> p) {
  return PositParser<NB, ES>::parse(p);
}

} // namespace l1

#endif // POSIT_PARSER_HPP
