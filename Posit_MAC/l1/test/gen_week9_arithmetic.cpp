#include <filesystem>
#include <fstream>
#include <iostream>
#include <random>
#include <stdexcept>
#include "sbm.hpp"
#include "sac.hpp"
#include "mul_norm.hpp"

int main(int argc, char** argv) {
    if (argc != 2) return 2;
    std::filesystem::create_directories(argv[1]);
    std::mt19937_64 rng(20261009);
    uint64_t total = 0;
    for (unsigned f : {1u, 5u, 12u, 26u, 27u}) {
        const unsigned fw = std::min(f, 12u), fin = 2*f+1;
        for (unsigned scheme = 0; scheme < 2; ++scheme) {
            std::ofstream out(std::filesystem::path(argv[1]) /
                ("arithmetic_" + std::to_string(f) + "_" + std::to_string(scheme) + ".txt"));
            for (unsigned row = 0; row < 6000; ++row) {
                const bool mode = row & 1;
                const unsigned w = mode ? fw : f;
                const unsigned q = mode ? fw + 2*scheme : 2*f;
                const uint64_t mask = (uint64_t(1)<<w)-1;
                uint64_t x = rng() & mask, y = (uint64_t(1)<<w) | (rng() & mask);
                if (row < 2*w) x = uint64_t(1) << (row/2);
                const unsigned limit = row % (w+1);
                l1::SacState sac(x,w);
                l1::SbmState sbm(y,w,q);
                bool numerical = false;
                auto emit = [&](unsigned scale, bool init, bool first) {
                    const uint64_t before = first ? 0 : sbm.acc;
                    const bool old_sticky = first ? false : sbm.sticky;
                    const bool old_num = first ? false : numerical;
                    const uint64_t base = y << (q-w);
                    const uint64_t term = init ? 0 : base >> scale;
                    const bool tail = !init && (base & ((uint64_t(1)<<scale)-1));
                    if (!init) sbm.add(scale, !mode || scheme == 1);
                    numerical |= tail;
                    const int sf = int(row % 801)-400;
                    const auto norm = l1::mul_norm<32,2>(sbm.acc,q,sf,false,sbm.sticky);
                    uint64_t independent = sbm.acc;
                    int independent_sf = sf;
                    bool independent_sticky = sbm.sticky;
                    if (independent >= (uint64_t(2)<<q)) {
                        independent_sticky |= independent & 1;
                        independent /= 2;
                        ++independent_sf;
                    }
                    if (norm.sf != independent_sf || norm.exact == independent_sticky ||
                        norm.frac != (independent << (63-q)))
                        throw std::runtime_error("independent normalization mismatch");
                    const unsigned pad = mode && scheme == 0 ? 2 : 0;
                    out << std::hex << mode << ' ' << y << ' ' << scale << ' ' << init << ' '
                        << first << ' ' << (before<<pad) << ' ' << old_sticky << ' ' << old_num << ' '
                        << (base<<pad) << ' ' << (term<<pad) << ' ' << tail << ' '
                        << (sbm.acc<<pad) << ' ' << sbm.sticky << ' ' << numerical << ' '
                        << std::dec << sf << ' ' << norm.sf << ' ' << std::hex
                        << ((norm.frac>>(63-fin)) & ((uint64_t(1)<<fin)-1)) << ' '
                        << !norm.exact << '\n';
                    ++total;
                };
                if (!limit || !x) {
                    emit(0,true,true);
                } else {
                    while (sac.fx && sac.iterations < limit) {
                        sac.step();
                        emit(sac.scale,false,sac.iterations == 1);
                    }
                }
                if (!mode && limit == w && sbm.acc != y*((uint64_t(1)<<w)+x))
                    throw std::runtime_error("exact product mismatch");
            }
        }
    }
    std::cout << "WEEK9 ARITHMETIC GENERATOR PASS rows=" << total << " seed=20261009\n";
}
