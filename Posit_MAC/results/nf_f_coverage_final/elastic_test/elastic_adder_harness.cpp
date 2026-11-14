#include <cstdint>
#include <deque>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>
#include "verilated.h"
#include "verilated_cov.h"
#include "Velastic_adder_top.h"

struct Vec {
    uint32_t a, b, exp_d, exp_flags;
};

static uint32_t lcg(uint64_t& s) {
    s = s * 6364136223846793005ULL + 1442695040888963407ULL;
    return uint32_t(s >> 32);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    if (argc < 4) {
        std::cerr << "Usage: elastic_cov vec.txt out.json cov.dat\n";
        return 1;
    }
    std::vector<Vec> vecs;
    {
        std::ifstream fin(argv[1]);
        uint32_t a, b, ed, ef;
        while (fin >> std::hex >> a >> b >> ed >> ef) {
            vecs.push_back({a, b, ed, ef});
        }
    }

    Velastic_adder_top dut;
    dut.clk = 0;
    dut.reset_n = 0;
    dut.in_valid = 0;
    dut.a = 0;
    dut.b = 0;
    dut.out_ready = 0;

    auto step = [&]() {
        dut.eval();
        dut.clk = 1;
        dut.eval();
        dut.clk = 0;
        dut.eval();
    };

    for (int i = 0; i < 6; ++i) step();
    dut.reset_n = 1;
    for (int i = 0; i < 4; ++i) step();

    std::deque<Vec> q;
    size_t idx = 0;
    uint64_t seed = 0x20261114ULL;
    uint64_t completed = 0;
    uint64_t stall_cycles = 0;
    uint64_t back_to_back_accepts = 0;
    bool prev_accepted = false;
    bool prev_stall_hold = false;
    uint32_t held_d = 0, held_flags = 0;

    for (uint64_t cyc = 0; cyc < 1000000 && (idx < vecs.size() || !q.empty()); ++cyc) {
        // Drive next inputs & stall pattern: bursts of out_ready=0 to backpressure all 9 stages
        bool stall_burst = ((cyc % 37) >= 12 && (cyc % 37) <= 21) || ((lcg(seed) % 5) == 0);
        dut.out_ready = stall_burst ? 0 : 1;

        if (idx < vecs.size()) {
            bool drop_in = ((lcg(seed) % 16) == 0); // occasional bubble plus long back-to-back runs
            dut.in_valid = drop_in ? 0 : 1;
            dut.a = vecs[idx].a;
            dut.b = vecs[idx].b;
        } else {
            dut.in_valid = 0;
        }

        dut.eval();
        bool acc = dut.in_valid && dut.in_ready;
        bool ret = dut.out_valid && dut.out_ready;
        if (stall_burst && dut.out_valid) stall_cycles++;

        if (prev_stall_hold) {
            if (!dut.out_valid || dut.d != held_d || dut.flags != held_flags) {
                throw std::runtime_error("Output mutated under stall!");
            }
        }
        prev_stall_hold = (dut.out_valid && !dut.out_ready);
        if (prev_stall_hold) {
            held_d = dut.d;
            held_flags = dut.flags;
        }

        if (acc) {
            if (prev_accepted) back_to_back_accepts++;
            q.push_back(vecs[idx]);
            idx++;
        }
        prev_accepted = acc;

        if (ret) {
            if (q.empty()) throw std::runtime_error("Unexpected output retire");
            Vec exp = q.front();
            q.pop_front();
            if (dut.d != exp.exp_d || (dut.flags & 0x1E) != (exp.exp_flags & 0x1E)) {
                std::ostringstream oss;
                oss << "Mismatch at completed=" << completed << " a=" << std::hex << exp.a
                    << " b=" << exp.b << " got d=" << dut.d << " flags=" << dut.flags
                    << " exp d=" << exp.exp_d << " flags=" << exp.exp_flags;
                throw std::runtime_error(oss.str());
            }
            completed++;
        }

        dut.clk = 1;
        dut.eval();
        dut.clk = 0;
        dut.eval();
    }

    if (completed != vecs.size()) {
        throw std::runtime_error("Incomplete drain: " + std::to_string(completed) + "/" + std::to_string(vecs.size()));
    }
    VerilatedCov::write(argv[3]);
    std::ofstream fout(argv[2]);
    fout << "{\n"
         << "  \"status\": \"PASS\",\n"
         << "  \"completed\": " << completed << ",\n"
         << "  \"mismatches\": 0,\n"
         << "  \"stall_cycles_with_out_valid\": " << stall_cycles << ",\n"
         << "  \"back_to_back_accepts\": " << back_to_back_accepts << "\n"
         << "}\n";
    std::cout << "ELASTIC_PASS completed=" << completed << " stall_cycles=" << stall_cycles
              << " b2b=" << back_to_back_accepts << "\n";
    dut.final();
    return 0;
}
