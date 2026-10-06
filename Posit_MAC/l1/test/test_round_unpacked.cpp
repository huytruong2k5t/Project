#include <array>
#include <cstdint>
#include <iostream>
#include <limits>
#include <random>
#include "../include/round_unpacked.hpp"
#include "../include/posit_parser.hpp"
#include "../include/posit_packer.hpp"
#include "../include/l1_multiplier_exact.hpp"
#include "../../l0/softposit_api.h"

using namespace l1;
constexpr uint64_t hidden = uint64_t(1) << 63;
constexpr uint64_t seed = 20261003;
uint64_t checks = 0, failures = 0, scale_changes = 0;

template<int NB, int ES>
bool equal(const posit_unpacked<NB,ES>& a, const posit_unpacked<NB,ES>& b) {
    return a.sign == b.sign && a.is_zero == b.is_zero && a.is_nar == b.is_nar &&
           a.sf == b.sf && a.frac == b.frac && a.exact == b.exact;
}

template<int NB, int ES>
void check(const posit_unpacked<NB,ES>& u, RoundMode mode, const char* kind) {
    auto expected = parse<NB,ES>(pack<NB,ES>(u,mode));
    auto actual = round_unpacked<NB,ES>(u,mode);
    ++checks;
    scale_changes += !actual.is_zero && !actual.is_nar && actual.sf != u.sf;
    if (!equal(actual,expected) ||
        !equal(round_unpacked<NB,ES>(actual,mode),actual)) {
        if (++failures <= 12)
            std::cout << "FAIL " << kind << " NB=" << NB << " ES=" << ES
                      << " mode=" << int(mode) << " sign=" << u.sign
                      << " sf=" << u.sf << " frac=" << std::hex << u.frac
                      << std::dec << " exact=" << u.exact << " got_sf=" << actual.sf
                      << " expected_sf=" << expected.sf << '\n';
    }
}

template<int NB, int ES>
void modes(posit_unpacked<NB,ES> u, const char* kind) {
    for (bool sign : {false,true}) for (bool exact : {false,true}) {
        u.sign=sign; u.exact=exact;
        check(u,RoundMode::RNE,kind);
        check(u,RoundMode::TRUNC,kind);
    }
}

template<int NB,int ES>
void grid() {
    for (uint32_t p=0; p < (uint32_t(1)<<NB); ++p) {
        auto u=parse<NB,ES>(posit_storage_t<NB>(p));
        check(u,RoundMode::RNE,"grid");
        check(u,RoundMode::TRUNC,"grid");
    }
}

template<int NB,int ES>
void boundaries() {
    constexpr int sfmax=posit_constants<NB,ES>::SF_MAX;
    posit_unpacked<NB,ES> u{};
    for (int sf=-sfmax-2; sf<=sfmax+2; ++sf) {
        u.sf=sf;
        for (uint64_t f : {hidden,hidden+1,~uint64_t(0),uint64_t(0xaaaaaaaaaaaaaaaa),
                           uint64_t(0xd555555555555555)}) {
            u.frac=f; modes(u,"scale/pattern");
        }
        // Both sides of every possible mantissa cut and carry threshold.
        for (int bit=0; bit<63; ++bit) {
            uint64_t delta=uint64_t(1)<<bit;
            for (uint64_t f : {hidden+delta-1,hidden+delta,hidden+delta+1,
                               uint64_t(0)-delta-1,uint64_t(0)-delta}) {
                u.frac=f; modes(u,"tie/carry");
            }
        }
    }
    for (int sf : {std::numeric_limits<int32_t>::min(),std::numeric_limits<int32_t>::max()}) {
        u.sf=sf;u.frac=~uint64_t(0);modes(u,"extreme-scale");
    }
    // Dirty payloads and overlapping flags must canonicalize like the oracle.
    for (bool zero : {false,true}) for (bool nar : {false,true})
        for (uint64_t f : {uint64_t(0),hidden,~uint64_t(0)}) {
            u={};u.sf=17;u.is_zero=zero;u.is_nar=nar;u.frac=f;
            modes(u,"special");
        }
}

