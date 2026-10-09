#define main kim_investigation_original_main
#include "../../l1/test/test_kim_baseline_investigation.cpp"
#undef main

#include "../../l1/test/paper_discriminator_study.hpp"

int main() {
    using namespace kim_study;
    std::fesetround(FE_TONEAREST);
    const auto pairs = generate_pairs(1000000, 314159, DistType::UniformBits);
    uint64_t input_subnormal = 0;
    uint64_t ideal_subnormal = 0;
    uint64_t normal_pairs = 0;
    uint64_t forced_zero_n3 = 0;
    uint64_t counts[3][4] = {};
    constexpr unsigned denominators[] = {1000, 200, 100, 20};

    for (const auto& pair : pairs) {
        const auto x = unpack_spfp(pair.a);
        const auto y = unpack_spfp(pair.b);
        const bool input_normal = x.exp != 0 && y.exp != 0;
        const bool ideal_normal = ((to_bits(pair.ideal) >> 23) & 255) != 0;
        input_subnormal += !input_normal;
        ideal_subnormal += !ideal_normal;
        forced_zero_n3 += mul_base_rnd(x, y, 3, {}) == 0;
        if (!input_normal || !ideal_normal) {
            continue;
        }
        ++normal_pairs;
        for (unsigned row = 0; row < 3; ++row) {
            const float obtained = from_bits(mul_base_rnd(x, y, row + 2, {}));
            const double error = std::abs(double(obtained) - pair.ideal) / pair.ideal;
            for (unsigned column = 0; column < 4; ++column) {
                counts[row][column] += error * denominators[column] < 1;
            }
        }
    }

    std::cout << "DIAGNOSTIC_ONLY: normal-input/normal-result subset, not an author filter\n"
              << "input_subnormal=" << input_subnormal
              << " ideal_subnormal=" << ideal_subnormal
              << " forced_zero_n3=" << forced_zero_n3
              << " normal_pairs=" << normal_pairs << '\n';
    std::cout << std::fixed << std::setprecision(6);
    for (unsigned row = 0; row < 3; ++row) {
        double gap = 0;
        std::cout << "normal_subset_n=" << row + 2;
        for (unsigned column = 0; column < 4; ++column) {
            const double rate = 100. * counts[row][column] / normal_pairs;
            gap = std::max(gap, std::abs(rate - table3_rnd[row][column]));
            std::cout << ',' << rate;
        }
        std::cout << " max_gap_pp=" << gap << '\n';
    }

    for (const auto candidate : {
             discriminator::Candidate::Fig3,
             discriminator::Candidate::Guard12Pack12,
             discriminator::Candidate::SourceUncut}) {
        const auto result = discriminator::evaluate(
            0x1c900000, 0x3c820000, 3, candidate, true, false);
        std::cout << "FIG4 " << discriminator::names[unsigned(candidate)]
                  << " bits=0x" << std::hex << result.result.bits << std::dec << '\n';
    }
}
