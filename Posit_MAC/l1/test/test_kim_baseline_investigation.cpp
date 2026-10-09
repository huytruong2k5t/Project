#include "kim_investigation.hpp"
#include <iostream>
#include <iomanip>
#include <vector>
#include <cmath>
#include <random>
#include <chrono>

using namespace kim_study;

struct TestCase {
    const char* name;
    uint32_t (*func)(const Spfp&, const Spfp&, unsigned, void*);
    void* opt;
};

// Target Table 3 from Kim 2019
const double table3_base[3][4] = {
    {1.20, 4.80, 8.62, 32.24},
    {6.36, 19.79, 31.06, 75.00},
    {20.19, 47.57, 64.17, 97.37}
};

const double table3_rnd[3][4] = {
    {4.97, 17.70, 29.46, 79.32},
    {28.92, 65.89, 84.72, 100.00},
    {74.00, 99.25, 100.00, 100.00}
};

const double table3_all[3][4] = {
    {9.30, 32.12, 50.01, 95.58},
    {43.94, 83.01, 95.03, 100.00},
    {86.69, 99.81, 100.00, 100.00}
};

enum class DistType { UniformValue, UniformBits, LogUniform };

struct GenPair {
    uint32_t a, b;
    float ideal;
};

std::vector<GenPair> generate_pairs(uint64_t count, uint64_t seed, DistType dist) {
    std::mt19937_64 rng(seed);
    std::vector<GenPair> pairs;
    pairs.reserve(count);
    
    while (pairs.size() < count) {
        uint32_t ba = 0, bb = 0;
        if (dist == DistType::UniformValue) {
            float fa = std::ldexp(float(rng() & 0xFFFFFF), -24);
            float fb = std::ldexp(float(rng() & 0xFFFFFF), -24);
            if (fa <= 0.0f || fb <= 0.0f || fa >= 1.0f || fb >= 1.0f) continue;
            ba = to_bits(fa);
            bb = to_bits(fb);
        } else if (dist == DistType::UniformBits) {
            // Random bits with sign=0, exp in [1, 126]
            do { ba = uint32_t(rng() & 0x3FFFFFFF); } while (ba == 0 || ba >= 0x3F800000);
            do { bb = uint32_t(rng() & 0x3FFFFFFF); } while (bb == 0 || bb >= 0x3F800000);
        } else if (dist == DistType::LogUniform) {
            // log-uniform: exp uniformly chosen from [100, 126], frac uniform
            int exp_a = 100 + int(rng() % 27);
            int exp_b = 100 + int(rng() % 27);
            ba = (uint32_t(exp_a) << 23) | uint32_t(rng() & 0x7FFFFF);
            bb = (uint32_t(exp_b) << 23) | uint32_t(rng() & 0x7FFFFF);
        }
        
        float fa = from_bits(ba), fb = from_bits(bb);
        volatile float ideal = fa * fb;
        if (ideal <= 0.0f || !std::isfinite(ideal)) continue;
        
        pairs.push_back({ba, bb, ideal});
    }
    return pairs;
}

