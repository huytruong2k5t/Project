#pragma once
#include "posit_mac_full_term.hpp"
#include "week12_fused_reference.hpp"

// Independent raw decoder + closed-form selected-bit product + full-grid sum.
// No SAC recurrence, shared Parser, fixed window, L1 adder, or L1 packer here.
namespace opt17_reference {
using Oracle = week12_reference::Oracle<32,3>;
inline l1::PrepackProduct product(uint32_t a, uint32_t b, full_term32::Config cfg) {
    l1::PrepackProduct p;
    const unsigned width = cfg.approximate ? 12 : 26;
    p.fractional_bits = 2 * width;
    p.magnitude_bits = 2 * width + 2;
    p.is_nar = a == full_term32::NAR || b == full_term32::NAR;
    p.is_zero = !p.is_nar && (!a || !b);
    if (p.is_nar || p.is_zero) return p;
    const auto av = Oracle::decode(a), bv = Oracle::decode(b);
    const uint32_t mask = (1u << width) - 1;
    uint32_t fa = uint32_t(av.coefficient >> (26 - width)) & mask;
    uint32_t fb = uint32_t(bv.coefficient >> (26 - width)) & mask;
    p.sign = av.sign != bv.sign;
    p.scale = av.sf + bv.sf;
    p.input_cut = cfg.approximate && ((av.coefficient | bv.coefficient) & 16383u);
    // Independent compiler popcount, rather than the model's serial helper.
    if (cfg.ops && __builtin_popcount(fb) < __builtin_popcount(fa)) std::swap(fa,fb);
    uint32_t selected = 0;
    unsigned taken = 0;
    const unsigned limit = cfg.approximate ? cfg.n : 26;
    for (int bit = int(width)-1; bit >= 0; --bit) {
        if ((fa & (1u << bit)) && taken < limit) {
            selected |= 1u << bit;
            ++taken;
        }
    }
    p.magnitude = ((1ull << width) + selected) * ((1ull << width) + fb);
    p.iteration_cut = selected != fa;
    return p;
}
inline std::pair<uint32_t,unsigned> mac(uint32_t a, uint32_t b, uint32_t c,
                                      full_term32::Config cfg, bool fused) {
    auto p = product(a,b,cfg);
    if (p.is_nar || c == full_term32::NAR) return {full_term32::NAR,16};
    if (p.is_zero) return {c,0};
    unsigned flags = ((p.input_cut || p.iteration_cut) ? 2u : 0u) | (p.iteration_cut ? 1u : 0u);
    if (!fused) {
        const auto packed = Oracle::add(p,0,flags);
        const auto decoded = Oracle::decode(packed.bits);
        p.magnitude = decoded.coefficient;
        p.scale = decoded.sf;
        p.fractional_bits = 26;
        p.sign = decoded.sign;
        flags = packed.flags;
    }
    const auto sum = Oracle::add(p,c,flags);
    return {sum.bits,sum.flags};
}
inline full_term32::Result checked(uint32_t a, uint32_t b, uint32_t c,
                                   full_term32::Config cfg, bool fused) {
    const auto result = full_term32::mac(a,b,c,cfg,fused);
    const auto p = product(a,b,cfg);
    if (result.product.value.magnitude != p.magnitude || result.product.value.scale != p.scale
        || result.product.value.sign != p.sign || result.product.value.input_cut != p.input_cut
        || result.product.value.iteration_cut != p.iteration_cut)
        throw std::runtime_error("FULL_TERM recurrence vs independent selected-bit product");
    const auto reference = opt17_reference::mac(a,b,c,cfg,fused);
    if (result.bits != reference.first || result.flags != reference.second)
        throw std::runtime_error("FULL_TERM L1 vs independent full-grid d/flags");
    return result;
}
}
