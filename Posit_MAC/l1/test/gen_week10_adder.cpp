#include <array>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <stdexcept>
#include "posit_mac.hpp"
#include "../../tb/week10_add_reference.hpp"
#include "../../l0/softposit_api.h"

namespace {
uint64_t rows = 0, oracle_checks = 0, l0_checks = 0;
void require(bool test, const char* message) {
    if (!test) {
        throw std::runtime_error(message);
    }
}
template<int NB, int ES>
void generate(const std::filesystem::path& folder, unsigned samples) {
    constexpr unsigned F = NB - 3 - ES;
    constexpr unsigned Q = F + 3;
    constexpr unsigned F_OUT = 2 * F + 1;
    constexpr uint32_t NAR = uint32_t(1) << (NB - 1);
    constexpr uint32_t MASK = uint32_t((uint64_t(1) << NB) - 1);
    constexpr uint32_t ONE = NAR / 2;
    using T = l1::posit_storage_t<NB>;
    std::ofstream out(folder / ("add_" + std::to_string(NB) + "_" + std::to_string(ES) + ".txt"));
    require(bool(out), "fixture open failed");
    std::mt19937_64 rng(20261012 + NB * 100 + ES);
    uint64_t count = 0, clamped = 0, carry = 0, cancellation = 0;
    uint64_t subtract_tail = 0, deep = 0, tie_even = 0, tie_odd = 0;
    auto emit = [&](uint32_t a, uint32_t b, unsigned incoming) {
        a &= MASK;
        b &= MASK;
        auto ua = l1::parse<NB, ES>(T(a));
        auto ub = l1::parse<NB, ES>(T(b));
        l1::AdderTrace trace;
        auto sum = l1::l1_add_unpacked<NB, ES>(ua, ub, &trace);
        const auto oracle = week10_reference::Adder<NB, ES>::add(a, b, incoming);
        const bool nar = ua.is_nar || ub.is_nar || (incoming & 16);
        const auto rne = nar ? T(NAR) : l1::pack<NB, ES>(sum, l1::RoundMode::RNE);
        const auto trunc = nar ? T(NAR) : l1::pack<NB, ES>(sum, l1::RoundMode::TRUNC);
        require(rne == oracle.rne && trunc == oracle.trunc, "L1 versus independent oracle");
        if constexpr (ES != 3) {
            uint32_t ref;
            if constexpr (NB == 8) {
                ref = l0_p8_add(uint8_t(a), uint8_t(b));
            } else if constexpr (NB == 16) {
                ref = l0_p16_add(uint16_t(a), uint16_t(b));
            } else {
                ref = l0_p32_add(a, b);
            }
            require(oracle.rne == ((incoming & 16) ? NAR : ref), "independent oracle versus L0");
            ++l0_checks;
        }
        auto flags = [&](T packed) {
            if (nar) {
                return 16u;
            }
            const auto f = l1::mac_round_flags(sum, l1::parse<NB, ES>(packed));
            return unsigned(incoming & 15) | f.bits();
        };
        require(flags(rne) == oracle.flags_rne && flags(trunc) == oracle.flags_trunc,
                "arithmetic flags versus independent oracle");
        oracle_checks += 2;
        uint64_t x = 0, y = 0;
        bool subtract = false, sign_base = nar, tail = false;
        int sf_base = 0;
        bool special_zero = !nar && ua.is_zero && ub.is_zero;
        if (!nar && !special_zero) {
            if (ua.is_zero || (!ub.is_zero &&
                (ua.sf < ub.sf || (ua.sf == ub.sf && ua.frac < ub.frac)))) {
                std::swap(ua, ub);
            }
            sign_base = ua.sign;
            sf_base = ua.sf;
            x = ua.frac >> (63 - Q);
            if (!ub.is_zero) {
                y = ub.frac >> (63 - Q);
                const unsigned delta = unsigned(ua.sf - ub.sf);
                if (delta > F + 2) {
                    y = 1;
                    tail = true;
                } else if (delta) {
                    tail = (y & ((uint64_t(1) << delta) - 1)) != 0;
                    y = (y >> delta) | uint64_t(tail);
                }
                subtract = ua.sign != ub.sign;
            }
        }
        const uint64_t magnitude = subtract ? x - y : x + y;
        const bool zero = !nar && sum.is_zero;
        const bool sign = nar || (!zero && sum.sign);
        const int sf = nar || zero ? 0 : sum.sf;
        const uint64_t fraction = nar || zero ? 0 :
            (sum.frac & ((uint64_t(1) << 63) - 1)) >> (63 - F_OUT);
        const bool sticky = !nar && !zero && !sum.exact;
        const unsigned aligned_flags = nar ? 16 : incoming & 15;
        const unsigned flags_out = nar ? 16 : aligned_flags | (sticky ? 2 : 0);
        out << std::hex << a << ' ' << b << ' ' << incoming << ' ' << x << ' ' << y
            << ' ' << subtract << ' ' << sign_base << std::dec << ' ' << sf_base
            << std::hex << ' ' << tail << ' ' << special_zero << ' ' << nar
            << ' ' << aligned_flags << ' ' << magnitude << ' ' << sign << ' ' << zero
            << ' ' << nar << std::dec << ' ' << sf << std::hex << ' ' << fraction
            << ' ' << sticky << ' ' << flags_out << ' ' << oracle.rne << ' ' << oracle.flags_rne
            << ' ' << oracle.trunc << ' ' << oracle.flags_trunc << '\n';
        ++count;
        ++rows;
        clamped += trace.clamped;
        carry += trace.carry;
        cancellation += trace.cancellation_zero;
        subtract_tail += trace.subtract && trace.alignment_tail;
        deep += trace.left_shift > 3;
        if (!nar && trace.guard && !trace.round && !trace.sticky) {
            const bool even = (uint32_t(trunc) & 1) == 0;
            tie_even += even;
            tie_odd += !even;
        }
    };
    const uint32_t corners[] = {0, 1, 2, NAR - 2, NAR - 1, NAR, NAR + 1,
                                MASK, ONE - 1, ONE, ONE + 1, (0u - ONE) & MASK};
    for (uint32_t a : corners) {
        for (uint32_t b : corners) {
            for (unsigned flags = 0; flags < 32; ++flags) {
                emit(a, b, flags);
            }
        }
    }
    l1::posit_unpacked<NB, ES> small{false, false, false, -int(F) - 1,
                                           uint64_t(1) << 63, true};
    const uint32_t half = l1::pack<NB, ES>(small);
    emit(ONE, half, 0);
    emit(ONE + 1, half, 0);
    if constexpr (NB == 8) {
        for (unsigned a = 0; a < 256; ++a) {
            for (unsigned b = 0; b < 256; ++b) {
                emit(a, b, 0);
            }
        }
    } else {
        for (unsigned i = 0; i < samples; ++i) {
            uint32_t a = uint32_t(rng()) & MASK;
            uint32_t b = uint32_t(rng()) & MASK;
            if (i % 5 < 2) {
                const uint32_t mag = (a & (NAR - 1)) ? a & (NAR - 1) : 1;
                const uint32_t next = std::min(NAR - 1, mag + (i & 15));
                a = (i & 1) ? mag : (0u - mag) & MASK;
                b = (i & 1) ? (0u - next) & MASK : next;
            } else if (i % 5 == 2) {
                a = corners[(i / 5) % 12];
            }
            emit(a, b, 0);
        }
    }
    out.close();
    require(clamped && carry && cancellation && subtract_tail && deep && tie_even && tie_odd,
            "required pilot branches missing");
    std::cout << "PROFILE " << NB << '/' << ES << " PASS rows=" << count
              << " clamp=" << clamped << " carry=" << carry << " cancellation=" << cancellation
              << " subtract_tail=" << subtract_tail << " deep=" << deep
              << " tie_even=" << tie_even << " tie_odd=" << tie_odd << '\n';
}
}
int main(int argc, char** argv) try {
    if (argc != 3) {
        throw std::invalid_argument("usage: gen_week10_adder output_directory samples_per_non_p8_format");
    }
    const std::filesystem::path folder = argv[1];
    const unsigned samples = unsigned(std::stoul(argv[2]));
    if (samples < 1000) {
        throw std::invalid_argument("pilot requires at least 1000 samples");
    }
    std::filesystem::create_directories(folder);
    generate<8, 0>(folder, samples);
    generate<16, 1>(folder, samples);
    generate<32, 2>(folder, samples);
    generate<32, 3>(folder, samples);
    std::cout << "W10 GENERATOR PASS rows=" << rows << " independent_mode_checks=" << oracle_checks
              << " L0_RNE_checks=" << l0_checks << " seed_base=20261012 mismatches=0\n";
    return 0;
} catch (const std::exception& error) {
    std::cerr << "FAIL: " << error.what() << '\n';
    return 1;
}
