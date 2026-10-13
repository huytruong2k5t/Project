#pragma once
#include "l1_multiplier_iter.hpp"
#include "posit_mac.hpp"
#include "week10_add_reference.hpp"
#include "week9_exact_reference.hpp"

// New comparison model; the frozen legacy L1 implementation is unchanged.
namespace week11 {
template<int NB, int ES> l1::posit_unpacked<NB, ES>
normalize(const l1::PrepackProduct& p) {
    if (p.is_nar || p.is_zero) {
        return l1::parse<NB, ES>(p.is_nar ? uint32_t(1) << (NB - 1) : 0);
    }
    unsigned top = 0;
    for (uint64_t value = p.magnitude; value >>= 1;) {
        ++top;
    }
    return {p.sign, false, false, p.scale + int(top) - int(p.fractional_bits),
            p.magnitude << (63 - top), !p.numerical_sticky};
}

// Independent serial bit-stream encoder of an exact dyadic prepack value.
// No L1 normalize, parser or packer is used here.
template<int NB, int ES> uint32_t dyadic(const l1::PrepackProduct& p) {
    const uint32_t nar = uint32_t(1) << (NB - 1);
    const uint32_t mask = uint32_t((uint64_t(1) << NB) - 1);
    if (p.is_nar) return nar;
    if (p.is_zero || !p.magnitude) return 0;
    int top = 0;
    for (uint64_t value = p.magnitude; value >>= 1;) ++top;
    const int scale = p.scale - int(p.fractional_bits) + top;
    const int limit = (NB - 2) * (1 << ES);
    uint32_t code;
    if (scale >= limit) code = nar - 1;
    else if (scale < -limit) code = 1;
    else {
        int k = scale / (1 << ES);
        if (scale < 0 && scale % (1 << ES)) --k;
        const int e = scale - k * (1 << ES);
        std::vector<bool> bits;
        bits.insert(bits.end(), k >= 0 ? k + 1 : -k, k >= 0);
        bits.push_back(k < 0);
        for (int i = ES - 1; i >= 0; --i) bits.push_back((e >> i) & 1);
        for (int i = top - 1; i >= 0; --i) bits.push_back((p.magnitude >> i) & 1);
        while (bits.size() < unsigned(NB + 1)) bits.push_back(false);
        code = 0;
        for (int i = 0; i < NB - 1; ++i) code = 2 * code + bits[unsigned(i)];
        bool tail = p.numerical_sticky;
        for (unsigned i = NB; i < bits.size(); ++i) tail |= bits[i];
        if (bits[NB - 1] && ((code & 1) || tail)) ++code;
        code = std::max(1u, std::min(nar - 1, code));
    }
    return (p.sign ? 0u - code : code) & mask;
}

template<int NB, int ES, unsigned FW> struct Model {
    static constexpr unsigned F = NB-3-ES;
    using T = l1::posit_storage_t<NB>;
    struct Result {
        uint32_t bits;
        unsigned flags;
        unsigned iterations;
        uint32_t product;
        l1::PrepackProduct prepack;
        bool finite_add = false;
        unsigned delta_bucket = 0;
        unsigned add_class = 0;
        bool same_sign = false;
    };
    static Result mac(T a, T b, T c, bool exact, unsigned n, unsigned ops) {
        constexpr uint32_t nar = uint32_t(1) << (NB - 1);
        if (a == nar || b == nar || c == nar) return {nar, 16, 0, nar, {}};
        if (!a || !b) return {uint32_t(c), 0, 0, 0, {}};
        l1::IterConfig config;
        config.exact = exact;
        config.n = n;
        config.ops = ops;
        config.scheme = l1::ShiftRound::FLOOR;
        config.rounding = l1::RoundMode::RNE;
        const auto m = l1::L1MultiplierIter<NB, ES, FW>::mul(a, b, config);
        const auto raw = normalize<NB, ES>(m.prepack);
        const auto product = l1::round_unpacked<NB, ES>(raw, l1::RoundMode::RNE);
        const uint32_t packed = uint32_t(l1::pack<NB, ES>(product));
        if (packed != dyadic<NB, ES>(m.prepack)) throw std::runtime_error("prepack oracle mismatch");
        const auto pf = l1::mac_round_flags(raw, product);
        unsigned flags = (pf.sat_max ? 8u : 0u) | (pf.sat_min ? 4u : 0u)
                       | ((pf.inexact || m.input_cut || m.approx_cut || m.prepack.term_cut) ? 2u : 0u)
                       | (m.approx_cut ? 1u : 0u);
        const auto sum = l1::l1_add_unpacked<NB, ES>(product, l1::parse<NB, ES>(c));
        const uint32_t output = uint32_t(l1::pack<NB, ES>(sum));
        const auto sf = l1::mac_round_flags(sum, l1::parse<NB, ES>(T(output)));
        flags |= (sf.sat_max ? 8u : 0u) | (sf.sat_min ? 4u : 0u) | (sf.inexact ? 2u : 0u);
        const auto independent = week10_reference::Adder<NB, ES>::add(packed, c, flags);
        if (output != independent.rne || flags != independent.flags_rne)
            throw std::runtime_error("NF sum oracle mismatch");
        if (exact && packed != exact_reference<NB, ES>(a, b))
            throw std::runtime_error("exact product oracle mismatch");
        const auto cu=l1::parse<NB,ES>(c);
        const unsigned delta=unsigned(std::abs(product.sf-cu.sf));
        const unsigned bucket=delta==0 ? 0 : delta==1 ? 1 : delta<=7 ? 2 : delta<=F ? 3 : 4;
        const int leading=std::max(product.sf,cu.sf)-sum.sf;
        const unsigned add_class=sum.is_zero ? 6 : leading<0 ? 0 : leading==0 ? 1
                               : leading==1 ? 2 : leading<=4 ? 3 : leading<=15 ? 4 : 5;
        return {output, flags, m.iterations, packed, m.prepack, !cu.is_zero,
                bucket, add_class, product.sign==cu.sign};
    }
};
}
