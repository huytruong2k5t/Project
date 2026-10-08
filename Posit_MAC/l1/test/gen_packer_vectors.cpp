#include <algorithm>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <random>
#include <stdexcept>
#include <string>
#include <vector>
#include "posit_parser.hpp"
#include "posit_packer.hpp"

// Independent variable-length bit-list encoder: no wide buffer or barrel shift.
template<int NB, int ES, int FI>
uint32_t encode(bool sign, bool zero, bool nar, int sf, uint64_t frac,
                bool sticky, bool rne) {
    const uint32_t maxpos = uint32_t((uint64_t(1) << (NB - 1)) - 1);
    const uint32_t mask = uint32_t((uint64_t(1) << NB) - 1);
    const int limit = (NB - 2) * (1 << ES);
    if (nar) return uint32_t(1) << (NB - 1);
    if (zero) return 0;
    uint32_t mag;
    if (sf >= limit) mag = maxpos;
    else if (sf < -limit) mag = 1;
    else {
        const int unit = 1 << ES;
        int k = sf / unit;
        if (sf < 0 && sf % unit) --k;
        int exponent = sf - k * unit;
        std::vector<bool> bits;
        if (k >= 0) {
            bits.insert(bits.end(), k + 1, true);
            bits.push_back(false);
        } else {
            bits.insert(bits.end(), -k, false);
            bits.push_back(true);
        }
        for (int i = ES - 1; i >= 0; --i) bits.push_back((exponent >> i) & 1);
        for (int i = FI - 1; i >= 0; --i) bits.push_back((frac >> i) & 1);
        while (bits.size() < unsigned(NB + 1)) bits.push_back(false);
        mag = 0;
        for (int i = 0; i < NB - 1; ++i) mag = (mag << 1) | bits[i];
        bool tail = sticky;
        for (unsigned i = NB; i < bits.size(); ++i) tail |= bits[i];
        if (rne && bits[NB - 1] && ((mag & 1) || tail)) ++mag;
        mag = std::max(uint32_t(1), std::min(maxpos, mag));
    }
    return (sign ? 0u - mag : mag) & mask;
}

uint64_t total = 0;

