#pragma once
#include <array>
#include <cstdint>
#include <stdexcept>
namespace l1 {
struct PaperOpsFormat {
    static constexpr unsigned FP32_FRACTION = 23;
    static constexpr unsigned KEPT_FRACTION = 12;
    static constexpr unsigned TRUNCATED_FRACTION = 11;
    static constexpr unsigned PREDICTION_FRACTION = 7;
    static constexpr unsigned PREDICTION_N = 2;
};
// Reconstructed predictor, independent of the requested multiplication n.
// Seven-bit complement and tie-A are explicit local reconstruction choices.
inline unsigned paper_prediction_error(unsigned fraction7) {
    if (fraction7 > 127) throw std::invalid_argument("prediction fraction");
    unsigned mantissa = 128 + fraction7;
    int exponent = 0, sign = 1, approximation = 0;
    for (unsigned i = 0; i < PaperOpsFormat::PREDICTION_N && mantissa; ++i) {
        bool up = mantissa >= 192;
        approximation += sign * (1 << (7 + exponent + int(up)));
        unsigned residual = up ? 255 - mantissa : mantissa - 128;
        if (up) sign = -sign;
        if (!residual) break;
        while (residual < 128) { residual *= 2; --exponent; }
        mantissa = residual;
    }
    int error = int(128 + fraction7) - approximation;
    return unsigned(error < 0 ? -error : error);
}
inline const std::array<unsigned, 128>& paper_prediction_lut() {
    static const auto table = [] {
        std::array<unsigned, 128> t{};
        for (unsigned i = 0; i < 128; ++i) t[i] = paper_prediction_error(i);
        return t;
    }();
    return table;
}
// Source-informed reconstruction: seven-bit prefix is zero-extended to Q12.
// Published patterns do not specify a complete n=2 LUT or tie handling.
inline unsigned paper_pattern_prediction_error(unsigned fraction7) {
    if(fraction7>127) throw std::invalid_argument("prediction fraction");
    unsigned m=(128+fraction7)<<5;
    bool up=m>=6144;
    unsigned first=up?8192:4096;
    unsigned residue=up?8191-m:m-4096;
    unsigned second=0;
    if(residue) {
        unsigned leading=0;for(unsigned t=residue;t>>=1;) ++leading;
        second=1u<<leading;
        if(leading && residue>=3u<<(leading-1)) second<<=1;
    }
    int prediction=int(first)+(up?-int(second):int(second));
    int error=int(m)-prediction;
    return unsigned(error<0?-error:error);
}
inline const std::array<unsigned,128>& paper_pattern_prediction_lut() {
    static const auto table=[] {
        std::array<unsigned,128> t{};
        for(unsigned i=0;i<128;++i) t[i]=paper_pattern_prediction_error(i);
        return t;
    }();
    return table;
}
struct PaperOpsSelection {
    unsigned index_a, index_b, error_a, error_b;
    bool swapped, tie;
};
template<unsigned W = 12>
inline PaperOpsSelection paper_ops_select(uint32_t fraction_a, uint32_t fraction_b) {
    static_assert(W >= 7 && W <= 27, "OPS fraction width");
    if ((fraction_a | fraction_b) >= (uint32_t(1) << W))
        throw std::invalid_argument("OPS fraction out of range");
    unsigned a = fraction_a >> (W - 7), b = fraction_b >> (W - 7);
    const auto& lut = paper_prediction_lut();
    return {a, b, lut[a], lut[b], lut[b] < lut[a], lut[a] == lut[b]};
}
template<unsigned W=12>
inline PaperOpsSelection paper_ops_select_pattern(uint32_t fraction_a,uint32_t fraction_b) {
    auto s=paper_ops_select<W>(fraction_a,fraction_b);
    s.error_a=paper_pattern_prediction_lut()[s.index_a];
    s.error_b=paper_pattern_prediction_lut()[s.index_b];
    s.swapped=s.error_b<s.error_a;s.tie=s.error_b==s.error_a;
    return s;
}
// Research improvement: compare E/M on the same seven-bit mantissa proxy.
// No division and no change to the reconstructed n=2 prediction table.
template<unsigned W = 12>
inline PaperOpsSelection paper_ops_select_relative(uint32_t fraction_a, uint32_t fraction_b) {
    auto s=paper_ops_select<W>(fraction_a,fraction_b);
    unsigned a=s.error_a*(128+s.index_b),b=s.error_b*(128+s.index_a);
    s.swapped=b<a;s.tie=a==b; // equal rational scores retain A
    return s;
}
enum class PaperFp32Class { Normal, Zero, Subnormal, Infinity, NaN };
struct PaperFp32Input {
    uint32_t original_bits, truncated_bits;
    uint16_t fraction12;
    uint8_t prediction7;
    PaperFp32Class classification;
};
inline PaperFp32Input paper_prepare_fp32(uint32_t bits) {
    unsigned exponent = (bits >> 23) & 255;
    unsigned fraction = bits & 0x7fffff;
    auto kind = exponent == 0 ? (fraction ? PaperFp32Class::Subnormal : PaperFp32Class::Zero) :
                exponent == 255 ? (fraction ? PaperFp32Class::NaN : PaperFp32Class::Infinity) :
                PaperFp32Class::Normal;
    // Preserve special payloads; normalized-mantissa OPS bypasses these cases.
    uint32_t truncated = kind == PaperFp32Class::Normal ? bits & ~uint32_t(0x7ff) : bits;
    return {bits, truncated, uint16_t(fraction >> 11), uint8_t(fraction >> 16), kind};
}
struct PaperFp32OpsResult {
    PaperFp32Input a, b;
    PaperOpsSelection selection{};
    bool bypass;
};
inline PaperFp32OpsResult paper_ops_fp32(uint32_t a, uint32_t b) {
    auto ua = paper_prepare_fp32(a), ub = paper_prepare_fp32(b);
    bool bypass = ua.classification != PaperFp32Class::Normal || ub.classification != PaperFp32Class::Normal;
    return {ua, ub, bypass ? PaperOpsSelection{} : paper_ops_select(ua.fraction12, ub.fraction12), bypass};
}
}
