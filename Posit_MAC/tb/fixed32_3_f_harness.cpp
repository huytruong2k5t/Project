#include <array>
#include <fstream>
#include <iostream>
#include <random>
#include <stdexcept>
#include <string>
#include "Vweek13_fused_tb.h"
#include "verilated.h"
#include "verilated_cov.h"
#include "posit_fused_window.hpp"
#include "week12_fused_reference.hpp"
#include "nf_coverage_corpus.hpp"

using Model = l1::FusedWindow<32,3,12,32>;
using Oracle = week12_reference::Oracle<32,3>;
using Mul = l1::L1MultiplierIter<32,3,12>;
constexpr uint64_t SEED = 20261022;
struct Input {uint32_t a,b,c; unsigned n,ops; bool mode,clear;};
void check(bool value,const char* message) {
    if (!value) throw std::runtime_error(message);
}
int signed11(unsigned value) {return (value&1024) ? int(value)-2048 : int(value);}
l1::IterConfig config(const Input& row) {
    l1::IterConfig cfg;
    cfg.n=row.n; cfg.ops=row.ops; cfg.rounding=l1::RoundMode::RNE;
    return cfg;
}
Input generate(std::mt19937_64& rng,uint64_t i,uint32_t state) {
    const unsigned cross=unsigned((i/2+i/512)%256);
    Input row{
        nf_coverage::Corpus<32,3>::stratified(rng,cross%8,(cross/64)&1,(i/512)&1),
        nf_coverage::Corpus<32,3>::stratified(rng,(cross/8)%8,(cross/128)&1,(i/1024)&1),
        uint32_t(rng()),unsigned(i%9),unsigned((i/9)%2),bool((i/4)%2),false};
    row.clear=row.mode&&i%97==3;
    // Fixed 50% cancellation-directed strata, not an application distribution.
    if (i&1) {
        const unsigned delta=unsigned((i/2)%5);
        if(row.mode&&!row.clear&&state&&state!=Oracle::NAR) {
            auto u=l1::parse<32,3>(state); u.sign=!u.sign; u.sf-=int(delta);
            row.a=uint32_t(l1::pack(u)); row.b=0x40000000;
        } else {
            row.mode=false; row.clear=false;
            row.a=(uint32_t(rng())&0x0fffffffu)|0x30000000u;
            row.b=(uint32_t(rng())&0x0fffffffu)|0x30000000u;
            if(i&2) row.a=0u-row.a;
            if(i&4) row.b=0u-row.b;
            auto p=Mul::mul(row.a,row.b,config(row)).prepack;
            auto u=week11::normalize<32,3>(p); u.sign=!u.sign; u.sf+=int(delta);
            row.c=uint32_t(l1::pack(u));
        }
    }
    // Corners cover zero/NaR priority, exact cancellation, tiny/huge sums.
    if (i%256<12) {
        row.mode=false; row.clear=false;
        switch(i%256) {
        case 0: row.a=0; row.b=Oracle::NAR; break;
        case 1: row.a=Oracle::NAR; row.b=0; break;
        case 2: row.c=Oracle::NAR; break;
        case 3: row.a=0; break;
        case 4: row.b=0; break;
        case 5: row.c=0; break;
        case 6: row.a=1; row.b=1; row.c=0; break;
        case 7: row.a=0x7fffffff; row.b=0x7fffffff; row.c=0; break;
        case 8: row.a=0x40000000; row.b=0x40000000; row.c=0xc0000000; break;
        case 9: row.a=0x40000000; row.b=0x40000000; row.c=0xc0000001; break;
        case 10: row.a=0xc0000000; row.b=0x40000000; row.c=0x40000001; break;
        default: row.a=0x7fffffff; row.b=1; row.c=0xffffffff; break;
        }
    }
    return row;
}
unsigned incoming(const l1::PrepackProduct& p) {
    return p.is_zero||p.is_nar?0:((p.input_cut||p.iteration_cut||p.term_cut)?2u:0u)|(p.iteration_cut?1u:0u);
}
int main(int argc,char** argv) try {
    check(argc==3,"usage: harness completed_count output_prefix");
    const uint64_t goal=std::stoull(argv[1]);
    const std::string prefix=argv[2];
    Verilated::commandArgs(argc,argv);
    Vweek13_fused_tb dut;
    std::mt19937_64 rng(SEED), traffic(SEED+1);
    uint64_t cycles=0,accepted=0,completed=0,aborted=0,stalls=0,commits=0;
    uint64_t reset_busy=0,reset_stall=0,invalid=0,stage_checks=0,oracle_checks=0;
    uint64_t near=0,near_after=0,tails=0,borrows=0,clears=0;
    std::array<uint64_t,9> n_hits{},iteration_hits{};
    std::array<uint64_t,36> configs{};
    std::array<uint64_t,5> flags_hits{},delta_hits{};
    std::array<uint64_t,256> crosses{};
    std::array<uint64_t,61> run_polarity{};
    std::array<uint64_t,6> popcount{};
    std::array<uint64_t,10> delta_before_mode{},delta_after_mode{};
    uint64_t lat_min=1000,lat_max=0;
    uint32_t state=0;
    auto tick=[&]() {dut.clk=0;dut.eval();dut.clk=1;dut.eval();++cycles;};
    auto reset=[&]() {
        dut.rst_n=0;dut.in_valid=0;dut.out_ready=0;
        for(int j=0;j<4;++j) {tick();check(!dut.out_valid&&!dut.in_ready,"reset gating");}
        state=0;dut.rst_n=1;
        for(int j=0;j<8;++j) tick();
        check(dut.dbg_accumulator==0,"reset accumulator");
    };
    dut.a=0;dut.b=0;dut.c=0;dut.cfg_mode=1;dut.cfg_n=0;dut.cfg_ops=0;
    dut.acc_mode=0;dut.acc_clr=0;
    reset();
    while(completed<goal) {
        if (accepted%127==0) {
            for(unsigned bad=0;bad<4;++bad) {
                dut.in_valid=1;dut.acc_mode=0;dut.acc_clr=bad==3;
                dut.cfg_mode=bad!=0;dut.cfg_n=bad==1?9:0;dut.cfg_ops=bad==2?2:0;
                dut.clk=0;dut.eval();check(!dut.in_ready,"invalid config accepted");tick();++invalid;
                check(!dut.out_valid,"invalid config output");
            }
        }
        Input row=generate(rng,accepted,state);
        const uint32_t ceff=row.mode?(row.clear?0:state):row.c;
        const auto mul=Mul::mul(row.a,row.b,config(row));
        const auto p=mul.prepack;
        const auto exp=Model::add(p,ceff);
        const auto ref=Oracle::add(p,ceff,incoming(p));
        check(exp.bits==ref.bits&&exp.flags==ref.flags,"L1 versus independent oracle");
        ++oracle_checks;
        dut.a=row.a;dut.b=row.b;dut.c=row.c;dut.cfg_mode=1;dut.cfg_n=row.n;dut.cfg_ops=row.ops;
        dut.acc_mode=row.mode;dut.acc_clr=row.clear;dut.in_valid=1;dut.out_ready=0;
        unsigned waiting=0;
        for(;;) {
            dut.clk=0;dut.eval();if(dut.in_ready) break;
            tick();check(++waiting<100,"input timeout");
        }
        tick();++accepted;dut.in_valid=0;
        if(row.mode&&row.clear) {state=0;++clears;}
        const unsigned expected_valid=std::max(1u,(exp.flags&16)?0u:mul.iterations)+11;
        bool seen=false,abort=false,held=false;
        unsigned held_d=0,held_f=0;
        const bool abort_busy=accepted%997==0;
        const bool abort_held=accepted%991==0;
        const unsigned hold_cycles=accepted%31==0?96:unsigned(traffic()%5);
        unsigned output_age=0;
        for(unsigned elapsed=0;elapsed<300;++elapsed) {
            // All external context changes after accept; the MAC must own it.
            dut.a=uint32_t(traffic());dut.b=uint32_t(traffic());dut.c=uint32_t(traffic());
            dut.cfg_mode=traffic()&1;dut.cfg_n=traffic()%16;dut.cfg_ops=traffic()%4;
            dut.acc_mode=traffic()&1;dut.acc_clr=traffic()&1;
            dut.in_valid=traffic()&1;
            dut.out_ready=output_age>=hold_cycles&&!abort_held;
            dut.clk=0;dut.eval();
            check(!dut.in_ready,"accepted while busy");
            if(held) check(dut.out_valid&&dut.d==held_d&&dut.flags==held_f,"output changed under stall");
            if (!(exp.flags&16)) {
                const auto& t=exp.trace;
                const bool choose_p=!p.is_zero&&p.magnitude&&(!ceff||t.p_sf>=t.c_sf);
                if(dut.dbg_core_done) {
                    check(p.is_zero||dut.dbg_raw_magnitude==p.magnitude,"raw prepack magnitude");
                    check(p.is_zero||signed11(dut.dbg_raw_scale)==p.scale,"raw prepack scale");
                    check(dut.dbg_raw_loss==incoming(p),"raw loss metadata");++stage_checks;
                }
                if(dut.dbg_v1) {check(signed11(dut.dbg_anchor)==t.anchor,"F1 anchor");++stage_checks;}
                if(dut.dbg_v2) {
                    const uint32_t large=uint32_t(choose_p?t.p_retained:t.c_retained);
                    const uint32_t small=uint32_t(choose_p?t.c_retained:t.p_retained);
                    check(dut.dbg_large_value==large&&dut.dbg_small_value==small,"F2 aligned values");
                    check(bool(dut.dbg_tail)==t.residual,"F2 signed tail");++stage_checks;
                }
                if(dut.dbg_v3) {
                    const bool csign=ceff>>31;
                    const int64_t large=int64_t(choose_p?t.p_retained:t.c_retained);
                    const int64_t small=int64_t(choose_p?t.c_retained:t.p_retained);
                    const int64_t sum=large+((p.sign!=csign)?-small:small);
                    check(int32_t(dut.dbg_retained_sum)==sum,"F3 retained sum");++stage_checks;
                }
                if(dut.dbg_v4) {
                    check(dut.dbg_magnitude==uint32_t(t.magnitude),"F4 magnitude/borrow");
                    check(bool(dut.dbg_sum_sign)==t.sign,"F4 sign");++stage_checks;
                }
                if(dut.dbg_v5) {
                    check(bool(dut.dbg_zero)==t.zero&&bool(dut.dbg_sticky)==t.residual,"F5 zero/sticky");
                    if(!t.zero) {
                        const auto h=Model::top(t.magnitude);
                        const uint64_t f=(uint64_t(t.magnitude)<<(30-h))&0x3fffffffu;
                        check(dut.dbg_fraction==(f<<23)&&signed11(dut.dbg_sf_final)==t.sf,"F5 fraction/scale");
                    }
                    ++stage_checks;
                }
            }
            if(dut.out_valid) {
                if(dut.d!=exp.bits||dut.flags!=exp.flags) {
                    std::cerr<<"serial="<<accepted<<" a/b/c="<<std::hex<<row.a<<'/'<<row.b<<'/'<<ceff
                      <<" got="<<dut.d<<" expected="<<exp.bits<<" flags="<<unsigned(dut.flags)<<'/'<<exp.flags<<std::dec<<'\n';
                    throw std::runtime_error("RTL result mismatch");
                }
                if(!seen) {
                    if(elapsed!=expected_valid) std::cerr<<"latency got="<<elapsed<<" expected="<<expected_valid<<'\n';
                    check(elapsed==expected_valid,"latency contract");
                    lat_min=std::min(lat_min,uint64_t(elapsed));lat_max=std::max(lat_max,uint64_t(elapsed));
                    if(row.mode) {state=exp.bits;++commits;}
                    seen=true;
                }
                ++output_age;
            }
            if((abort_busy&&elapsed==3)||(abort_held&&seen)) {
                ++aborted;reset_busy+=abort_busy;reset_stall+=abort_held&&seen;abort=true;reset();break;
            }
            bool retire=dut.out_valid&&dut.out_ready;
            held=dut.out_valid&&!dut.out_ready;held_d=dut.d;held_f=dut.flags;stalls+=held;
            dut.clk=1;dut.eval();++cycles;
            if(seen) check(dut.dbg_accumulator==state,"accumulator commit/state");
            if(retire) {
                ++completed;++n_hits[row.n];++configs[row.n+9*row.ops+18*row.mode];
                ++iteration_hits[(exp.flags&16)?0:mul.iterations];
                for(unsigned j=0;j<5;++j) flags_hits[j]+=bool(exp.flags&(1u<<j));
                near+=exp.trace.near_before;near_after+=exp.trace.near_after;
                tails+=exp.trace.residual;borrows+=exp.trace.borrow;
                if(exp.trace.near_before) {
                    const unsigned delta=unsigned(std::abs(exp.trace.p_sf-exp.trace.c_sf));
                    ++delta_hits[delta];++delta_before_mode[delta+5*row.mode];
                }
                if(exp.trace.near_after) {
                    const unsigned delta=unsigned(std::abs(int(Model::top(exp.trace.p_retained))-int(Model::top(exp.trace.c_retained))));
                    ++delta_after_mode[delta+5*row.mode];
                }
                // Cross counters use the same regime groups as the existing corpus.
                if(row.a&&row.b&&row.a!=Oracle::NAR&&row.b!=Oracle::NAR) {
                    auto group=[&](uint32_t raw) {
                        uint32_t mag=raw>>31?0u-raw:raw;bool pol=(mag>>30)&1;unsigned run=0;
                        for(int k=30;k>=0&&bool((mag>>k)&1)==pol;--k)++run;
                        ++run_polarity[(pol?30u:0u)+run-1];
                        constexpr unsigned hi[]={3,7,11,15,17,22,27,31};unsigned g=0;while(run>hi[g])++g;return g;
                    };
                    ++crosses[group(row.a)+8*group(row.b)+64*(row.a>>31)+128*(row.b>>31)];
                    const uint64_t fa=Oracle::decode(row.a).coefficient&0x3ffffffu;
                    const uint64_t fb=Oracle::decode(row.b).coefficient&0x3ffffffu;
                    unsigned ca=unsigned(__builtin_popcountll(fa>>14));
                    const unsigned cb=unsigned(__builtin_popcountll(fb>>14));
                    if(row.ops)ca=std::min(ca,cb);
                    ++popcount[ca==0?0:ca==1?1:ca==2?2:ca<=4?3:ca<=8?4:5];

                }
                break;
            }
            check(elapsed<299,"output timeout");
        }
        if(!abort) {dut.in_valid=0;tick();check(!dut.out_valid,"duplicate output");}
        if(completed&&completed%100000==0&&!abort) std::cout<<"W13 CHECKPOINT completed="<<completed<<std::endl;
    }
    check(accepted==completed+aborted,"accounting");
    check(near*10>=completed*3,"near coverage below 30 percent");
    for(auto x:n_hits) check(x>0,"missing n");
    for(auto x:crosses) check(x>0,"missing regime/sign cross");
    for(auto x:run_polarity) check(x>0,"missing run/polarity");
    for(auto x:popcount) check(x>0,"missing popcount group");
    for(auto x:delta_before_mode) check(x>0,"missing delta/mode before cut");
    for(auto x:delta_after_mode) check(x>0,"missing delta/mode after cut");
    std::cout<<"COVERAGE tail="<<tails<<" borrow="<<borrows<<" resets="<<reset_busy<<'/'<<reset_stall<<" commits="<<commits<<" clears="<<clears<<std::endl;
    check(tails&&borrows&&reset_busy&&reset_stall&&invalid&&commits&&clears,"coverage hole");
    std::ofstream out(prefix+".json");
    out<<"{\n\"status\":\"PASS\",\"seed\":"<<SEED<<",\"completed\":"<<completed
       <<",\"accepted\":"<<accepted<<",\"reset_aborted\":"<<aborted<<",\"mismatches\":0"
       <<",\"oracle_checks\":"<<oracle_checks<<",\"stage_checks\":"<<stage_checks
       <<",\"stalled_cycles\":"<<stalls<<",\"reset_busy\":"<<reset_busy<<",\"reset_stalled\":"<<reset_stall
       <<",\"invalid_checks\":"<<invalid<<",\"commits\":"<<commits<<",\"clears\":"<<clears
       <<",\"near\":"<<near<<",\"near_after\":"<<near_after<<",\"tails\":"<<tails<<",\"borrows\":"<<borrows
       <<",\"valid_latency_min\":"<<lat_min<<",\"valid_latency_max\":"<<lat_max;
    auto array=[&](const char* name,const auto& v) {out<<",\n\""<<name<<"\":[";bool first=true;for(auto x:v){out<<(first?"":",")<<x;first=false;}out<<']';};
    array("n_hits",n_hits);array("config_hits",configs);array("iterations",iteration_hits);
    array("run_polarity",run_polarity);array("popcount",popcount);
    array("delta_before_mode",delta_before_mode);array("delta_after_mode",delta_after_mode);
    array("flags",flags_hits);array("near_delta",delta_hits);array("regime_sign_cross",crosses);
    out<<"\n}\n";out.close();
    dut.final();VerilatedCov::write((prefix+".coverage.dat").c_str());
    // Event-simulator vectors use own sequential accumulator and explicit resets.
    std::ofstream vec(prefix+".vectors");state=0;
    for(unsigned i=0;i<8192;++i) {
        bool rst=i%127==0;if(rst)state=0;
        auto row=generate(rng,i,state);uint32_t ceff=row.mode?(row.clear?0:state):row.c;
        auto mul=Mul::mul(row.a,row.b,config(row));auto result=Model::add(mul.prepack,ceff);
        if(row.mode)state=result.bits;
        unsigned latency=std::max(1u,(result.flags&16)?0u:mul.iterations)+11;
        vec<<std::hex<<row.a<<' '<<row.b<<' '<<row.c<<' '<<result.bits<<' '<<result.flags<<std::dec
           <<' '<<row.n<<' '<<row.ops<<' '<<row.mode<<' '<<row.clear<<' '<<rst<<' '<<latency<<'\n';
    }
    std::cout<<"W13 PASS completed="<<completed<<" mismatch=0 stages="<<stage_checks<<std::endl;
    return 0;
} catch(const std::exception& e) {std::cerr<<"W13 FAIL: "<<e.what()<<'\n';return 1;}
