#include <iostream>
#include <iomanip>
#include <cstdint>
#include <random>
#include "../include/posit_types.hpp"
#include "../include/posit_parser.hpp"
#include "../include/posit_packer.hpp"

using namespace l1;

template <int NB, int ES>
bool test_exhaustive(const char* name) {
    using storage_t = posit_storage_t<NB>;
    uint64_t total = 1ULL << NB;
    uint64_t pass = 0;
    uint64_t fail = 0;

    std::cout << "[TEST] Exhaustive Identity for " << name << " (NB=" << NB << ", ES=" << ES << "): " << total << " patterns..." << std::endl;

    for (uint64_t i = 0; i < total; ++i) {
        storage_t p_in = static_cast<storage_t>(i);
        auto u = parse<NB, ES>(p_in);
        storage_t p_out = pack<NB, ES>(u, RoundMode::RNE);

        if (p_out == p_in) {
            pass++;
        } else {
            fail++;
            if (fail <= 10) {
                std::cout << "  Mismatch at 0x" << std::hex << static_cast<uint64_t>(p_in)
                          << " -> got 0x" << static_cast<uint64_t>(p_out)
                          << " (sign=" << u.sign << ", sf=" << std::dec << u.sf
                          << ", frac=0x" << std::hex << u.frac << ")" << std::endl;
            }
        }
    }

    if (fail == 0) {
        std::cout << "  [PASS] " << name << ": " << pass << "/" << total << " (100% Bit-Exact Match)" << std::endl;
        return true;
    } else {
        std::cout << "  [FAIL] " << name << ": " << fail << " mismatches out of " << total << std::endl;
        return false;
    }
}

bool test_posit32_sampled(uint64_t num_samples = 1000000) {
    std::cout << "[TEST] Posit32 Identity Verification (" << num_samples << " stratified/random samples + corners)..." << std::endl;
    
    // 1. Mandatory Corners (§6.4)
    uint32_t corners[] = {
        0x00000000, // zero
        0x80000000, // NaR
        0x40000000, // +1.0
        0xC0000000, // -1.0
        0x00000001, // minpos
        0xFFFFFFFF, // -minpos
        0x7FFFFFFF, // maxpos
        0x80000001, // -maxpos
        0x48000000, // +2.0
        0x38000000, // +0.5
        0x7FFE0000, // high regime
        0x00020000  // low regime
    };

    uint64_t pass = 0, fail = 0;
    for (uint32_t c : corners) {
        auto u = parse<32, 2>(c);
        uint32_t out = pack<32, 2>(u, RoundMode::RNE);
        if (out == c) {
            pass++;
        } else {
            fail++;
            std::cout << "  Mismatch on corner 0x" << std::hex << c << " -> got 0x" << out << std::dec << std::endl;
        }
    }

    // 2. Random sampling
    std::mt19937_64 rng(1337);
    for (uint64_t i = 0; i < num_samples; ++i) {
        uint32_t p_in = static_cast<uint32_t>(rng());
        auto u = parse<32, 2>(p_in);
        uint32_t out = pack<32, 2>(u, RoundMode::RNE);
        if (out == p_in) {
            pass++;
        } else {
            fail++;
            if (fail <= 10) {
                std::cout << "  Mismatch at sample 0x" << std::hex << p_in << " -> got 0x" << out << std::dec << std::endl;
            }
        }
    }

    uint64_t total = pass + fail;
    if (fail == 0) {
        std::cout << "  [PASS] Posit32: " << pass << "/" << total << " (100% Bit-Exact Match)" << std::endl;
        return true;
    } else {
        std::cout << "  [FAIL] Posit32: " << fail << " mismatches out of " << total << std::endl;
        return false;
    }
}

int main() {
    std::cout << "============================================================" << std::endl;
    std::cout << "  L1 Roundtrip Identity Verification: pack(parse(p)) == p" << std::endl;
    std::cout << "============================================================" << std::endl;

    bool ok_p8 = test_exhaustive<8, 0>("Posit8 (ES=0)");
    bool ok_p16 = test_exhaustive<16, 1>("Posit16 (ES=1)");
    bool ok_p32 = test_posit32_sampled(1000000);

    std::cout << "============================================================" << std::endl;
    if (ok_p8 && ok_p16 && ok_p32) {
        std::cout << "  ALL ROUNDTRIP IDENTITY TESTS PASSED (0 Mismatch)!" << std::endl;
        std::cout << "============================================================" << std::endl;
        return 0;
    } else {
        std::cout << "  SOME TESTS FAILED!" << std::endl;
        std::cout << "============================================================" << std::endl;
        return 1;
    }
}
