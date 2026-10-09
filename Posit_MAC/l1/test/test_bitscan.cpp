#include "paper_multiplier.hpp"
#include "paper_measurement.hpp"
#include <iostream>
#include <iomanip>

using namespace l1;

// Bit-scan multiplier as described in Section III-C of 2021 paper:
// "SAC generates a shift amount, which is the left-shift size required to move the next 1 of FracX to the hidden bit position, every cycle."
// SBM shifts FracY and accumulates it.
struct BitScanMultiplier {
    static uint32_t mul(uint32_t a, uint32_t b, unsigned n_terms, bool cut_out12 = true) {
        auto ua = parse<32, 3>(a), ub = parse<32, 3>(b);
        if (ua.is_zero || ub.is_zero || ua.is_nar || ub.is_nar) {
            return (ua.is_nar || ub.is_nar) ? 0x80000000 : 0;
        }
        
        // 12-bit fraction + 1 hidden bit = 13 bits
        uint32_t xa = uint32_t(ua.frac >> 51); // 13 bits: [12:0]
        uint32_t xb = uint32_t(ub.frac >> 51);
        
        // Operand selector: Kim's Table 2 predictor or min-popcount?
        // Let's test Table 2 predictor
        auto sel = paper_ops_select_pattern(xa - 4096, xb - 4096);
        bool swap = sel.swapped;
        uint32_t X = swap ? xb : xa;
        uint32_t Y = swap ? xa : xb;
        
        // Bit-scan:
        // First term: Y corresponding to hidden bit of X (power 0)
        // Hidden bit is bit 12
        uint64_t acc = Y; // at hidden bit alignment
        uint32_t rem = X & 0xFFF; // 12 fraction bits of X
        
        unsigned terms = 1;
        while (rem > 0 && terms < n_terms) {
            // Find leading 1 in rem (from bit 11 down to 0)
            int lz = 0;
            while ((rem & (1u << (11 - lz))) == 0) {
                ++lz;
            }
            int shift = lz + 1; // shift relative to bit 12
            acc += (uint64_t(Y) >> shift);
            rem &= ~(1u << (11 - lz));
            ++terms;
        }
        
        // Normalize acc: hidden bit is at bit 12 (4096)
        int sf = ua.sf + ub.sf;
        if (acc >= 8192) {
            acc >>= 1;
            sf += 1;
        }
        
        posit_unpacked<32, 3> u;
        u.sign = ua.sign ^ ub.sign;
        u.is_zero = false;
        u.is_nar = false;
        u.sf = sf;
        u.frac = acc << 51; // align to bit 63
        u.exact = true;
        
        if (cut_out12) {
            u.frac &= ~((uint64_t(1) << 51) - 1);
        }
        return pack<32, 3>(u, RoundMode::TRUNC);
    }
};

int main() {
    paper_init_fp32_rne();
    PaperGenerator gen(314159, PaperDistribution::UniformValue);
    PaperCounters counters;
    
    const unsigned dens[4] = {1000, 200, 100, 20};
    uint64_t counts_cut[3][4] = {}, counts_uncut[3][4] = {};
    const uint64_t samples = 1000000;
    
    const double target[3][4] = {
        {9.87, 32.19, 50.03, 95.57},
        {44.69, 83.17, 95.05, 99.99},
        {87.09, 99.79, 99.99, 99.99}
    };
    
    while (counters.accepted < samples) {
        uint32_t ra = gen.next_bits(), rb = gen.next_bits();
        auto pair = paper_evaluate_pair(ra, rb);
        counters.record(pair.reason);
        if (pair.reason != PaperReject::Accepted) continue;
        
        for (unsigned n = 2; n <= 4; ++n) {
            uint32_t out_cut = BitScanMultiplier::mul(pair.posit_a, pair.posit_b, n, true);
            uint32_t out_uncut = BitScanMultiplier::mul(pair.posit_a, pair.posit_b, n, false);
            
            auto err_cut = paper_error_fraction(out_cut, pair.ideal_bits);
            auto err_uncut = paper_error_fraction(out_uncut, pair.ideal_bits);
            
            for (int j = 0; j < 4; ++j) {
                if (err_cut.below(dens[j])) ++counts_cut[n - 2][j];
                if (err_uncut.below(dens[j])) ++counts_uncut[n - 2][j];
            }
        }
    }
    
    std::cout << "=== BIT-SCAN (Literal Next-1) EVALUATION (1M samples) ===\n";
    std::cout << "--- WITH OUTPUT CUT 12 ---\n";
    for (unsigned n = 2; n <= 4; ++n) {
        std::cout << "n=" << n << ": ";
        double max_d = 0;
        for (int j = 0; j < 4; ++j) {
            double pct = 100.0 * counts_cut[n - 2][j] / samples;
            std::cout << std::fixed << std::setprecision(2) << pct << "% | ";
            double d = std::fabs(pct - target[n - 2][j]);
            if (d > max_d) max_d = d;
        }
        std::cout << "Max delta: " << max_d << " pp\n";
    }
    
    std::cout << "\n--- WITHOUT OUTPUT CUT ---\n";
    for (unsigned n = 2; n <= 4; ++n) {
        std::cout << "n=" << n << ": ";
        double max_d = 0;
        for (int j = 0; j < 4; ++j) {
            double pct = 100.0 * counts_uncut[n - 2][j] / samples;
            std::cout << std::fixed << std::setprecision(2) << pct << "% | ";
            double d = std::fabs(pct - target[n - 2][j]);
            if (d > max_d) max_d = d;
        }
        std::cout << "Max delta: " << max_d << " pp\n";
    }
    
    return 0;
}