template<int NB, int ES>
void generate(const std::string& directory) {
    constexpr int F = NB - 3 - ES;
    constexpr int FI = 2 * F + 1;
    constexpr int S = (NB - 2) * (1 << ES);
    constexpr int SW = []() {
        int v = 4 * S + 3, n = 0;
        while (v) { ++n; v >>= 1; }
        return n + 1;
    }();
    const uint64_t fm = (uint64_t(1) << FI) - 1;
    std::ofstream out(directory + "/packer_" + std::to_string(NB)
                      + "_" + std::to_string(ES) + ".txt");
    if (!out) throw std::runtime_error("cannot open fixtures");
    uint64_t rows = 0;
    auto emit = [&](bool sign, bool zero, bool nar, int sf, uint64_t frac,
                    bool sticky, uint8_t previous) {
        l1::posit_unpacked<NB, ES> u{};
        u.sign = sign;
        u.is_zero = zero;
        u.is_nar = nar || (previous & 16);
        u.sf = sf;
        u.frac = (uint64_t(1) << 63) | (frac << (63 - FI));
        u.exact = !sticky;
        uint32_t expected[2];
        unsigned flags[2];
        for (int mode = 0; mode < 2; ++mode) {
            bool rne = mode == 0;
            auto rounding = rne ? l1::RoundMode::RNE : l1::RoundMode::TRUNC;
            expected[mode] = l1::pack<NB, ES>(u, rounding);
            auto serial = encode<NB, ES, FI>(sign, zero, u.is_nar, sf,
                                             frac, sticky, rne);
            if (expected[mode] != serial) {
                throw std::runtime_error("L1/serial pack oracle mismatch");
            }
            flags[mode] = previous & 15;
            if (u.is_nar) flags[mode] = 16;
            else if (!zero) {
                auto decoded = l1::parse<NB, ES>(
                    static_cast<l1::posit_storage_t<NB>>(expected[mode]));
                bool high = sf > S || (sf == S && (frac || sticky));
                bool low = sf < -S;
                bool lost = sticky || decoded.sf != sf
                          || decoded.frac != u.frac || decoded.sign != sign;
                flags[mode] |= (high ? 8 : 0) | (low ? 4 : 0) | (lost ? 2 : 0);
            }
        }
        out << std::dec << sign << ' ' << zero << ' ' << nar << ' ' << sf
            << ' ' << std::hex << frac << ' ' << std::dec << sticky
            << ' ' << std::hex << unsigned(previous)
            << ' ' << expected[0] << ' ' << flags[0]
            << ' ' << expected[1] << ' ' << flags[1] << '\n';
        ++rows;
        ++total;
    };
    // Exhaustive p8/p16 identity; stratified p32 words are already accepted
    // parser fixtures, so read those instead of silently replacing the corpus.
    if constexpr (NB <= 16) {
        for (uint32_t p = 0; p < (uint32_t(1) << NB); ++p) {
            auto u = l1::parse<NB, ES>(static_cast<l1::posit_storage_t<NB>>(p));
            emit(u.sign, u.is_zero, u.is_nar, u.sf,
                 (u.frac >> (63 - FI)) & fm, false, 0);
        }
    } else {
        std::ifstream parser(directory + "/../parser_comb/parser_"
                             + std::to_string(NB) + "_" + std::to_string(ES) + ".txt");
        uint32_t p; unsigned sign, zero, nar; int sf; uint64_t f;
        uint64_t identity = 0;
        while (parser >> std::hex >> p >> std::dec >> sign >> zero >> nar >> sf
                      >> std::hex >> f) {
            emit(sign, zero, nar, sf, f << (FI - F), false, 0);
            ++identity;
        }
        if (identity != 1200010) throw std::runtime_error("missing p32 identity corpus");
    }
    // Full scale domain including exact boundaries, under/overflow, both signs,
    // sticky-only tails, incoming flags and fraction patterns.
    const uint64_t patterns[] = {0, fm, uint64_t(1) << (FI - 1), 1,
                                0xaaaaaaaaaaaaaaaaULL & fm, 0x5555555555555555ULL & fm};
    for (int sf = -(1 << (SW - 1)); sf < (1 << (SW - 1)); ++sf) {
        for (bool sign : {false, true}) for (bool sticky : {false, true}) {
            for (auto f : patterns) emit(sign, false, false, sf, f, sticky, 1);
        }
    }
    // Every available fraction precision in the central regime, ties-even/odd,
    // below/at/above midpoint, and carry from all-ones retained fraction.
    for (int sf = -S; sf < S; ++sf) {
        int k = sf / (1 << ES);
        if (sf < 0 && sf % (1 << ES)) --k;
        int run = k >= 0 ? k + 1 : -k;
        int available = NB - 1 - (run + 1) - ES;
        if (available < 0 || available >= FI) continue;
        int tail_bits = FI - available;
        uint64_t half = uint64_t(1) << (tail_bits - 1);
        uint64_t retained_mask = available ? (uint64_t(1) << available) - 1 : 0;
        for (uint64_t retained : {uint64_t(0), std::min(uint64_t(1), retained_mask), retained_mask}) {
            uint64_t base = retained << tail_bits;
            for (uint64_t tail : {half - 1, half, half + 1}) {
                if (base + tail > fm) continue;
                for (bool sign : {false, true}) for (bool sticky : {false, true}) {
                    emit(sign, false, false, sf, base + tail, sticky, 0);
                }
            }
        }
    }
    for (unsigned prior = 0; prior < 32; ++prior) {
        emit(true, true, true, 0, fm, true, prior);
        emit(true, true, false, 0, fm, true, prior);
        emit(true, false, false, 0, fm, true, prior);
    }
    std::mt19937_64 rng(20261006 + NB * 17 + ES);
    for (unsigned i = 0; i < 100000; ++i) {
        int sf = int(rng() % (2 * S + 17)) - S - 8;
        emit(rng() & 1, false, false, sf, rng() & fm, rng() & 1, rng() & 15);
    }
    out.close();
    if (!out) throw std::runtime_error("fixture write failure");
    std::cout << "PACKER FIXTURE NB=" << NB << " ES=" << ES
              << " rows=" << rows << " seed=20261006 L1_SERIAL_PASS\n";
}

int main(int argc, char** argv) {
    try {
        if (argc != 2) throw std::invalid_argument("usage: gen_packer_vectors OUTDIR");
        generate<8, 0>(argv[1]);
        generate<16, 1>(argv[1]);
        generate<32, 2>(argv[1]);
        generate<32, 3>(argv[1]);
        std::cout << "PACKER GENERATOR PASS rows=" << total << '\n';
    } catch (const std::exception& e) {
        std::cerr << e.what() << '\n';
        return 1;
    }
}
