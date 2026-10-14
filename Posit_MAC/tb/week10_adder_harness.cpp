#include <cstdint>
#include <deque>
#include <fstream>
#include <iostream>
#include <random>
#include <stdexcept>
#include <string>
#include "Vadder_verification_top.h"
#include "verilated.h"
#include "verilated_cov.h"
#include "posit_mac.hpp"
#include "week10_add_reference.hpp"
#include "softposit_api.h"
#ifndef PROFILE_NB
#define PROFILE_NB 32
#endif
#ifndef PROFILE_ES
#define PROFILE_ES 3
#endif
namespace {
constexpr unsigned NB = PROFILE_NB, ES = PROFILE_ES, F = NB - 3 - ES;
constexpr unsigned F_OUT = 2 * F + 1;
constexpr unsigned SF_MAX = (NB - 2) * (1 << ES);
constexpr unsigned width_for(unsigned value) {
    unsigned width = 0;
    for (unsigned limit = 1; limit < value; limit <<= 1) ++width;
    return width;
}
constexpr unsigned SF_W = width_for(4 * SF_MAX + 4) + 1;
constexpr uint32_t NAR = uint32_t(1) << (NB - 1);
constexpr uint32_t MASK = uint32_t((uint64_t(1) << NB) - 1);
struct Payload {
    unsigned sign, zero, nar;
    int sf;
    uint64_t frac;
    unsigned sticky, flags, rne, rne_flags, trunc, trunc_flags;
    bool operator==(const Payload& b) const {
        return sign==b.sign && zero==b.zero && nar==b.nar && sf==b.sf && frac==b.frac &&
               sticky==b.sticky && flags==b.flags && rne==b.rne && rne_flags==b.rne_flags &&
               trunc==b.trunc && trunc_flags==b.trunc_flags;
    }
};
void require(bool ok, const char* message) {
    if (!ok) throw std::runtime_error(message);
}
uint64_t l0_checks = 0, oracle_checks = 0;
Payload expected(uint32_t a, uint32_t b, unsigned flags) {
    using T = l1::posit_storage_t<NB>;
    auto sum = l1::l1_add_unpacked<NB, ES>(l1::parse<NB, ES>(T(a)), l1::parse<NB, ES>(T(b)));
    const auto ref = week10_reference::Adder<NB, ES>::add(a, b, flags);
    oracle_checks += 2;
    if constexpr (ES != 3) {
        uint32_t bits;
        if constexpr (NB == 8) bits=l0_p8_add(uint8_t(a),uint8_t(b));
        else if constexpr (NB == 16) bits=l0_p16_add(uint16_t(a),uint16_t(b));
        else bits=l0_p32_add(a,b);
        require(ref.rne==((flags&16)?NAR:bits),"independent reference versus L0");
        ++l0_checks;
    }
    const bool nar = sum.is_nar || (flags & 16);
    const bool zero = !nar && sum.is_zero;
    const bool sign = nar || (!zero && sum.sign);
    const bool sticky = !nar && !zero && !sum.exact;
    const uint64_t frac = nar || zero ? 0 :
        (sum.frac & ((uint64_t(1)<<63)-1)) >> (63-F_OUT);
    const unsigned raw_flags = nar ? 16 : (flags & 15) | (sticky ? 2 : 0);
    require(ref.rne==(nar?NAR:uint32_t(l1::pack<NB,ES>(sum))),"L1 versus exact reference RNE");
    require(ref.trunc==(nar?NAR:uint32_t(l1::pack<NB,ES>(sum,l1::RoundMode::TRUNC))),
            "L1 versus exact reference TRUNC");
    return {unsigned(sign),unsigned(zero),unsigned(nar),nar||zero?0:sum.sf,frac,
            unsigned(sticky),raw_flags,ref.rne,ref.flags_rne,ref.trunc,ref.flags_trunc};
}
Payload actual(const Vadder_verification_top& dut) {
    int sf = int(dut.sf);
    if (sf & (1 << (SF_W-1))) sf -= 1 << SF_W;
    return {dut.sign,dut.is_zero,dut.is_nar,sf,uint64_t(dut.frac),dut.sticky,dut.flags_out,
            dut.d_rne,dut.flags_rne,dut.d_trunc,dut.flags_trunc};
}
uint32_t operand(std::mt19937_64& rng, uint64_t serial) {
    if constexpr (NB != 32) return uint32_t(rng()) & MASK;
    constexpr unsigned lo[]={1,4,8,12,16,18,23,28};
    constexpr unsigned hi[]={3,7,11,15,17,22,27,31};
    const unsigned group=unsigned((serial/2)%8);
    const bool polarity=serial&1;
    const bool negative=(serial/16)&1;
    const unsigned end=std::min(hi[group],polarity?31u:30u);
    const unsigned run=lo[group]+unsigned((serial/32)%(end-lo[group]+1));
    uint32_t mag=0;
    for(int i=30;i>30-int(run);--i) if(polarity) mag|=uint32_t(1)<<i;
    unsigned left=31-run;
    if(left) {if(!polarity) mag|=uint32_t(1)<<(left-1);--left;}
    const unsigned eb=std::min(ES,left),fb=left-eb;
    const uint32_t mask=fb?(uint32_t(1)<<fb)-1:0;
    uint32_t frac=uint32_t(rng())&mask;
    switch((serial/64)%6) {
        case 0:frac=0;break;
        case 1:frac=mask;break;
        case 2:frac=0xaaaaaaaa&mask;break;
        case 3:frac=0x55555555&mask;break;
        case 4:frac=fb?uint32_t(1)<<(rng()%fb):0;break;
        default:break;
    }
    mag|=(uint32_t(rng())&((uint32_t(1)<<eb)-1))<<fb;
    mag|=frac;
    return negative?0u-mag:mag;
}
}
int main(int argc,char**argv) try {
    if(argc!=3) throw std::invalid_argument("usage: harness completed_goal output_prefix");
    const uint64_t goal=std::stoull(argv[1]);
    require(goal>=1000,"goal too small");
    const std::string prefix=argv[2];
    Verilated::commandArgs(argc,argv);
    Vadder_verification_top dut;
    std::mt19937_64 rng(20261012+NB*100+ES);
    struct Entry {Payload value;uint64_t cycle;};
    std::deque<Entry> queue;
    uint64_t cycles=0,accepted=0,completed=0,aborts=0,output_stalls=0,input_stalls=0;
    uint64_t reset_busy=0,reset_output_stall=0,max_slots=0,long_stalls=0;
    bool source=false,held=false;
    Payload held_payload{};
    dut.clk=0;dut.reset_n=0;dut.in_valid=0;dut.out_ready=0;
    dut.a=0;dut.b=0;dut.flags_in=0;dut.eval();
    while(completed<goal || !queue.empty()) {
        ++cycles;
        const bool reset=cycles<4 || cycles%4093==0 || cycles%4093==1;
        if(reset) {
            reset_busy+=!queue.empty();
            reset_output_stall+=held;
            aborts+=queue.size();queue.clear();held=false;source=false;
        }
        if(!reset && completed<goal && !source && (cycles<16 || rng()%5)) {
            uint32_t a,b;
            if constexpr (NB==8) {
                a=uint32_t(accepted/256)&255;b=uint32_t(accepted)&255;
            } else {
                a=operand(rng,accepted);
                b=operand(rng,accepted+39);
                if(accepted%10<4) {
                    uint32_t mag=uint32_t(rng())&(NAR-1);
                    if(!mag) mag=1;
                    const uint32_t next=std::min(NAR-1,mag+uint32_t(accepted&15));
                    a=(accepted&1)?mag:0u-mag;b=(accepted&1)?0u-next:next;
                }
            }
            if(accepted%1024==0) {a=0;b=NAR;}
            if(accepted%1024==1) {a=NAR-1;b=NAR-1;}
            dut.a=a&MASK;dut.b=b&MASK;
            dut.flags_in=accepted%97==0?unsigned((accepted/97)%32):0;
            source=true;
        }
        dut.reset_n=!reset;
        dut.in_valid=!reset&&source;
        const bool long_block=cycles%4096>=100 && cycles%4096<200;
        dut.out_ready=!reset && (cycles<16 || (!long_block&&rng()%4!=0));
        dut.clk=0;dut.eval();
        const auto before=actual(dut);
        if(!reset) {
            if(held) require(dut.out_valid && before==held_payload,"output changed during stall");
            if(dut.out_valid && dut.out_ready) {
                require(!queue.empty(),"unexpected output");
                if(!(before==queue.front().value)) {
                    std::cerr<<"Mismatch cycle="<<cycles<<" expected="<<std::hex<<queue.front().value.rne
                             <<" actual="<<before.rne<<std::dec<<'\n';
                    throw std::runtime_error("RTL versus L1/reference payload and flags");
                }
                if(completed==0) require(cycles-queue.front().cycle==3,"no-stall handshake latency");
                queue.pop_front();++completed;
                if(completed%1000000==0) std::cout<<"CHECKPOINT NB="<<NB<<" ES="<<ES<<" completed="<<completed<<std::endl;
            }
            if(dut.in_valid && dut.in_ready) {
                queue.push_back({expected(dut.a,dut.b,dut.flags_in),cycles});
                ++accepted;source=false;
            }
            require(queue.size()<=3,"pipeline capacity exceeded");
            max_slots=std::max(max_slots,uint64_t(queue.size()));
            held=dut.out_valid&&!dut.out_ready;
            held_payload=before;
            output_stalls+=held;
            input_stalls+=dut.in_valid&&!dut.in_ready;
            long_stalls+=held&&long_block;
        }
        dut.clk=1;dut.eval();
        if(reset) require(!dut.in_ready&&!dut.out_valid,"reset gating failed");
        require(cycles<goal*10+10000,"harness timeout/deadlock");
    }
    dut.final();
    require(completed+aborts==accepted && max_slots==3 && reset_busy && reset_output_stall && long_stalls,
            "protocol accounting/coverage missing");
    VerilatedCov::write((prefix+"_coverage.dat").c_str());
    std::ofstream report(prefix+"_summary.json");
    report<<"{\n  \"NB\": "<<NB<<", \"ES\": "<<ES<<", \"seed\": "<<20261012+NB*100+ES
          <<", \"accepted\": "<<accepted<<", \"completed\": "<<completed
          <<", \"reset_aborts\": "<<aborts<<", \"output_stalls\": "<<output_stalls
          <<", \"input_stalls\": "<<input_stalls<<", \"reset_busy\": "<<reset_busy
          <<", \"reset_output_stall\": "<<reset_output_stall<<", \"long_stalls\": "<<long_stalls
          <<", \"max_slots\": "<<max_slots<<", \"independent_mode_checks\": "<<oracle_checks
          <<", \"L0_RNE_checks\": "<<l0_checks<<", \"mismatches\": 0\n}\n";
    std::cout<<"W10 HARNESS PASS NB="<<NB<<" ES="<<ES<<" accepted="<<accepted<<" completed="<<completed
             <<" reset_aborts="<<aborts<<" independent_mode_checks="<<oracle_checks
             <<" L0_RNE_checks="<<l0_checks<<" mismatches=0"<<std::endl;
    return 0;
} catch(const std::exception& error) {
    std::cerr<<"FAIL: "<<error.what()<<'\n';return 1;
}
