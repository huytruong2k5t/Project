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
uint32_t operand(std::mt19937_64& rng, uint64_t serial) {
    if constexpr (NB != 32) return uint32_t(rng()) & MASK;
    if (serial % 3 == 0) return uint32_t(rng());
    constexpr unsigned lo[] = {1,4,8,12,16,18,23,28};
    constexpr unsigned hi[] = {3,7,11,15,17,22,27,31};
    const unsigned group = unsigned((serial/2)%8);
    const bool polarity = serial&1, negative = (serial/16)&1;
    const unsigned end = std::min(hi[group], polarity ? 31u : 30u);
    const unsigned run = lo[group] + unsigned((serial/32)%(end-lo[group]+1));
    uint32_t mag = 0;
    for (int bit = 30; bit > 30-int(run); --bit) if (polarity) mag |= uint32_t(1)<<bit;
    unsigned left = 31-run;
    if (left) { if (!polarity) mag |= uint32_t(1)<<(left-1); --left; }
    const unsigned eb = std::min(unsigned(ES), left), fb = left-eb;
    const uint32_t mask = fb ? (uint32_t(1)<<fb)-1 : 0;
    uint32_t frac = uint32_t(rng()) & mask;
    switch ((serial/64)%6) {
        case 0: frac=0; break;
        case 1: frac=mask; break;
        case 2: frac=0xaaaaaaaa&mask; break;
        case 3: frac=0x55555555&mask; break;
        case 4: frac=fb ? uint32_t(1)<<(rng()%fb) : 0; break;
        default: break;
    }
    mag |= (uint32_t(rng())&((uint32_t(1)<<eb)-1))<<fb;
    mag |= frac;
    return negative ? 0u-mag : mag;
}
uint32_t stratified(std::mt19937_64& rng, unsigned group, bool negative, bool polarity) {
    constexpr unsigned lo[]={1,4,8,12,16,18,23,28};
    constexpr unsigned hi[]={3,7,11,15,17,22,27,31};
    const unsigned end=std::min(hi[group],polarity ? 31u : 30u);
    const unsigned run=lo[group]+unsigned(rng()%(end-lo[group]+1));
    uint32_t mag=0;
    for(int i=30;i>30-int(run);--i) if(polarity) mag|=uint32_t(1)<<i;
    const unsigned left=31-run;
    if(left) {
        if(!polarity) mag|=uint32_t(1)<<(left-1);
        mag|=uint32_t(rng())&((uint32_t(1)<<(left-1))-1);
    }
    return negative ? 0u-mag : mag;
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
    const uint64_t seed = 20261013 + 100*NB + ES;
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
            dut.a=operand(rng, accepted);
            dut.b=operand(rng, accepted+39);
            dut.c=operand(rng, accepted+77);
            if constexpr (NB==32) {
                const uint64_t cross=accepted/128;
                dut.a=stratified(rng,unsigned(cross%8),bool((cross/64)&1),bool(accepted&1));
                dut.b=stratified(rng,unsigned((cross/8)%8),bool((cross/128)&1),bool((accepted/2)&1));
            }
            dut.cfg_n=accepted%9;
            dut.cfg_ops=(accepted/9)%2;
            dut.cfg_mode=(accepted/18)%2;
            dut.acc_mode=(accepted/36)%2;
            dut.acc_clr=dut.acc_mode && (accepted/72)%11==0;
            const uint32_t one = uint32_t(1)<<(NB-2);
            switch (accepted%128) {
                case 0: dut.a=0; dut.b=NAR; break;
                case 1: dut.a=NAR; dut.b=0; break;
                case 2: dut.c=NAR; break;
                case 3: dut.a=0; break;
                case 4: dut.b=0; break;
                case 5: dut.c=0; break;
                case 6: dut.a=NAR-1; dut.b=NAR-1; dut.c=(0u-(NAR-1))&MASK; break;
                case 7: dut.a=1; dut.b=1; dut.c=1; break;
                case 8: dut.a=one; dut.b=one; dut.c=(0u-one)&MASK; break;
                case 9: dut.a=one; dut.b=one; dut.c=(0u-one+1)&MASK; break;
                case 10: dut.a=(0u-one)&MASK; dut.b=one; dut.c=one; break;
                case 13: case 14: case 15: case 16: {
                    const unsigned shifts[]={1,3,8,20};
                    const unsigned shift=std::min(shifts[accepted%128-13],F);
                    l1::posit_unpacked<NB,ES> cu{true,false,false,-1,
                        uint64_t(0)-(uint64_t(1)<<(64-shift)),true};
                    dut.a=one; dut.b=one; dut.c=l1::pack<NB,ES>(cu);
                    break;
                }
                default: break;
            }
            // Additional cancellation candidates use the actual comparison product.
            if (accepted%128==11 || accepted%128==12) {
                const auto p=Model::mac(dut.a, dut.b, 0, !dut.cfg_mode, dut.cfg_n, dut.cfg_ops);
                dut.c=(0u-p.product+uint32_t(accepted%128==12))&MASK;
            }
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
            if (dut.out_valid) {
                require(pending,"unexpected/duplicate output");
                if (dut.d!=expected.bits || dut.flags!=expected.flags) {
                    std::cerr<<"Mismatch NB="<<NB<<" ES="<<ES<<" serial="<<accepted
                             <<" expected="<<std::hex<<expected.bits<<" actual="<<dut.d
                             <<" flags="<<expected.flags<<'/'<<unsigned(dut.flags)<<std::dec<<'\n';
                    throw std::runtime_error("RTL versus new NF model/oracle");
                }
                if (!seen_valid) {
                    const uint64_t latency=cycles-launch_cycle-1;
                    require(latency==std::max(1u,expected.iterations)+10,"valid latency differs from contract");
                    first_valid_min=std::min(first_valid_min,latency);
                    first_valid_max=std::max(first_valid_max,latency);
                    if (pending_acc) { accumulator=expected.bits; ++acc_commits; }
                    seen_valid=true;
                }
            }
            if (dut.out_valid && dut.out_ready) {
                handshake_min=std::min(handshake_min,cycles-launch_cycle);
                handshake_max=std::max(handshake_max,cycles-launch_cycle);
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
    report<<"]}\n";
    std::cout<<"W11 HARNESS PASS NB="<<NB<<" ES="<<ES<<" completed="<<completed
             <<" reset_aborts="<<aborts<<" mismatches=0"<<std::endl;
} catch (const std::exception& e) {
    std::cerr<<"FAIL: "<<e.what()<<'\n'; return 1;
}
