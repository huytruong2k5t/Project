#include <filesystem>
#include <fstream>
#include <iostream>
#include <random>
#include <sstream>
#include "paper_discriminator_study.hpp"

// Emits expected observations only. The RTL receives A/B/n/force, never state.
int main(int argc, char** argv) {
    if (argc != 3) return 2;
    std::filesystem::create_directories(argv[2]);
    std::ifstream corpus(argv[1]);
    if (!corpus) throw std::runtime_error("missing frozen corpus");
    std::ofstream transactions(std::filesystem::path(argv[2]) / "transactions.txt");
    std::ofstream traces(std::filesystem::path(argv[2]) / "traces.txt");
    unsigned records = 0, commits = 0, specials = 0, frozen = 0;
    auto emit = [&](uint32_t a, uint32_t b, unsigned n, bool force) {
        const auto value = discriminator::evaluate(a, b, n, discriminator::Candidate::Fig3, force);
        if (!discriminator::verify_trace(a, b, n, discriminator::Candidate::Fig3, value))
            throw std::runtime_error("Q96 reference mismatch");
        transactions << std::hex << a << ' ' << b << std::dec << ' ' << n << ' '
                     << force << ' ' << value.steps.size() << ' ' << std::hex
                     << value.result.bits << '\n';
        int64_t acc = 0;
        for (const auto& step : value.steps) {
            const uint64_t term = unsigned(value.anchor - step.power) >= 64 ? 0 :
                uint64_t(value.selected_y) >> unsigned(value.anchor - step.power);
            traces << std::dec << step.iteration << ' ' << std::hex << step.mantissa
                   << ' ' << std::dec << step.exponent << ' ' << step.power << ' '
                   << (step.coefficient < 0) << ' ' << value.anchor << ' ' << std::hex
                   << acc << ' ' << term << ' ' << step.term_tail << ' '
                   << step.next_mantissa << ' ' << std::dec << step.next_exponent << ' '
                   << ((step.coefficient < 0) ^ step.round_up) << ' ' << std::hex
                   << step.accumulator << '\n';
            acc = step.accumulator;
            ++commits;
        }
        specials += value.steps.empty();
        ++records;
    };
    std::string line;
    std::getline(corpus, line);
    while (std::getline(corpus, line)) {
        std::istringstream row(line);
        std::string id, category, a, b, n, force;
        std::getline(row, id, ',');
        std::getline(row, category, ',');
        std::getline(row, a, ',');
        std::getline(row, b, ',');
        std::getline(row, n, ',');
        std::getline(row, force, ',');
        emit(std::stoul(a, nullptr, 16), std::stoul(b, nullptr, 16),
             std::stoul(n), std::stoul(force));
        ++frozen;
    }
    emit(0x1c900000, 0x3c820000, 3, true);
    for (unsigned f = 0; f < 4096; ++f) {
        const uint32_t a = 0x40000000u | (f << 14);
        const uint32_t b = 0x40000000u | (((f * 37 + 91) & 4095) << 14);
        for (unsigned n : {1u, 3u, 8u}) emit(a, b, n, f & 1);
    }
    const uint32_t corners[] = {0, 0x80000000, 1, 0xffffffff, 0x7fffffff,
        0x80000001, 0x40000000, 0xc0000000, 0x40004000, 0xbfffc000};
    for (uint32_t a : corners) for (uint32_t b : corners)
        for (unsigned n : {1u, 3u, 8u}) for (bool force : {false, true})
            emit(a, b, n, force);
    std::mt19937_64 rng(20261009);
    for (unsigned i = 0; i < 500; ++i) {
        const uint32_t a = rng(), b = rng();
        for (unsigned n = 1; n <= 8; ++n) emit(a, b, n, i & 1);
    }
    std::cout << "PAPER TOP GENERATOR PASS records=" << records
              << " commits=" << commits << " specials=" << specials
              << " frozen=" << frozen << " seed=20261009\n";
}
