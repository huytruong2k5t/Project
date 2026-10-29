#include <algorithm>
#include <array>
#include <deque>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <sstream>
#include <string>
#include "verilated.h"
#include "dut.hpp"
#include "full_term_reference.hpp"

namespace {
constexpr uint64_t SEED = 20261029;
void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}
uint64_t mix(uint64_t x) {
    x += 0x9e3779b97f4a7c15ull;
    x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ull;
    x = (x ^ (x >> 27)) * 0x94d049bb133111ebull;
    return x ^ (x >> 31);
}
struct Transaction {
    uint64_t sequence = 0;
    uint64_t accepted_at = 0;
    uint32_t a = 0, b = 0, c = 0, effective_c = 0;
    bool accumulate = false, clear = false, launched = false, visible = false;
    full_term32::Config cfg{};
    full_term32::Result expected{};
};
Transaction transaction(uint64_t index, const std::string& scenario) {
    Transaction t;
    t.sequence = index;
    t.a = uint32_t(mix(SEED + 7 * index));
    t.b = uint32_t(mix(SEED + 7 * index + 1));
    t.c = uint32_t(mix(SEED + 7 * index + 2));
    t.cfg.n = unsigned(index % 13);
    t.cfg.ops = unsigned((index / 13) % 2);
    t.cfg.approximate = DUT_FUSED || index % 7 != 0;
    t.accumulate = index % 11 >= 7;
    t.clear = t.accumulate && index % 7 == 0;
    if (index % 19 == 0) t.a = 0;
    if (index % 29 == 0) t.b = full_term32::NAR;
    if (index % 41 == 0) t.c = full_term32::NAR;
    if (index % 31 == 0) { t.a = 0x40000000u; t.b = 0x40000000u; t.c = 0xc0000000u; }
    if (index % 43 == 0) { t.a = 0x7fffffffu; t.b = 0x7fffffffu; }
    if (index % 47 == 0) { t.a = 1; t.b = 1; }
    if (index % 23 == 0) t.c = 0;
    if (index % 17 == 0) { t.a = 0x40004000u; t.b = 0x43ffc000u; }
    if (index < 2) {
        t.a = 0x43ffc000u; t.b = 0x43ffc000u; t.c = 0x40000000u;
        t.accumulate = false; t.clear = false;
        t.cfg.approximate = true; t.cfg.ops = unsigned(index); t.cfg.n = index ? 1 : 12;
    }
    if (index == 2) {
        t.a = 0x1c900000; t.b = 0x3c820000; t.c = 0;
        t.accumulate = false; t.clear = false; t.cfg = {true,12,0};
    }
    if (!DUT_FUSED && index % 257 == 17) {
        t.a = 0x43ffffffu; t.b = 0x43ffffffu; t.c = 0;
        t.cfg = {false,15,unsigned(index % 2)};
        t.accumulate = false; t.clear = false;
    }
    const auto npos = scenario.find("_n");
    if (npos != std::string::npos) {
        t.cfg = {true,unsigned(std::stoul(scenario.substr(npos + 2))),1};
        t.accumulate = scenario.rfind("acc_",0) == 0;
        t.clear = t.accumulate && index == 0;
        t.a = 0x43ffc000u; t.b = 0x43ffc000u;
        t.c = 0x40000000u | (uint32_t(mix(index)) & 0x03ffffffu);
    }
    return t;
}
}