template<int NB,int ES>
void random_unpacked(uint64_t count) {
    std::mt19937_64 rng(seed+NB*16+ES);
    constexpr int sfmax=posit_constants<NB,ES>::SF_MAX;
    for (uint64_t i=0;i<count;++i) {
        posit_unpacked<NB,ES> u{};
        u.sign=rng()&1;u.exact=rng()&1;
        u.sf=int(rng()%(4*sfmax+1))-2*sfmax;
        u.frac=rng()|hidden;
        check(u,RoundMode::RNE,"random");
        check(u,RoundMode::TRUNC,"random");
    }
}

template<int NB,int ES,typename Oracle>
void products(uint64_t count, bool exhaustive, Oracle oracle) {
    std::mt19937_64 rng(seed+NB);
    for (uint64_t i=0;i<count;++i) {
        auto a=posit_storage_t<NB>(exhaustive ? i>>8 : rng());
        auto b=posit_storage_t<NB>(exhaustive ? i&255 : rng());
        auto u=L1MultiplierExact<NB,ES>::mul_unpacked(a,b);
        check(u,RoundMode::RNE,"product");check(u,RoundMode::TRUNC,"product");
        auto rounded=round_unpacked<NB,ES>(u);
        ++checks;
        if (pack<NB,ES>(rounded)!=oracle(a,b)) {
            if (++failures<=12) std::cout << "FAIL SoftPosit product NB=" << NB << '\n';
        }
    }
}

void p8_known_ties() {
    for (bool sign : {false,true}) for (int n : {1,3}) {
        posit_unpacked<8,0> u{};u.sign=sign;u.frac=hidden+(uint64_t(n)<<57);u.exact=true;
        uint8_t expected=n==1?0x40:0x42;
        if(sign) expected=uint8_t(0-expected);
        ++checks;
        if(pack<8,0>(round_unpacked<8,0>(u))!=expected) ++failures;
    }
}

void missing_exponent() {
    // The exponent is entirely outside the retained payload at this scale.
    // Exact halfway keeps even 0x7ffe; an external sticky tail rounds to maxpos.
    for (bool sign : {false,true}) for (bool exact : {false,true}) {
        posit_unpacked<16,1> u{};u.sign=sign;u.sf=27;u.frac=hidden;u.exact=exact;
        auto actual=round_unpacked<16,1>(u);
        ++checks;
        if (actual.sf!=(exact?26:28) || actual.frac!=hidden || actual.sign!=sign)
            ++failures;
    }
}

int main() {
    std::cout << "ROUND_UNPACKED contract: all six fields + idempotence; RNE/TRUNC; seed=" << seed << '\n';
    p8_known_ties();missing_exponent();grid<8,0>();grid<16,1>();
    boundaries<8,0>();boundaries<16,1>();boundaries<32,2>();boundaries<32,3>();
    // Sweep 12 fractional source bits, every in-range/adjacent p8 scale,
    // both signs, modes and states of the external sticky flag.
    for(int sf=-8;sf<=8;++sf) for(uint64_t f=0;f<4096;++f) {
        posit_unpacked<8,0> u{};u.sf=sf;u.frac=hidden+(f<<51);modes(u,"p8-dense");
    }
    random_unpacked<8,0>(100000);random_unpacked<16,1>(100000);
    random_unpacked<32,2>(250000);random_unpacked<32,3>(250000);
    products<8,0>(65536,true,l0_p8_mul);
    products<16,1>(100000,false,l0_p16_mul);
    products<32,2>(100000,false,l0_p32_mul);
    std::cout << "checks=" << checks << " scale_changes=" << scale_changes
              << " failures=" << failures << '\n';
    std::cout << (failures ? "ROUND_UNPACKED FAILED" : "ROUND_UNPACKED PASSED") << std::endl;
    return failures?1:0;
}
