#pragma once
#include <algorithm>
#include <random>
#include "week11_model.hpp"

// Verification corpus only. Seed/distribution are frozen before acceptance.
extern unsigned FIXED_N,FIXED_OPS;
namespace nf_coverage {
template<int NB, int ES> struct Corpus {
    static constexpr unsigned F = NB - 3 - ES;
    static constexpr unsigned FW = F < 12 ? F : 12;
    static constexpr uint32_t NAR = uint32_t(1) << (NB - 1);
    static constexpr uint32_t MASK = uint32_t((uint64_t(1) << NB) - 1);
    static constexpr uint32_t ONE = uint32_t(1) << (NB - 2);
    using Model = week11::Model<NB, ES, FW>;
    struct Input {
        uint32_t a, b, c;
        unsigned n, ops, mode;
        bool acc_mode, acc_clr;
    };
    static uint32_t stratified(std::mt19937_64& rng, unsigned group,
                               bool negative, bool polarity) {
        if constexpr (NB != 32) return uint32_t(rng()) & MASK;
        constexpr unsigned lo[] = {1,4,8,12,16,18,23,28};
        constexpr unsigned hi[] = {3,7,11,15,17,22,27,31};
        const unsigned end = std::min(hi[group], polarity ? 31u : 30u);
        const unsigned run = lo[group] + unsigned(rng() % (end - lo[group] + 1));
        uint32_t mag = 0;
        for (int bit = 30; bit > 30 - int(run); --bit) {
            if (polarity) mag |= uint32_t(1) << bit;
        }
        const unsigned left = 31 - run;
        if (left) {
            if (!polarity) mag |= uint32_t(1) << (left - 1);
            mag |= uint32_t(rng()) & ((uint32_t(1) << (left - 1)) - 1);
        }
        return negative ? (0u - mag) & MASK : mag;
    }
    static uint32_t power(int sf, bool sign = false) {
        return uint32_t(l1::pack<NB, ES>({sign, false, false, sf,
                                         uint64_t(1) << 63, true}));
    }
    static Input next(std::mt19937_64& rng, uint64_t serial, uint32_t accumulator) {
        const uint64_t cross = serial / 128;
        Input v{stratified(rng, unsigned(cross % 8), bool((cross / 64) & 1), bool(serial & 1)),
                stratified(rng, unsigned((cross / 8) % 8), bool((cross / 128) & 1), bool((serial / 2) & 1)),
                uint32_t(rng()) & MASK, unsigned(serial % 9), unsigned((serial / 9) % 2),
                unsigned((serial / 18) % 2), bool((serial / 36) % 2), false};
        v.n=FIXED_N;v.ops=FIXED_OPS;v.mode=1;
        v.acc_clr = v.acc_mode && (serial / 72) % 11 == 0;
        // Half of the base corpus anchors C to the actual rounded product.
        // Range clamping may change delta: the monitor measures it, never assumes it.
        if ((serial / 72) % 6 < 3) {
            v.acc_mode = false;
            v.acc_clr = false;
            const auto p = Model::mac(v.a, v.b, 0, !v.mode, v.n, v.ops);
            if (p.product && p.product != NAR) {
                auto c = l1::parse<NB, ES>(p.product);
                c.sign = !c.sign;
                c.sf += int((serial / 6) % 5);
                v.c = uint32_t(l1::pack<NB, ES>(c));
            }
        } else if ((serial / 72) % 6 == 3 && v.acc_mode && !v.acc_clr &&
                   accumulator && accumulator != NAR) {
            // The port C is ignored here. Construct against the committed state.
            auto a = l1::parse<NB, ES>(accumulator);
            a.sign = !a.sign;
            a.sf -= int((serial / 6) % 5);
            v.a = uint32_t(l1::pack<NB, ES>(a));
            v.b = ONE;
        }
        // Directed cases override the base corpus, including control state.
        // Replayed by both native and four-state simulators without force/release.
        switch (serial % 128) {
            case 0: v.a=0; v.b=NAR; break;
            case 1: v.a=NAR; v.b=0; break;
            case 2: v.c=NAR; break;
            case 3: v.a=0; break;
            case 4: v.b=0; break;
            case 5: v.c=0; break;
            case 6: v.a=NAR-1; v.b=NAR-1; v.c=(0u-(NAR-1))&MASK; break;
            case 7: v.a=1; v.b=1; v.c=1; break;
            case 8: v.a=ONE; v.b=ONE; v.c=(0u-ONE)&MASK; break;
            case 9: v.a=ONE; v.b=ONE; v.c=(0u-ONE+1)&MASK; break;
            case 10: v.a=(0u-ONE)&MASK; v.b=ONE; v.c=ONE; break;
            case 11: case 12: case 13: case 14: {
                const unsigned shifts[] = {1,3,8,20};
                const unsigned shift = std::min(shifts[serial%128-11], F);
                v.a=ONE; v.b=ONE;
                v.c=uint32_t(l1::pack<NB,ES>({true,false,false,-1,
                    uint64_t(0)-(uint64_t(1)<<(64-shift)),true}));
                break;
            }
            case 15: case 16: case 17:
                v.acc_mode=false; v.acc_clr=false; v.mode=1;
                v.a=ONE+uint32_t(serial%128==16); v.b=ONE;
                v.c=serial%128==17 ? MASK : power(-int(F)-1);
                break;
            case 18: v.a=NAR-1; v.b=1; v.c=0; break;
            case 19: v.a=(0u-(NAR-1))&MASK; v.b=(0u-(NAR-1))&MASK; v.c=0; break;
            case 20: case 21: case 22: case 23: {
                const unsigned shifts[] = {1,3,8,20};
                const unsigned shift=std::min(shifts[serial%128-20],F);
                v.acc_mode=false; v.acc_clr=false; v.mode=1;
                v.a=ONE; v.b=ONE;
                v.c=uint32_t(l1::pack<NB,ES>({true,false,false,0,
                    (uint64_t(1)<<63) | (uint64_t(1)<<(63-shift)),true}));
                break;
            }
            default: break;
        }
        return v;
    }
};
}