int main(int argc, char** argv) try {
    require(argc == 4,"harness count label scenario");
    const uint64_t goal = std::stoull(argv[1]);
    const std::string label = argv[2], scenario = argv[3];
    const bool stress = scenario == "stress" || scenario == "event";
    Verilated::commandArgs(argc,argv);
    DUT dut;
    std::deque<Transaction> pending;
    Transaction source;
    bool source_valid = false, output_held = false, core_active = false;
    uint64_t core_sequence = 0;
    full_term32::Product core_product;
    uint32_t held_d = 0, accumulator = 0;
    unsigned held_flags = 0;
    uint64_t cycles = 0, accepted = 0, completed = 0, aborted = 0, rounds = 0;
    uint64_t prefetch = 0, launch_before_retire = 0, invalid_checks = 0;
    uint64_t ops_stall = 0, c_p2_stall = 0, core_during_ops_stall = 0;
    uint64_t output_stalls = 0, credit_full = 0, simultaneous_accept_retire = 0;
    uint64_t acc_completed = 0, clear_completed = 0, reset_count = 0, max_pending = 0;
    uint64_t first_accept = UINT64_MAX, last_retire = 0;
    uint64_t previous_accept = UINT64_MAX, previous_launch = UINT64_MAX, previous_retire = UINT64_MAX;
    uint64_t accept_ii_sum = 0, launch_ii_sum = 0, retire_ii_sum = 0, launches = 0;
    uint64_t latency_min = UINT64_MAX, latency_max = 0, latency_sum = 0;
    std::array<uint64_t,26> bins{};
    std::array<uint64_t,2> exact_bins{};
    std::array<uint64_t,7> reset_bins{};
    std::array<uint64_t,27> iteration_bins{};
    std::ofstream trace(label+"_trace.csv");
    trace << "edge,accept,launch,done,take,credit,ac_p1_valid,ac_p1_role,ac_p2_valid,ac_p2_role,ops_valid,c_valid,out_valid,out_ready\n";
    std::ofstream event;
    if (scenario == "event") event.open(label+"_event.txt");
    dut.clk = 0; dut.rst_n = 0; dut.in_valid = 0; dut.out_ready = 0;
    dut.a = 0; dut.b = 0; dut.c = 0; dut.acc_mode = 0; dut.acc_clr = 0;
    dut.cfg_mode = 1; dut.cfg_n = 0; dut.cfg_ops = 0; dut.eval();
    while (completed < goal || !pending.empty()) {
        ++cycles;
        require(cycles < goal * 150 + 100000,"watchdog");
        const bool reset = cycles < 5 || (stress && cycles > 100 && cycles % 8191 < 2);
        if (reset) {
            if (!pending.empty()) {
                ++reset_count;
#if !DUT_REFERENCE
                reset_bins[0] += P_FRONT(raw_pending_q) != 0;
                reset_bins[1] += P_FRONT(ac_valid) != 0;
                reset_bins[2] += P_FRONT(ops_valid_q) != 0;
                reset_bins[3] += P_FRONT(c_valid_q) != 0;
                reset_bins[4] += P_FRONT(credit_q) == 2;
#endif
                reset_bins[5] += core_active;
                reset_bins[6] += output_held;
            }
            aborted += pending.size(); pending.clear();
            accumulator = 0; source_valid = false; core_active = false; output_held = false;
        }
        const bool invalid = !reset && cycles >= 10 && cycles < 45;
        if (!reset && !invalid && cycles >= 48 && completed + pending.size() < goal && !source_valid) {
            if (!stress || cycles < 100 || mix(cycles + 9) % 5) {
                source = transaction(accepted,scenario);
                source_valid = true;
            }
        }
        dut.rst_n = !reset;
        dut.out_ready = !stress || (cycles % 4096 >= 128 && mix(cycles + 17) % 4 != 0);
        dut.in_valid = source_valid;
        dut.a = source.a; dut.b = source.b; dut.c = source.c;
        dut.cfg_mode = source.cfg.approximate; dut.cfg_n = source.cfg.n; dut.cfg_ops = source.cfg.ops;
        dut.acc_mode = source.accumulate; dut.acc_clr = source.clear;
        if (invalid) {
            dut.in_valid = 1; dut.cfg_mode = 1; dut.cfg_n = 0; dut.cfg_ops = 0;
            dut.acc_mode = 0; dut.acc_clr = 0;
            switch (cycles % 7) {
                case 0: dut.cfg_ops = 2; break;
                case 1: dut.cfg_ops = 3; break;
                case 2: dut.cfg_n = 13; break;
                case 3: dut.cfg_n = 14; break;
                case 4: dut.cfg_n = 15; break;
                case 5: dut.acc_clr = 1; break;
                default: if (DUT_FUSED) dut.cfg_mode = 0; else dut.cfg_ops = 2; break;
            }
        }
        dut.clk = 0; dut.eval();
        if (invalid) { require(!dut.in_ready,"invalid config accepted"); ++invalid_checks; }
        if (reset) require(!dut.in_ready && !dut.out_valid,"reset public handshake");
        const bool take_input = dut.in_valid && dut.in_ready;
        const bool take_output = dut.out_valid && dut.out_ready;
        if (!reset) {
#if !DUT_REFERENCE
            require(P_FRONT(credit_q) == pending.size(),"credit vs scoreboard");
            credit_full += P_FRONT(credit_q) == 2;
            ops_stall += P_FRONT(ops_valid_q) && !P_LAUNCH;
#if DUT_THREE_PARSER
            c_p2_stall += P_FRONT(cp_valid) && P_FRONT(c_valid_q);
#else
            c_p2_stall += P_FRONT(ac_valid) && P_FRONT(ac_role) && P_FRONT(c_valid_q);
#endif
            core_during_ops_stall += P_FRONT(ops_valid_q) && !P_LAUNCH && P_CORE(t2_valid);
#endif
            if (output_held) require(dut.out_valid && dut.d == held_d && dut.flags == held_flags,"output changed during stall");
            if (take_input) {
                prefetch += !pending.empty();
                source.effective_c = source.accumulate ? (source.clear ? 0 : accumulator) : source.c;
                source.expected = opt17_reference::checked(source.a,source.b,source.effective_c,source.cfg,DUT_FUSED);
                source.accepted_at = cycles;
                pending.push_back(source); ++accepted; source_valid = false;
                first_accept = std::min(first_accept,cycles);
                if (previous_accept != UINT64_MAX) accept_ii_sum += cycles - previous_accept;
                previous_accept = cycles;
            }
            if (P_LAUNCH) {
                auto it = std::find_if(pending.begin(),pending.end(),[](const Transaction& t){return !t.launched;});
                require(it != pending.end() && !core_active,"core launch ownership");
                core_active = true; core_sequence = it->sequence; core_product = it->expected.product;
                if (!it->a || !it->b || it->a == full_term32::NAR || it->b == full_term32::NAR || it->effective_c == full_term32::NAR)
                    core_product = {};
                it->launched = true;
                launch_before_retire += it != pending.begin();
                if (previous_launch != UINT64_MAX) launch_ii_sum += cycles - previous_launch;
                previous_launch = cycles; ++launches;
            }
            if (P_CORE(t2_valid)) {
                require(core_active,"commit without core owner");
                const unsigned iteration = P_CORE(t2_iteration);
                const uint64_t expected = iteration ? core_product.checkpoints[iteration-1] : core_product.value.magnitude;
                require(P_ACC_NEXT == expected,"per-round M/Q mismatch seq="+std::to_string(core_sequence));
                ++rounds;
            }
            if (P_WRAPPER(core_done)) {
                require(core_active,"done without core owner");
                require(P_WRAPPER(acc) == core_product.value.magnitude,"final prepack mismatch");
                require(P_ITER == core_product.iterations,"iteration count mismatch");
                ++iteration_bins[P_ITER]; core_active = false;
            }
            if (dut.out_valid) {
                require(!pending.empty(),"duplicate/unowned output");
                auto& head = pending.front();
                if (dut.d != head.expected.bits || dut.flags != head.expected.flags) {
                    std::ostringstream msg;
                    msg << "MAC mismatch seq=" << head.sequence << " a/b/c=" << std::hex << head.a << '/' << head.b << '/' << head.effective_c
                        << " got=" << dut.d << '/' << unsigned(dut.flags) << " expected=" << head.expected.bits << '/' << head.expected.flags;
                    throw std::runtime_error(msg.str());
                }
                if (!head.visible) {
                    head.visible = true;
                    if (head.accumulate) accumulator = head.expected.bits;
                }
                output_held = !dut.out_ready;
                held_d = dut.d; held_flags = dut.flags;
                output_stalls += output_held;
            } else output_held = false;
            if (take_output) {
                const auto head = pending.front();
                const uint64_t latency = cycles - head.accepted_at;
                latency_min = std::min(latency_min,latency); latency_max = std::max(latency_max,latency); latency_sum += latency;
                if (head.cfg.approximate) ++bins[2*head.cfg.n+head.cfg.ops]; else ++exact_bins[head.cfg.ops];
                acc_completed += head.accumulate; clear_completed += head.clear;
                if (previous_retire != UINT64_MAX) retire_ii_sum += cycles - previous_retire;
                previous_retire = cycles;
                pending.pop_front(); ++completed; last_retire = cycles;
            }
            simultaneous_accept_retire += take_input && take_output;
            max_pending = std::max<uint64_t>(max_pending,pending.size());
            require(accepted == completed + aborted + pending.size(),"transaction conservation");
            require(pending.size() <= (DUT_REFERENCE ? 1 : 2),"outstanding bound");
        }
        if (event) {
            event << std::hex << unsigned(dut.rst_n) << ' ' << unsigned(dut.in_valid) << ' ' << unsigned(dut.out_ready)
                  << ' ' << dut.a << ' ' << dut.b << ' ' << dut.c << ' ' << unsigned(dut.acc_mode) << ' ' << unsigned(dut.acc_clr)
                  << ' ' << unsigned(dut.cfg_mode) << ' ' << unsigned(dut.cfg_n) << ' ' << unsigned(dut.cfg_ops)
                  << ' ' << unsigned(dut.in_ready) << ' ' << unsigned(dut.out_valid) << ' ' << dut.d << ' ' << unsigned(dut.flags) << '\n';
        }
        const bool launch_edge = !reset && P_LAUNCH;
        const bool done_edge = !reset && P_WRAPPER(core_done);
#if !DUT_REFERENCE
        const bool result_edge = !reset && P_WRAPPER(result_take);
#endif
        dut.clk = 1; dut.eval(); Verilated::timeInc(5);
        dut.clk = 0; dut.eval(); Verilated::timeInc(5);
        if (first_accept != UINT64_MAX && cycles - first_accept < 48) {
#if !DUT_REFERENCE
            trace << cycles-first_accept << ',' << take_input << ',' << launch_edge << ',' << done_edge << ',' << result_edge
                  << ',' << unsigned(P_FRONT(credit_q)) << ',' << unsigned(P_AC(p1_valid_q)) << ',' << unsigned(P_AC(p1_role_q))
                  << ',' << unsigned(P_FRONT(ac_valid)) << ',' << unsigned(P_FRONT(ac_role))
                  << ',' << unsigned(P_FRONT(ops_valid_q)) << ',' << unsigned(P_FRONT(c_valid_q))
                  << ',' << unsigned(dut.out_valid) << ',' << unsigned(dut.out_ready) << '\n';
#else
            (void)launch_edge; (void)done_edge;
#endif
        }
    }
    std::ofstream out(label+".json");
    out << "{\"status\":\"PASS\",\"seed\":" << SEED << ",\"scenario\":\"" << scenario
        << "\",\"accepted\":" << accepted << ",\"completed\":" << completed << ",\"reset_aborted\":" << aborted
        << ",\"cycles\":" << cycles << ",\"span_accept_to_last_retire\":" << last_retire-first_accept
        << ",\"mismatches\":0,\"round_checks\":" << rounds << ",\"max_outstanding\":" << max_pending
        << ",\"prefetch_accepts\":" << prefetch << ",\"launch_before_previous_retire\":" << launch_before_retire
        << ",\"ops_stall_cycles\":" << ops_stall << ",\"c_at_p2_stall_cycles\":" << c_p2_stall
        << ",\"core_commits_during_ops_stall\":" << core_during_ops_stall << ",\"credit_full_cycles\":" << credit_full
        << ",\"output_stall_cycles\":" << output_stalls << ",\"simultaneous_accept_retire\":" << simultaneous_accept_retire
        << ",\"acc_completed\":" << acc_completed << ",\"clear_completed\":" << clear_completed
        << ",\"invalid_config_checks\":" << invalid_checks << ",\"reset_events_with_tokens\":" << reset_count
        << ",\"accept_ii_sum\":" << accept_ii_sum << ",\"launch_ii_sum\":" << launch_ii_sum << ",\"launches\":" << launches
        << ",\"retire_ii_sum\":" << retire_ii_sum << ",\"latency_min\":" << latency_min << ",\"latency_max\":" << latency_max
        << ",\"latency_sum\":" << latency_sum << ",\"n_ops_bins\":[";
    for (unsigned i=0;i<bins.size();++i) out << (i?",":"") << bins[i];
    out << "],\"exact_ops_bins\":[" << exact_bins[0] << ',' << exact_bins[1] << "],\"reset_bins\":[";
    for (unsigned i=0;i<reset_bins.size();++i) out << (i?",":"") << reset_bins[i];
    out << "],\"iteration_bins\":[";
    for (unsigned i=0;i<iteration_bins.size();++i) out << (i?",":"") << iteration_bins[i];
    out << "]}\n";
    std::cout << "OPT17_PASS completed=" << completed << " aborted=" << aborted << " cycles=" << cycles << " mismatch=0\n";
} catch (const std::exception& e) {
    std::cerr << "OPT17_FAIL " << e.what() << '\n'; return 1;
}
