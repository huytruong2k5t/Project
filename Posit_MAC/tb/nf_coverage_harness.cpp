#include <array>
#include <fstream>
#include <iostream>
#include <random>
#include <stdexcept>
#include <string>
#include "Vposit_mac_nf.h"
#include "verilated.h"
#include "verilated_cov.h"
#include "week11_model.hpp"
#include "nf_coverage_corpus.hpp"
#include "Vposit_mac_nf___024root.h"
#include "softposit_api.h"
#ifndef PROFILE_NB
#define PROFILE_NB 32
#endif
#ifndef PROFILE_ES
#define PROFILE_ES 3
#endif
namespace {
constexpr int NB = PROFILE_NB, ES = PROFILE_ES;
constexpr unsigned F = NB-3-ES, FW = F < 12 ? F : 12;
constexpr uint32_t NAR = uint32_t(1) << (NB-1);
constexpr uint32_t MASK = uint32_t((uint64_t(1) << NB)-1);
using Model = week11::Model<NB, ES, FW>;
void require(bool ok, const char* msg) { if (!ok) throw std::runtime_error(msg); }
int signed_sf(unsigned value) {
    constexpr unsigned width = []() {
        unsigned value = 4*(NB-2)*(1u<<ES)+4, bits=0;
        --value;
        while (value) { ++bits; value >>= 1; }
        return bits+1;
    }();
    return int(value ^ (1u << (width-1))) - int(1u << (width-1));
}
unsigned regime_key(uint32_t mag) {
    const bool polarity = bool((mag >> (NB-2)) & 1);
    unsigned run=0;
    for (int bit=NB-2; bit>=0 && bool((mag>>bit)&1)==polarity; --bit) ++run;
    return 32*unsigned(polarity)+run;
}
std::array<uint64_t,7> pack_bins(uint32_t mag, bool g, bool r, bool st,
                                  unsigned special, unsigned flags) {
    std::array<uint64_t,7> bins{};
    if (special==0) {
        const bool up=g && ((mag&1) || r || st);
        const bool discarded=g || r || st;
        const bool tie=g && !r && !st;
        bins[0]=up;
        bins[1]=discarded && !up;
        bins[2]=tie && up;
        bins[3]=tie && !up;
        bins[6]=up && mag && mag<NAR-1 && regime_key(mag)!=regime_key(mag+1);
    }
    bins[4]=special==3 && bool(flags&8);
    bins[5]=special==4 && bool(flags&4);
    return bins;
}
int regime_group(uint32_t raw) {
    if(!raw || raw==NAR) return -1;
    const uint32_t mag=(raw&NAR)?(0u-raw)&MASK:raw;
    const bool polarity=(mag>>(NB-2))&1;
    unsigned run=0;
    for(int i=NB-2;i>=0 && bool((mag>>i)&1)==polarity;--i) ++run;
    constexpr unsigned hi[]={3,7,11,15,17,22,27,31};
    for(unsigned g=0;g<8;++g) if(run<=hi[g]) return int(g);
    throw std::runtime_error("regime group");
}
}
int main(int argc, char** argv) try {
    if (argc != 3) throw std::invalid_argument("harness completed_goal output_prefix");
    const uint64_t goal = std::stoull(argv[1]);
    const std::string prefix = argv[2];
    Verilated::commandArgs(argc, argv);
    Vposit_mac_nf dut;
    const uint64_t seed = 20261014 + 100*NB + ES;
    std::mt19937_64 rng(seed);
    uint64_t accepted=0, completed=0, aborts=0, cycles=0, output_stalls=0, input_stalls=0;
    uint64_t reset_busy=0, reset_stalled=0, long_stalls=0, acc_commits=0, clears=0;
    uint64_t l0_checks=0, oracle_checks=0, invalid_checks=0;
    uint64_t first_valid_min=1000000, first_valid_max=0, handshake_min=1000000, handshake_max=0;
    std::array<uint64_t, 72> bins{};
    std::array<uint64_t,256> regime_bins{};
    std::array<uint64_t,70> add_bins{};
    std::array<uint64_t,7> iteration_bins{};
    std::array<uint64_t,5> flag_bins{};
    std::array<uint64_t,64> run_bins{};
    std::array<uint64_t,6> pop_bins{};
    std::array<uint64_t,14> iteration_mode_bins{};
    std::array<uint64_t,7> product_pack_bins{}, final_pack_bins{};
    std::array<uint64_t,7> pending_product_pack{}, pending_final_pack{};
    std::array<uint64_t,10> near_delta{};
    std::array<uint64_t,2> completed_mode{}, specials{}, finite_add_mode{};
    std::array<uint32_t,2> pending_operands{};
    uint32_t pending_effective=0, pending_c_port=0;
    unsigned pending_pop=0, pending_mode=0, pending_n=0, pending_ops=0;
    int pending_near=-1;
    bool observed_product=false, observed_add=false, observed_final=false, observed_pop=false;
    uint64_t rtl_adder_checks=0, product_pack_events=0, final_pack_events=0;
    int pending_regime=-1;
    bool pending=false, source=false, held=false, seen_valid=false;
    uint32_t accumulator=0, held_bits=0;
    unsigned held_flags=0, pending_bin=0;
    uint64_t launch_cycle=0;
    bool pending_acc=false;
    Model::Result expected{};
    dut.clk=0; dut.rst_n=0; dut.in_valid=0; dut.out_ready=0;
    dut.a=0; dut.b=0; dut.c=0; dut.cfg_mode=0; dut.cfg_n=0; dut.cfg_ops=0;
    dut.acc_mode=0; dut.acc_clr=0; dut.eval();
    while (completed < goal || pending) {
        ++cycles;
        const bool reset = cycles < 4 || cycles%4093==0 || cycles%4093==1
                        || (held && cycles%4096==160);
        if (reset) {
            reset_busy += pending;
            reset_stalled += held;
            aborts += pending;
            pending=false; source=false; held=false; accumulator=0;
        }
        if (!reset && completed < goal && !source && !pending && rng()%5) {
            const auto v = nf_coverage::Corpus<NB,ES>::next(rng, accepted, accumulator);
            dut.a=v.a; dut.b=v.b; dut.c=v.c;
            dut.cfg_n=v.n; dut.cfg_ops=v.ops; dut.cfg_mode=v.mode;
            dut.acc_mode=v.acc_mode; dut.acc_clr=v.acc_clr;
            source=true;
        }
        if (pending && !source) {
            // External context is free to change after its handshake.
            dut.a=uint32_t(rng())&MASK;
            dut.b=uint32_t(rng())&MASK;
            dut.c=uint32_t(rng())&MASK;
            dut.cfg_mode=unsigned(rng()&1);
            dut.cfg_n=unsigned(rng()%9);
            dut.cfg_ops=unsigned(rng()%4);
            dut.acc_mode=unsigned(rng()&1);
            dut.acc_clr=unsigned(rng()&1);
        }
        dut.rst_n=!reset;
        dut.in_valid=!reset && source;
        const bool long_block=cycles%4096>=100 && cycles%4096<196;
        dut.out_ready=!reset && !long_block && rng()%4!=0;
        // Invalid requests are tested only when no legitimate request is held.
        const bool invalid=!reset && !pending && !source && cycles%31==0;
        if (invalid) {
            dut.in_valid=1;
            dut.cfg_ops=2+unsigned((cycles/31)&1);
        }
        dut.clk=0; dut.eval();
        if (!reset) {
            if (invalid) { require(!dut.in_ready,"reserved config accepted"); ++invalid_checks; }
            if (held) require(dut.out_valid && dut.d==held_bits && dut.flags==held_flags,
                              "output changed while stalled");
            const auto& rt = *dut.rootp;
            if (pending && rt.posit_mac_nf__DOT__u_wrapper__DOT__pair_retire) {
                const auto x=rt.posit_mac_nf__DOT__u_wrapper__DOT__ops_x;
                const unsigned count=unsigned(__builtin_popcount(x));
                pending_pop=count<=2 ? count : count<=4 ? 3 : count<=8 ? 4 : 5;
                observed_pop=!rt.posit_mac_nf__DOT__u_wrapper__DOT__bypass;
            }
            if (pending && rt.posit_mac_nf__DOT__u_wrapper__DOT__core_done) {
                pending_product_pack=pack_bins(
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_mag_trunc_d,
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_guard_bit_d,
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_round_bit_d,
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_sticky_bit_d,
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_special_sel_d,
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_flags_d);
                require(!observed_product, "duplicate product token");
                observed_product=true;
            }
            if (pending && rt.posit_mac_nf__DOT__u_wrapper__DOT__norm_valid_q &&
                           rt.posit_mac_nf__DOT__u_wrapper__DOT__add_ready) {
                const auto p=l1::parse<NB,ES>(expected.product);
                const auto c=l1::parse<NB,ES>(pending_effective);
                const auto& actual_sf=rt.posit_mac_nf__DOT__u_wrapper__DOT__norm_sf_q;
                const auto actual_frac=rt.posit_mac_nf__DOT__u_wrapper__DOT__product_frac_q;
                require(rt.posit_mac_nf__DOT__u_wrapper__DOT__norm_sign_q==p.sign &&
                        rt.posit_mac_nf__DOT__u_wrapper__DOT__norm_zero_q==p.is_zero &&
                        rt.posit_mac_nf__DOT__u_wrapper__DOT__norm_nar_q==p.is_nar,
                        "product adapter specials differ");
                // A/B/C NaR bypass may mark the product NaR independent of A*B.
                if (!p.is_zero && !p.is_nar) {
                    require(signed_sf(actual_sf)==p.sf && actual_frac==((p.frac>>(63-F))&((uint64_t(1)<<F)-1)),
                            "RTL product adapter differs from oracle");
                }
                require(rt.posit_mac_nf__DOT__u_wrapper__DOT__c_sign_q==c.sign &&
                        rt.posit_mac_nf__DOT__u_wrapper__DOT__c_zero_q==c.is_zero &&
                        rt.posit_mac_nf__DOT__u_wrapper__DOT__c_nar_q==c.is_nar,
                        "RTL C_eff specials differ");
                if (!c.is_zero && !c.is_nar) {
                    require(signed_sf(rt.posit_mac_nf__DOT__u_wrapper__DOT__c_sf_q)==c.sf &&
                            rt.posit_mac_nf__DOT__u_wrapper__DOT__c_frac_q==((c.frac>>(63-F))&((uint64_t(1)<<F)-1)),
                            "RTL C_eff differs from accepted state");
                }
                pending_near=-1;
                if (!p.is_zero && !p.is_nar && !c.is_zero && !c.is_nar && p.sign!=c.sign) {
                    const int delta=std::abs(signed_sf(actual_sf)-
                        signed_sf(rt.posit_mac_nf__DOT__u_wrapper__DOT__c_sf_q));
                    if (delta<=4) pending_near=delta;
                }
                require(!observed_add, "duplicate adder token");
                observed_add=true;
                ++rtl_adder_checks;
            }
            if (pending && rt.posit_mac_nf__DOT__u_wrapper__DOT__add_valid &&
                           rt.posit_mac_nf__DOT__u_wrapper__DOT__pack_ready) {
                pending_final_pack=pack_bins(
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_pack__DOT__p1_mag_trunc_d,
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_pack__DOT__p1_guard_bit_d,
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_pack__DOT__p1_round_bit_d,
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_pack__DOT__p1_sticky_bit_d,
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_pack__DOT__p1_special_sel_d,
                    rt.posit_mac_nf__DOT__u_wrapper__DOT__u_pack__DOT__p1_flags_d);
                require(!observed_final, "duplicate final packer token");
                observed_final=true;
            }
            if (dut.out_valid) {
                require(pending,"unexpected/duplicate output");
                if (dut.d!=expected.bits || dut.flags!=expected.flags) {
                    std::cerr<<"Mismatch NB="<<NB<<" ES="<<ES<<" serial="<<accepted
                             <<" expected="<<std::hex<<expected.bits<<" actual="<<dut.d
                             <<" flags="<<expected.flags<<'/'<<unsigned(dut.flags)<<std::dec<<'\n';
                    std::ofstream fail(prefix+"_failure.json");
                    fail << "{\"a\":" << pending_operands[0]
                         << ",\"b\":" << pending_operands[1]
                         << ",\"c_port\":" << pending_c_port
                         << ",\"c_effective\":" << pending_effective
                         << ",\"acc_mode\":" << pending_acc
                         << ",\"mode\":" << pending_mode
                         << ",\"n\":" << pending_n << ",\"ops\":" << pending_ops
                         << ",\"expected\":" << expected.bits
                         << ",\"actual\":" << unsigned(dut.d)
                         << ",\"expected_flags\":" << expected.flags
                         << ",\"actual_flags\":" << unsigned(dut.flags) << "}\n";
                    throw std::runtime_error("RTL versus new NF model/oracle");
                }
                if (!seen_valid) {
                    const uint64_t latency=cycles-launch_cycle-1;
                    require(latency==std::max(1u,expected.iterations)+12,"valid latency differs from contract");
                    first_valid_min=std::min(first_valid_min,latency);
                    first_valid_max=std::max(first_valid_max,latency);
                    if (pending_acc) { accumulator=expected.bits; ++acc_commits; }
                    seen_valid=true;
                }
            }
            if (dut.out_valid && dut.out_ready) {
                handshake_min=std::min(handshake_min,cycles-launch_cycle);
                handshake_max=std::max(handshake_max,cycles-launch_cycle);
                require(observed_product && observed_add && observed_final, "missing passive token");
                ++completed_mode[unsigned(pending_acc)];
                if (pending_near>=0) ++near_delta[5*unsigned(pending_acc)+unsigned(pending_near)];
                specials[unsigned(pending_acc)]+=!expected.finite_add;
                finite_add_mode[unsigned(pending_acc)]+=expected.finite_add;
                for (auto raw:pending_operands) {
                    if (raw && raw!=NAR) {
                        const uint32_t mag=(raw&NAR) ? (0u-raw)&MASK : raw;
                        ++run_bins[regime_key(mag)];
                    }
                }
                if (observed_pop) ++pop_bins[pending_pop];
                const unsigned it=expected.iterations;
                ++iteration_mode_bins[7*pending_mode+(it<=4 ? it : it<=8 ? 5 : 6)];
                for (unsigned i=0; i<7; ++i) {
                    product_pack_bins[i]+=pending_product_pack[i];
                    final_pack_bins[i]+=pending_final_pack[i];
                }
                ++product_pack_events; ++final_pack_events;
                ++bins[pending_bin]; ++completed; pending=false;
                if(pending_regime>=0) ++regime_bins[unsigned(pending_regime)];
                if(expected.finite_add)
                    ++add_bins[expected.delta_bucket*14+unsigned(expected.same_sign)*7+expected.add_class];
                const unsigned t=expected.iterations;
                ++iteration_bins[t<=4?t:t<=8?5:6];
                for(unsigned i=0;i<5;++i) flag_bins[i]+=bool(expected.flags&(1u<<i));
                if (completed%1000000==0)
                    std::cout<<"CHECKPOINT NB="<<NB<<" ES="<<ES<<" completed="<<completed<<std::endl;
            }
            if (dut.in_valid && dut.in_ready) {
                require(!pending,"more than one transaction in flight");
                const uint32_t effective=dut.acc_mode ? (dut.acc_clr ? 0 : accumulator) : uint32_t(dut.c);
                expected=Model::mac(dut.a,dut.b,effective,!dut.cfg_mode,dut.cfg_n,dut.cfg_ops);
                pending_operands={uint32_t(dut.a),uint32_t(dut.b)};
                pending_effective=effective; pending_c_port=dut.c;
                pending_mode=dut.cfg_mode; pending_n=dut.cfg_n; pending_ops=dut.cfg_ops;
                pending_near=-1;
                observed_product=observed_add=observed_final=observed_pop=false;
                pending_product_pack={}; pending_final_pack={};
                ++oracle_checks;
                if (!dut.cfg_mode && ES!=3) {
                    uint32_t ref;
                    if constexpr (NB==8) ref=l0_p8_add(l0_p8_mul(dut.a,dut.b),effective);
                    else if constexpr (NB==16) ref=l0_p16_add(l0_p16_mul(dut.a,dut.b),effective);
                    else ref=l0_p32_add(l0_p32_mul(dut.a,dut.b),effective);
                    require(ref==expected.bits,"NF exact L0 mismatch"); ++l0_checks;
                }
                pending_bin=unsigned(dut.cfg_n)+9*unsigned(dut.cfg_ops)
                           +18*unsigned(dut.cfg_mode)+36*unsigned(dut.acc_mode);
                const int ga=regime_group(dut.a), gb=regime_group(dut.b);
                pending_regime=ga<0 || gb<0 ? -1 : ga*32+gb*4
                             +2*int(bool(dut.a&NAR))+int(bool(dut.b&NAR));
                pending_acc=dut.acc_mode;
                if (dut.acc_mode && dut.acc_clr) { accumulator=0; ++clears; }
                pending=true; seen_valid=false; launch_cycle=cycles;
                ++accepted; source=false;
            }
            held=dut.out_valid && !dut.out_ready;
            held_bits=dut.d; held_flags=dut.flags;
            output_stalls+=held;
            input_stalls+=dut.in_valid && !dut.in_ready;
            long_stalls+=held && long_block;
        }
        dut.clk=1; dut.eval();
        if (reset) require(!dut.in_ready && !dut.out_valid,"reset gating failed");
        require(cycles < goal*100+10000,"timeout/deadlock");
    }
    dut.final();
    require(accepted==completed+aborts,"reset accounting");
    if (!(reset_busy && reset_stalled && long_stalls && clears && acc_commits)) {
        std::cerr<<"Coverage counters reset_busy="<<reset_busy<<" reset_stalled="<<reset_stalled
                 <<" long_stalls="<<long_stalls<<" clears="<<clears<<" acc="<<acc_commits<<'\n';
        throw std::runtime_error("missing protocol coverage");
    }
    for (auto count:bins) require(count>0,"missing config/control bin");
    if(NB==32 && goal>=10000000)
        for(auto count:regime_bins) require(count>0,"missing regime/sign cross bin");
    VerilatedCov::write((prefix+"_coverage.dat").c_str());
    std::ofstream report(prefix+"_summary.json");
    report<<"{\"NB\":"<<NB<<",\"ES\":"<<ES<<",\"seed\":"<<seed
          <<",\"accepted\":"<<accepted<<",\"completed\":"<<completed<<",\"reset_aborts\":"<<aborts
          <<",\"cycles\":"<<cycles<<",\"output_stalls\":"<<output_stalls<<",\"input_stalls\":"<<input_stalls
          <<",\"reset_busy\":"<<reset_busy<<",\"reset_stalled\":"<<reset_stalled
          <<",\"long_stalls\":"<<long_stalls<<",\"acc_commits\":"<<acc_commits<<",\"clears\":"<<clears
          <<",\"oracle_checks\":"<<oracle_checks<<",\"L0_checks\":"<<l0_checks
          <<",\"invalid_checks\":"<<invalid_checks<<",\"first_valid_min\":"<<first_valid_min
          <<",\"first_valid_max\":"<<first_valid_max<<",\"handshake_min\":"<<handshake_min
          <<",\"handshake_max\":"<<handshake_max<<",\"mismatches\":0,\"bins\":[";
    for (unsigned i=0;i<bins.size();++i) report<<(i?",":"")<<bins[i];
    report<<"],\"regime_sign_bins\":[";
    for(unsigned i=0;i<regime_bins.size();++i) report<<(i?",":"")<<regime_bins[i];
    report<<"],\"adder_bins\":[";
    for(unsigned i=0;i<add_bins.size();++i) report<<(i?",":"")<<add_bins[i];
    report<<"],\"iteration_bins\":[";
    for(unsigned i=0;i<iteration_bins.size();++i) report<<(i?",":"")<<iteration_bins[i];
    report<<"],\"flag_bins\":[";
    for(unsigned i=0;i<flag_bins.size();++i) report<<(i?",":"")<<flag_bins[i];
    report<<"],\"run_polarity_bins\":[";
    for (unsigned i=0;i<run_bins.size();++i) report<<(i?",":"")<<run_bins[i];
    report<<"],\"popcount_bins\":[";
    for (unsigned i=0;i<pop_bins.size();++i) report<<(i?",":"")<<pop_bins[i];
    report<<"],\"iteration_mode_bins\":[";
    for (unsigned i=0;i<iteration_mode_bins.size();++i) report<<(i?",":"")<<iteration_mode_bins[i];
    report<<"],\"product_packer_bins\":[";
    for (unsigned i=0;i<7;++i) report<<(i?",":"")<<product_pack_bins[i];
    report<<"],\"final_packer_bins\":[";
    for (unsigned i=0;i<7;++i) report<<(i?",":"")<<final_pack_bins[i];
    report<<"],\"near_delta_standalone_acc\":[";
    for (unsigned i=0;i<10;++i) report<<(i?",":"")<<near_delta[i];
    report<<"],\"completed_standalone_acc\":["<<completed_mode[0]<<","<<completed_mode[1]
          <<"],\"non_finite_add_standalone_acc\":["<<specials[0]<<","<<specials[1]
          <<"],\"finite_add_standalone_acc\":["<<finite_add_mode[0]<<","<<finite_add_mode[1]
          <<"],\"rtl_adder_checks\":"<<rtl_adder_checks
          <<",\"product_packer_events\":"<<product_pack_events
          <<",\"final_packer_events\":"<<final_pack_events<<"}\n";
    std::cout<<"NF COVERAGE HARNESS PASS NB="<<NB<<" ES="<<ES<<" completed="<<completed
             <<" reset_aborts="<<aborts<<" mismatches=0"<<std::endl;
} catch (const std::exception& e) {
    std::cerr<<"FAIL: "<<e.what()<<'\n'; return 1;
}
