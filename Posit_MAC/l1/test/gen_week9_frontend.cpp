#include <filesystem>
#include <fstream>
#include <iostream>
#include <random>
#include <stdexcept>
#include <string>

#include "ops_sel.hpp"
#include "sac.hpp"

namespace fs = std::filesystem;
constexpr uint64_t seed = 20261008;
uint64_t ops_rows = 0, sac_rows = 0;

unsigned count_bits(uint64_t value, unsigned width) {
    unsigned count = 0;
    for (unsigned bit = 0; bit < width; ++bit) {
        count += unsigned((value >> bit) & 1);
    }
    return count;
}

void generate_ops(const fs::path& directory, unsigned full, unsigned narrow) {
    std::ofstream output(directory / ("ops_" + std::to_string(full) + ".txt"));
    const uint64_t mask = (uint64_t(1) << full) - 1;
    const int sf_max = full == 1 ? 2 : full == 5 ? 6 : full == 12 ? 28 : full == 26 ? 240 : 120;
    std::mt19937_64 random(seed + full);
    auto emit = [&](uint64_t a, uint64_t b, unsigned mode, unsigned policy) {
        const unsigned width = mode ? narrow : full;
        uint64_t x = a >> (full - width), y = b >> (full - width);
        const bool error = policy > 1;
        const bool swapped = !error && policy == 1 && count_bits(y, width) < count_bits(x, width);
        const bool cut = mode && ((a | b) & ((uint64_t(1) << (full - width)) - 1));
        if (!error && l1::ops_swap(x, y, policy) != swapped) {
            throw std::runtime_error("L1 OPS mismatch");
        }
        if (swapped) { std::swap(x, y); }
        const bool sign_a = (ops_rows >> 3) & 1, sign_b = (ops_rows >> 5) & 1;
        const int sf_a = int(ops_rows % unsigned(2 * sf_max + 1)) - sf_max;
        const int sf_b = (ops_rows % 3) ? -sf_a : sf_a;
        output << std::hex << a << ' ' << b << std::dec << ' ' << mode << ' ' << policy
               << ' ' << sign_a << ' ' << sign_b << ' ' << sf_a << ' ' << sf_b << ' '
               << std::hex << (error ? 0 : x) << ' ' << (error ? 0 : (uint64_t(1) << width) | y)
               << std::dec << ' ' << (error ? 0 : width) << ' ' << (!error && (sign_a ^ sign_b))
               << ' ' << (error ? 0 : sf_a + sf_b) << ' ' << swapped << ' ' << (!error && cut)
               << ' ' << error << '\n';
        ++ops_rows;
    };
    const uint64_t before = ops_rows;
    if (full <= 5) {
        for (uint64_t a = 0; a <= mask; ++a) {
            for (uint64_t b = 0; b <= mask; ++b) {
                for (unsigned mode = 0; mode < 2; ++mode) {
                    for (unsigned policy = 0; policy < 4; ++policy) { emit(a, b, mode, policy); }
                }
            }
        }
    } else {
        for (unsigned bit = 0; bit < full; ++bit) {
            for (unsigned mode = 0; mode < 2; ++mode) {
                for (unsigned policy = 0; policy < 4; ++policy) {
                    emit(uint64_t(1) << bit, mask, mode, policy);
                    emit(mask, uint64_t(1) << bit, mode, policy);
                    emit(uint64_t(1) << bit, uint64_t(1) << bit, mode, policy);
                }
            }
        }
        const uint64_t low = (uint64_t(1) << (full - narrow)) - 1;
        for (unsigned policy = 0; policy < 4; ++policy) {
            emit(low, uint64_t(1) << (full - narrow), 1, policy);
            emit(0, 0, 1, policy);
            emit(mask, mask, 0, policy);
        }
        for (unsigned i = 0; i < 50000; ++i) {
            const uint64_t a = random() & mask;
            const uint64_t b = random() & mask;
            emit(a, b, i % 2, (i / 2) % 4);
        }
    }
    output.close();
    if (!output) { throw std::runtime_error("OPS fixture write"); }
    std::cout << "OPS F=" << full << " FW=" << narrow << " rows=" << ops_rows - before << '\n';
}

void generate_sac(const fs::path& directory, unsigned width) {
    std::ofstream output(directory / ("sac_" + std::to_string(width) + ".txt"));
    const uint64_t mask = (uint64_t(1) << width) - 1;
    unsigned scale_width = 1;
    while ((1u << scale_width) <= width) { ++scale_width; }
    const unsigned max_scale = (1u << scale_width) - 1;
    std::mt19937_64 random(seed + 100 + width);
    auto emit = [&](uint64_t fx, unsigned scale) {
        unsigned sa = 0;
        for (unsigned position = 1; position <= width; ++position) {
            if ((fx >> (width - position)) & 1) { sa = position; break; }
        }
        const bool error = scale > width || (fx != 0 && scale + sa > width);
        const bool valid = fx != 0 && !error;
        const uint64_t next_fx = valid ? (fx << sa) & mask : fx;
        const unsigned next_scale = valid ? scale + sa : scale;
        if (valid) {
            l1::SacState state(fx, width);
            state.scale = scale;
            if (state.step() != sa || state.fx != next_fx || state.scale != next_scale) {
                throw std::runtime_error("L1 SAC mismatch");
            }
        }
        output << std::hex << fx << std::dec << ' ' << scale << ' ' << (valid ? sa : 0)
               << ' ' << next_scale << ' ' << std::hex << next_fx << std::dec << ' '
               << valid << ' ' << (next_fx == 0) << ' ' << error << '\n';
        ++sac_rows;
    };
    const uint64_t before = sac_rows;
    if (width <= 12) {
        for (uint64_t fx = 0; fx <= mask; ++fx) {
            for (unsigned scale = 0; scale <= max_scale; ++scale) { emit(fx, scale); }
        }
    } else {
        for (unsigned scale = 0; scale <= max_scale; ++scale) {
            emit(0, scale);
            emit(mask, scale);
            for (unsigned bit = 0; bit < width; ++bit) { emit(uint64_t(1) << bit, scale); }
        }
        for (unsigned i = 0; i < 50000; ++i) {
            const uint64_t fx = random() & mask;
            emit(fx, i % (max_scale + 1));
        }
    }
    output.close();
    if (!output) { throw std::runtime_error("SAC fixture write"); }
    std::cout << "SAC W=" << width << " rows=" << sac_rows - before << '\n';
}

int main(int argc, char** argv) try {
    if (argc != 2) { throw std::invalid_argument("OUTPUT_DIRECTORY"); }
    const fs::path directory(argv[1]);
    fs::create_directories(directory);
    for (unsigned full : {1u, 5u, 12u, 26u, 27u}) {
        generate_ops(directory, full, full < 12 ? full : 12);
        generate_sac(directory, full);
    }
    std::cout << "WEEK9 GENERATOR PASS ops=" << ops_rows << " sac=" << sac_rows
              << " seed=" << seed << '\n';
    return 0;
} catch (const std::exception& error) {
    std::cerr << "WEEK9 GENERATOR FAIL " << error.what() << '\n';
    return 1;
}
