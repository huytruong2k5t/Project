#include <array>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include "paper_discriminator_study.hpp"

// Literal Fig.5(b) gates, posit32 ES3 fraction12, no library encoder.
// Rgm is six signed bits. Values outside this interface are not claimed valid.
uint32_t fig5_raw(bool sign, int sf, unsigned frac12) {
    int k = sf / 8;
    if (sf < 0 && sf % 8) --k;
    const unsigned rgm = unsigned(k) & 63;
    const unsigned rgm_sign = rgm >> 5;
    const unsigned offset = (rgm & 31) ^ (rgm_sign ? 31 : 0);
    const unsigned top = !(rgm_sign ^ unsigned(sign)); // XNOR, ~FRB in figure.
    const unsigned second = rgm_sign ^ unsigned(sign); // XOR, FRB in figure.
    const uint32_t lower = ((unsigned(sf) & 7) << 26) | (frac12 << 14);
    const uint32_t xor_lower = lower ^ (sign ? 0x1fffffffu : 0);
    const uint32_t joined = (top << 30) | (second << 29) | xor_lower;
    uint32_t shifted = joined >> offset;
    if (offset && top) shifted |= uint32_t((uint64_t(1) << offset)-1) << (31-offset);
    return (uint32_t(sign) << 31) | ((shifted + unsigned(sign)) & 0x7fffffff);
}

uint32_t fig5_clamped(bool sign, int sf, unsigned frac12) {
    if (sf >= 240) return sign ? 0x80000001u : 0x7fffffffu;
    if (sf < -240) return sign ? 0xffffffffu : 1u;
    return fig5_raw(sign, sf, frac12);
}

uint32_t library_pack(bool sign, int sf, unsigned frac12) {
    l1::posit_unpacked<32,3> u{sign, false, false, sf,
        uint64_t(4096 + frac12) << 51, true};
    return l1::pack<32,3>(u, l1::RoundMode::TRUNC);
}

// Literal positive-term interpretation of Fig.4: initialize with Y and
// add at most n_fraction highest set fraction bits. Uses division, not SAC.
uint32_t scan_fraction(unsigned x, unsigned y, unsigned n_fraction,
                       unsigned& terms, int sf_base = 0) {
    uint64_t acc = y;
    unsigned fraction = x - 4096;
    terms = 1;
    for (unsigned i = 0; i < n_fraction && fraction; ++i) {
        unsigned p = 0;
        for (unsigned v = fraction; v >>= 1;) ++p;
        const unsigned distance = 12-p;
        acc += y / (1u << distance);
        fraction -= 1u << p;
        ++terms;
    }
    int sf = sf_base;
    while (acc >= 8192) { acc /= 2; ++sf; }
    return fig5_clamped(false, sf, unsigned(acc-4096));
}