int main(int argc, char** argv) {
    uint64_t samples = argc > 1 ? std::stoull(argv[1]) : 1000000;
    uint64_t seed = argc > 2 ? std::stoull(argv[2]) : 314159;
    
    std::fesetround(FE_TONEAREST);
    
    std::cout << "========================================================\n";
    std::cout << "KIM 2019 BASELINE ABLATION & GENERATOR INVESTIGATION\n";
    std::cout << "Samples: " << samples << ", Seed: " << seed << "\n";
    std::cout << "========================================================\n\n";
    
    const unsigned dens[4] = {1000, 200, 100, 20}; // Err < 0.1%, 0.5%, 1.0%, 5.0%
    
    DistType dists[] = {DistType::UniformValue, DistType::UniformBits};
    const char* dist_names[] = {"UniformValue [0, 1) grid24", "UniformBits in (0, 1)"};
    
    for (int d = 0; d < 2; ++d) {
        std::cout << "\n>>> TESTING DISTRIBUTION: " << dist_names[d] << " <<<\n\n";
        auto pairs = generate_pairs(samples, seed, dists[d]);
        
        // Define variants to test
        RndOptions rnd_hw{false, true};   // 1.5 threshold, 1's complement
        RndOptions rnd_exact{false, false}; // 1.5 threshold, exact
        RndOptions rnd_sqrt2{true, true};  // sqrt(2) threshold, 1's complement
        RndOptions rnd_sqrt2_exact{true, false}; // sqrt(2) threshold, exact
        
        TrncOptions trnc_both{true, true, rnd_hw};
        TrncOptions trnc_x_only{false, true, rnd_hw};
        TrncOptions trnc_no_out{true, false, rnd_hw};
        
        struct Experiment {
            std::string name;
            int type; // 0: base, 1: rnd_hw, 2: rnd_exact, 3: rnd_sqrt2, 4: trnc_both, 5: trnc_x, 6: sel_both, 7: sel_x
            const double (*target)[4];
        };
        
        std::vector<Experiment> experiments = {
            {"1. Proposed BASE", 0, table3_base},
            {"2a. BASE+RND (Thresh=1.5, OnesComp)", 1, table3_rnd},
            {"2b. BASE+RND (Thresh=1.5, ExactSub)", 2, table3_rnd},
            {"2c. BASE+RND (Thresh=sqrt2, OnesComp)", 3, table3_rnd},
            {"3a. BASE+RND+TRNC (Cut both X and Y)", 4, nullptr},
            {"3b. BASE+RND+TRNC (Cut X only)", 5, nullptr},
            {"4a. BASE+RND+TRNC+SEL (Cut both X & Y, Table 2)", 6, table3_all},
            {"4b. BASE+RND+TRNC+SEL (Cut X only, Table 2)", 7, table3_all}
        };
        
        for (const auto& exp : experiments) {
            std::cout << "--- " << exp.name << " ---\n";
            std::cout << "n | Err<0.1% | Err<0.5% | Err<1.0% | Err<5.0% | Max Delta pp vs Target\n";
            std::cout << "-----------------------------------------------------------------------\n";
            
            for (unsigned n = 2; n <= 4; ++n) {
                uint64_t counts[4] = {0, 0, 0, 0};
                uint64_t outliers = 0; // Err >= 5%
                
                for (const auto& p : pairs) {
                    Spfp X = unpack_spfp(p.a);
                    Spfp Y = unpack_spfp(p.b);
                    uint32_t res_bits = 0;
                    
                    if (exp.type == 0) {
                        res_bits = mul_base(X, Y, n);
                    } else if (exp.type == 1) {
                        res_bits = mul_base_rnd(X, Y, n, rnd_hw);
                    } else if (exp.type == 2) {
                        res_bits = mul_base_rnd(X, Y, n, rnd_exact);
                    } else if (exp.type == 3) {
                        res_bits = mul_base_rnd(X, Y, n, rnd_sqrt2);
                    } else if (exp.type == 4) {
                        res_bits = mul_base_rnd_trnc(X, Y, n, trnc_both);
                    } else if (exp.type == 5) {
                        res_bits = mul_base_rnd_trnc(X, Y, n, trnc_x_only);
                    } else if (exp.type == 6) {
                        res_bits = mul_base_rnd_trnc_sel(X, Y, n, trnc_both);
                    } else if (exp.type == 7) {
                        res_bits = mul_base_rnd_trnc_sel(X, Y, n, trnc_x_only);
                    }
                    
                    float res = from_bits(res_bits);
                    double err = std::fabs(double(res) - double(p.ideal)) / double(p.ideal);
                    
                    for (int j = 0; j < 4; ++j) {
                        if (err * dens[j] < 1.0) ++counts[j];
                    }
                    if (err >= 0.05) ++outliers;
                }
                
                double row_max_delta = 0.0;
                std::cout << n << " | ";
                for (int j = 0; j < 4; ++j) {
                    double pct = 100.0 * counts[j] / samples;
                    std::cout << std::fixed << std::setprecision(2) << pct << "% | ";
                    if (exp.target) {
                        double delta = std::fabs(pct - exp.target[n - 2][j]);
                        if (delta > row_max_delta) row_max_delta = delta;
                    }
                }
                if (exp.target) {
                    std::cout << "Delta: " << std::fixed << std::setprecision(4) << row_max_delta << " pp";
                    if (row_max_delta <= 1.0) std::cout << " [PASS <=1%]";
                } else {
                    std::cout << "(No direct paper target)";
                }
                std::cout << " | Outliers(>=5%): " << outliers << " (" << std::fixed << std::setprecision(4) << (100.0 * outliers / samples) << "%)\n";
            }
            std::cout << "\n";
        }
    }
    
    return 0;
}
