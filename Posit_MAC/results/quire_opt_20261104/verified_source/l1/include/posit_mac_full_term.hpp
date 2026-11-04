#pragma once
#include <cstdint>
#include <stdexcept>
#include "posit_mac.hpp"
#include "posit_fused_window.hpp"

// Separate FULL_TERM32/3 model. The frozen FLOOR implementation is unchanged.
namespace full_term32 {
constexpr uint32_t NAR = 0x80000000u;
struct Config {
    bool approximate = true;
    unsigned n = 12;
    unsigned ops = 1;
};
struct Product {
    l1::PrepackProduct value{};
    unsigned iterations = 0;
    uint64_t checkpoints[26]{};
};
struct Result {
    uint32_t bits = 0;
    unsigned flags = 0;
    Product product{};
};
inline unsigned popcount(uint32_t x) {
    unsigned count = 0;
    while (x) { count += x & 1u; x >>= 1; }
    return count;
}
inline unsigned highest(uint64_t x) {
    if (!x) throw std::invalid_argument("highest zero");
    unsigned h = 0;
    while (x >>= 1) ++h;
    return h;
}
inline Product multiply(uint32_t a, uint32_t b, Config cfg) {
    if (cfg.ops > 1 || (cfg.approximate && cfg.n > 12))
        throw std::invalid_argument("FULL_TERM config");
    Product result;
    auto& p = result.value;
    const unsigned width = cfg.approximate ? 12 : 26;
    p.fractional_bits = 2 * width;
    p.magnitude_bits = 2 * width + 2;
    p.is_nar = a == NAR || b == NAR;
    p.is_zero = !p.is_nar && (!a || !b);
    if (p.is_nar || p.is_zero) return result;
    const auto av = l1::parse<32,3>(a);
    const auto bv = l1::parse<32,3>(b);
    p.sign = av.sign != bv.sign;
    p.scale = av.sf + bv.sf;
    const uint32_t fa = uint32_t((av.frac >> (63 - width)) & ((1ull << width) - 1));
    const uint32_t fb = uint32_t((bv.frac >> (63 - width)) & ((1ull << width) - 1));
    if (cfg.approximate) {
        const uint64_t discarded = (1ull << (63 - width)) - 1;
        p.input_cut = ((av.frac | bv.frac) & discarded) != 0;
    }
    const bool swap = cfg.ops == 1 && popcount(fb) < popcount(fa);
    uint32_t fx = swap ? fb : fa;
    const uint64_t y = (1ull << width) | (swap ? fa : fb);
    const uint64_t base = y << width;
    p.magnitude = base;
    const unsigned limit = cfg.approximate ? cfg.n : 26;
    unsigned scale = 0;
    while (fx && result.iterations < limit) {
        unsigned sa = 1;
        while (!(fx & (1u << (width - sa)))) ++sa;
        scale += sa;
        fx = uint32_t((uint64_t(fx) << sa) & ((1ull << width) - 1));
        if (scale > width || (base & ((1ull << scale) - 1)))
            throw std::logic_error("FULL_TERM discarded numerical bit");
        p.magnitude += base >> scale;
        result.checkpoints[result.iterations++] = p.magnitude;
    }
    p.iteration_cut = fx != 0;
    if (p.magnitude >= (1ull << p.magnitude_bits))
        throw std::overflow_error("FULL_TERM accumulator");
    return result;
}
inline l1::posit_unpacked<32,3> unpack(const l1::PrepackProduct& p) {
    l1::posit_unpacked<32,3> u{};
    u.sign = p.sign;
    u.is_zero = p.is_zero;
    u.is_nar = p.is_nar;
    u.exact = true;
    if (!u.is_zero && !u.is_nar) {
        const unsigned h = highest(p.magnitude);
        u.sf = p.scale + int(h) - int(p.fractional_bits);
        u.frac = p.magnitude << (63 - h);
    }
    return u;
}
inline Result mac(uint32_t a, uint32_t b, uint32_t c, Config cfg, bool fused) {
    if (fused && !cfg.approximate) throw std::invalid_argument("exact fused unsupported");
    Result out;
    out.product = multiply(a,b,cfg);
    if (out.product.value.is_nar || c == NAR) {
        out.bits = NAR; out.flags = 16; return out;
    }
    if (out.product.value.is_zero) { out.bits = c; return out; }
    if (fused) {
        // This add() accepts a dyadic prepack with Q24; no FLOOR multiply is used.
        const auto w = l1::FusedWindow<32,3,24,32>::add(out.product.value,c);
        out.bits = w.bits; out.flags = w.flags; return out;
    }
    const auto raw = unpack(out.product.value);
    const uint32_t rounded = l1::pack<32,3>(raw,l1::RoundMode::RNE);
    const auto product = l1::parse<32,3>(rounded);
    const auto pf = l1::mac_round_flags(raw,product);
    out.flags = (pf.sat_max ? 8u : 0u) | (pf.sat_min ? 4u : 0u)
              | ((pf.inexact || out.product.value.input_cut || out.product.value.iteration_cut) ? 2u : 0u)
              | (out.product.value.iteration_cut ? 1u : 0u);
    const auto sum = l1::l1_add_unpacked<32,3>(product,l1::parse<32,3>(c));
    out.bits = l1::pack<32,3>(sum,l1::RoundMode::RNE);
    const auto sf = l1::mac_round_flags(sum,l1::parse<32,3>(out.bits));
    out.flags |= (sf.sat_max ? 8u : 0u) | (sf.sat_min ? 4u : 0u) | (sf.inexact ? 2u : 0u);
    return out;
}
}