int main(int argc, char** argv) {
    if (argc != 2) return 2;
    const std::filesystem::path directory(argv[1]);
    std::filesystem::create_directories(directory);
    std::ofstream vectors(directory / "packer.txt");
    std::ofstream divergent(directory / "divergent.csv");
    std::ofstream counts(directory / "sac_counts.csv");
    if (!vectors || !divergent || !counts) throw std::runtime_error("output files");
    uint64_t normal_checks = 0, clamp_checks = 0, raw_differences = 0, fixture_rows = 0;
    // Exhaust all fraction12/sign at every representable scale -240..240.
    // +240 is tested with an explicit project saturation policy.
    for (int sf = -240; sf <= 240; ++sf) {
        for (unsigned fraction = 0; fraction < 4096; ++fraction) {
            for (bool sign : {false, true}) {
                const auto expected = fig5_clamped(sign, sf, fraction);
                if (library_pack(sign, sf, fraction) != expected)
                    throw std::runtime_error("Fig5/library valid-range mismatch");
                ++normal_checks;
            }
        }
    }
    const int scale_edges[] = {-240,-239,-233,-232,-9,-8,-1,0,1,7,8,15,16,231,232,239,240};
    auto emit = [&](bool sign, int sf, unsigned fraction) {
        const uint32_t raw = fig5_raw(sign, sf, fraction);
        const uint32_t expected = fig5_clamped(sign, sf, fraction);
        if (expected != library_pack(sign, sf, fraction))
            throw std::runtime_error("Fig5/clamped library mismatch");
        vectors << sign << ' ' << sf << ' ' << std::hex << fraction << ' '
                << expected << ' ' << raw << std::dec << '\n';
        raw_differences += raw != expected;
        ++fixture_rows;
    };
    for (int sf : scale_edges) for (unsigned f = 0; f < 4096; ++f)
        for (bool sign : {false, true}) emit(sign, sf, f);
    const unsigned patterns[] = {0,1,2047,2048,4094,4095,0x555,0xaaa};
    for (int sf = -512; sf <= 511; ++sf) for (unsigned f : patterns)
        for (bool sign : {false, true}) { emit(sign, sf, f); ++clamp_checks; }

    divergent << "x_Q12,y_Q12,n_terms,rnd_result,scan_same_total_result,scan_n_fraction_result,rnd_actual_terms,scan_actual_terms\n";
    counts << "n_terms,pairs,rnd_vs_scan_same_total_differences,rnd_vs_scan_n_fraction_differences\n";
    uint64_t sac_pairs = 0;
    // GLSVLSI2019 Table1 explicitly presents three signed power terms.
    // Input mantissa 1.11011100110111000000000, unbiased exponent -2.
    const unsigned source_mantissa = (1u << 23) | 0b11011100110111000000000u;
    l1::PaperSac source_sac(source_mantissa,23,true);
    source_sac.exponent = -2;
    const int source_powers[] = {-1,-5,-8};
    const int source_signs[] = {1,-1,-1};
    std::ofstream source_trace(directory / "source2019_trace.csv");
    source_trace << "n,power,coefficient,next_exponent\n";
    for (unsigned i=0; i<3; ++i) {
        const bool up = (source_sac.mantissa & (1u << 22)) != 0;
        const int power = source_sac.exponent + int(up);
        const int coefficient = source_sac.coefficient;
        if (power != source_powers[i] || coefficient != source_signs[i])
            throw std::runtime_error("2019 Table1 source terms mismatch");
        source_sac.advance(up);
        source_trace << i+1 << ',' << power << ',' << coefficient << ',' << source_sac.exponent << '\n';
    }
    const unsigned ys[] = {4096,4097,4616,6143,8191};
    for (unsigned n = 1; n <= 8; ++n) {
        uint64_t same = 0, extra = 0, pairs = 0;
        for (unsigned x = 4096; x < 8192; ++x) for (unsigned y : ys) {
            const uint32_t a = 0x40000000 | ((x-4096) << 14);
            const uint32_t b = 0x40000000 | ((y-4096) << 14);
            const auto rnd = discriminator::evaluate(a,b,n,discriminator::Candidate::Fig3,true);
            if (!discriminator::verify_trace(a,b,n,discriminator::Candidate::Fig3,rnd))
                throw std::runtime_error("RND independent Q96 mismatch");
            unsigned scan_t, extra_t;
            const uint32_t scan = scan_fraction(x,y,n-1,scan_t);
            const uint32_t scan_extra = scan_fraction(x,y,n,extra_t);
            same += rnd.result.bits != scan;
            extra += rnd.result.bits != scan_extra;
            if ((x==6143 || x==6144 || x==6145 || x==5248) && (y==4097 || y==4616) && n<=4)
                divergent << x << ',' << y << ',' << n << ",0x" << std::hex << rnd.result.bits
                          << ",0x" << scan << ",0x" << scan_extra << std::dec << ','
                          << rnd.steps.size() << ',' << scan_t << '\n';
            ++pairs;
        }
        counts << n << ',' << pairs << ',' << same << ',' << extra << '\n';
        sac_pairs += pairs;
    }
    // Published Fig.4: hidden + 2 fraction updates. All terms positive here.
    unsigned fig_terms;
    const uint32_t fig_scan = scan_fraction(5248,4616,2,fig_terms,-11);
    const auto fig_rnd = discriminator::evaluate(0x1c900000,0x3c820000,3,
        discriminator::Candidate::Fig3,true);
    if (fig_rnd.result.bits != 0x1ae34000 || fig_scan != 0x1ae34000 || fig_terms != 3)
        throw std::runtime_error("source fixture");
    const auto fig_rnd2 = discriminator::evaluate(0x1c900000,0x3c820000,2,
        discriminator::Candidate::Fig3,true);
    unsigned scan_count;
    const auto fig_scan_total2 = scan_fraction(5248,4616,1,scan_count,-11);
    std::ofstream mapping(directory / "source2021_count.csv");
    mapping << "interpretation,local_count,output\n" << std::hex;
    mapping << "RND_total_terms,2,0x" << fig_rnd2.result.bits << '\n';
    mapping << "RND_total_terms,3,0x" << fig_rnd.result.bits << '\n';
    mapping << "scan_total_terms,2,0x" << fig_scan_total2 << '\n';
    mapping << "scan_fraction_updates,2,0x" << fig_scan << '\n';
    std::cout << "CONTRACT AUDIT PASS normal_checks=" << normal_checks
              << " clamp_checks=" << clamp_checks << " sac_pairs=" << sac_pairs
              << " fixture_rows=" << fixture_rows
              << " raw_boundary_differences=" << raw_differences << '\n';
    std::cout << "No claim of original author RTL; scan is a literal2021 control; RND is the frozen2019/2024 reconstruction.\n";
}
