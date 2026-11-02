#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include "verilated.h"
#if VM_COVERAGE
#include "verilated_cov.h"
#endif
#include "Vshared_mac_checker.h"
#include "full_term_reference.hpp"

static void require(bool ok,const std::string& message) {
    if (!ok) throw std::runtime_error(message);
}
static uint64_t mix(uint64_t x) {
    x+=0x9e3779b97f4a7c15ull;
    x=(x^(x>>30))*0xbf58476d1ce4e5b9ull;
    x=(x^(x>>27))*0x94d049bb133111ebull;
    return x^(x>>31);
}
struct Request {
    uint32_t a=0,b=0,c=0,effective_c=0,expected=0;
    unsigned n=12,ops=1,flags=0;
    bool accumulate=false,clear=false,bypass=false,seen_done=false;
    uint64_t accepted_at=0;
    l1::PrepackProduct product{};
};
int main(int argc,char** argv) {
    try {
        require(argc==6,"COUNT N OPS SEED OUTPUT required");
        const uint64_t target=std::stoull(argv[1]),seed=std::stoull(argv[4]);
        const int fixed_n=std::stoi(argv[2]),fixed_ops=std::stoi(argv[3]);
        require(fixed_n>=-1 && fixed_n<=12 && fixed_ops>=-1 && fixed_ops<=1,"invalid test config");
        VerilatedContext ctx; ctx.commandArgs(argc,argv);
        Vshared_mac_checker d(&ctx);
        auto advance=[&](uint64_t amount) {
            const uint64_t end=ctx.time()+amount;
            while (d.eventsPending() && d.nextTimeSlot()<=end) {
                ctx.timeInc(d.nextTimeSlot()-ctx.time()); d.eval();
            }
            ctx.timeInc(end-ctx.time()); d.eval();
        };
        auto clock=[&]() { advance(5000); d.clk=1; d.eval(); advance(2000); advance(3000); d.clk=0; d.eval(); };
        d.clk=0; d.rst_n=0; d.in_valid=0; d.out_ready=0; d.cfg_n=12; d.cfg_ops=1;
        d.a=0; d.b=0; d.c=0; d.acc_mode=0; d.acc_clr=0; d.eval();
        for (unsigned i=0;i<5;++i) clock();
        d.rst_n=1; d.eval();
        for (unsigned i=0;i<10;++i) clock();
        require(d.in_ready && !d.out_valid,"startup");
        unsigned invalid_checks=0;
        for (unsigned n=13;n<16;++n) {
            d.in_valid=1; d.cfg_n=n;
            for (unsigned i=0;i<4;++i) { d.eval(); require(!d.in_ready && !d.out_valid,"invalid n accepted"); clock(); ++invalid_checks; }
        }
        d.cfg_n=12;
        for (unsigned op=2;op<4;++op) {
            d.cfg_ops=op;
            for (unsigned i=0;i<4;++i) { d.eval(); require(!d.in_ready && !d.out_valid,"invalid ops accepted"); clock(); ++invalid_checks; }
        }
        d.cfg_ops=1; d.acc_mode=0; d.acc_clr=1;
        for (unsigned i=0;i<4;++i) { d.eval(); require(!d.in_ready && !d.out_valid,"invalid clear accepted"); clock(); ++invalid_checks; }
        d.in_valid=0; d.acc_clr=0;

        uint64_t cycles=0,generated=0,accepted=0,completed=0,aborted=0,stage_checks=0,done_checks=0;
        uint64_t input_stalls=0,output_stalls=0,near=0,standalone=0,accumulation=0;
        uint64_t lat_min=UINT64_MAX,lat_max=0;
        uint32_t state=0;
        bool active=false,input_pending=false,held=false;
        uint64_t held_payload=0;
        Request input,current;
        std::array<std::array<uint64_t,13>,2> bins{};
        std::array<uint64_t,32> flag_bins{};
        std::array<uint64_t,13> iteration_bins{};
        unsigned reset_left=0;
        auto make_request=[&](uint64_t i) {
            Request r;
            r.n=fixed_n<0?unsigned(i%13):unsigned(fixed_n);
            r.ops=fixed_ops<0?unsigned((i/13)%2):unsigned(fixed_ops);
            r.a=uint32_t(mix(seed+7*i)); r.b=uint32_t(mix(seed+7*i+1)); r.c=uint32_t(mix(seed+7*i+2));
            r.accumulate=i%10>=7; r.clear=r.accumulate && i%37==0;
            if (i%10<4) {
                r.accumulate=false; r.clear=false;
                r.a=0x40000000u|(r.a&0x03ffffffu); r.b=0x40000000u|(r.b&0x03ffffffu);
                auto p=opt17_reference::product(r.a,r.b,{true,r.n,r.ops});
                const auto packed=opt17_reference::Oracle::add(p,0,0);
                r.c=uint32_t(0-packed.bits);
                if (i%3==0) ++r.c;
            }
            static const uint32_t corners[]={0,0x80000000u,1,0xffffffffu,0x7fffffffu,0x80000001u,0x40000000u,0xc0000000u,0x43ffc000u,0x40004000u};
            if (i%17==0) { r.a=corners[(i/17)%10]; r.b=corners[(i/170)%10]; }
            if (i%19==0) r.c=0;
            if (i%23==0) { r.a=0x43ffc000u; r.b=r.a; }
            if (i==0) { r.a=0x1c900000u; r.b=0x3c820000u; r.c=0; r.accumulate=false; r.clear=false; }
            if (i%53==0 && i) { r.a=0x7fffffffu; r.b=r.a; }
            if (i%59==0 && i) { r.a=1; r.b=1; }
            return r;
        };
        while (completed<target) {
            ++cycles;
            require(cycles<(target+1000)*180,"watchdog/deadlock");
            if (!reset_left && cycles%4093==0 && active) {
                ++aborted; active=false; input_pending=false; held=false; state=0; reset_left=5;
            }
            d.rst_n=reset_left?0:1;
            if (reset_left) --reset_left;
            if (!input_pending && d.rst_n) { input=make_request(generated++); input_pending=true; }
            d.in_valid=input_pending && d.rst_n;
            d.a=input.a; d.b=input.b; d.c=input.c; d.cfg_n=input.n; d.cfg_ops=input.ops;
            d.acc_mode=input.accumulate; d.acc_clr=input.clear;
            d.out_ready=d.rst_n && (mix(seed+cycles)%7<5) && cycles%113>6;
            d.eval();
            const bool take_in=d.rst_n && d.in_valid && d.in_ready;
            const bool take_out=d.rst_n && d.out_valid && d.out_ready;
            const bool commit=d.rst_n && d.commit_valid;
            const unsigned iteration=d.commit_iteration;
            const bool first=d.commit_first,last=d.commit_last;
            if (d.rst_n && held) require(d.out_valid && ((uint64_t(d.d)<<5)|d.flags)==held_payload,"output stall stability");
            held=d.rst_n && d.out_valid && !d.out_ready;
            held_payload=(uint64_t(d.d)<<5)|d.flags;
            if (held) ++output_stalls;
            if (d.in_valid && !d.in_ready) ++input_stalls;
            if (take_out) {
                require(active,"duplicate/unexpected output");
                require(current.seen_done,"output before last core commit");
                if (d.d!=current.expected || d.flags!=current.flags) {
                    std::cerr<<"a="<<std::hex<<current.a<<" b="<<current.b<<" ce="<<current.effective_c
                             <<" got="<<d.d<<"/"<<unsigned(d.flags)<<" expected="<<current.expected<<"/"<<current.flags<<std::dec<<" n="<<current.n<<" ops="<<current.ops<<'\n';
                    throw std::runtime_error("MAC oracle mismatch at "+std::to_string(completed));
                }
                if (current.accumulate) { state=d.d; ++accumulation; } else ++standalone;
                ++bins[current.ops][current.n]; ++flag_bins[d.flags];
                if (!current.bypass && current.effective_c) {
                    auto p=current.product;
                    if (!TEST_FUSED) {
                        auto rounded=opt17_reference::Oracle::add(p,0,0);
                        auto v=opt17_reference::Oracle::decode(rounded.bits);
                        p.scale=v.sf; p.fractional_bits=26; p.magnitude=v.coefficient; p.sign=v.sign;
                    }
                    const auto cv=opt17_reference::Oracle::decode(current.effective_c);
                    unsigned h=0; for (uint64_t m=p.magnitude;m>1;m>>=1) ++h;
                    const int ps=p.scale+int(h)-int(p.fractional_bits);
                    if (p.magnitude && cv.coefficient && p.sign!=cv.sign && std::abs(ps-cv.sf)<=4) ++near;
                }
                const uint64_t latency=cycles-current.accepted_at;
                lat_min=std::min(lat_min,latency); lat_max=std::max(lat_max,latency);
                active=false; ++completed;
            }
            if (take_in) {
                require(!active,"capacity exceeded");
                current=input; current.accepted_at=cycles;
                current.effective_c=current.accumulate?(current.clear?0:state):current.c;
                const auto expected=opt17_reference::mac(current.a,current.b,current.effective_c,{true,current.n,current.ops},TEST_FUSED);
                current.expected=expected.first; current.flags=expected.second;
                current.product=opt17_reference::product(current.a,current.b,{true,current.n,current.ops});
                current.bypass=current.product.is_nar || current.product.is_zero || current.effective_c==0x80000000u;
                active=true; input_pending=false; ++accepted;
            }
            advance(5000); d.clk=1; d.eval(); advance(2000);
            if (d.rst_n) {
                require(!d.core_error,"core invariant error");
                if (commit) {
                    require(active,"commit without transaction");
                    uint64_t expected_m=0;
                    if (!current.bypass) expected_m=opt17_reference::product(current.a,current.b,{true,iteration,current.ops}).magnitude;
                    require(d.core_magnitude==expected_m,"per-iteration magnitude mismatch");
                    require(d.core_iterations==iteration,"iteration metadata mismatch");
                    require(first==(iteration<=1),"first token mismatch");
                    require(bool(d.core_done)==last,"done/last commit mismatch");
                    ++stage_checks;
                }
                if (d.core_done) {
                    require(active && !current.seen_done,"done duplication"); current.seen_done=true;
                    const auto p=current.product;
                    require(d.core_magnitude==(current.bypass?0:p.magnitude),"prepack magnitude");
                    require(d.core_scale==(current.bypass?0:(unsigned(p.scale)&2047)),"prepack scale");
                    require(d.core_sign==(current.bypass?false:p.sign),"prepack sign");
                    require(d.core_input_cut==(current.bypass?false:p.input_cut),"input-cut metadata");
                    require(d.core_cut==(current.bypass?false:p.iteration_cut),"iteration-cut metadata");
                    ++iteration_bins[d.core_iterations]; ++done_checks;
                }
            }
            advance(3000); d.clk=0; d.eval();
        }
        require(accepted==completed+aborted,"accounting");
        d.in_valid=0; d.out_ready=1; d.eval();
        for (unsigned i=0;i<8;++i) { clock(); require(!d.out_valid,"duplicate at drain"); }
        std::ofstream out(argv[5]);
        out<<"{\"status\":\"PASS\",\"profile\":\"APPROX12_FULL_TERM26_Q24\",\"fused\":"<<TEST_FUSED
           <<",\"seed\":"<<seed<<",\"fixed_n\":"<<fixed_n<<",\"fixed_ops\":"<<fixed_ops
           <<",\"accepted\":"<<accepted<<",\"completed\":"<<completed<<",\"reset_aborted\":"<<aborted
           <<",\"mismatches\":0,\"stage_checks\":"<<stage_checks<<",\"done_checks\":"<<done_checks
           <<",\"input_stalls\":"<<input_stalls<<",\"output_stalls\":"<<output_stalls
           <<",\"invalid_checks\":"<<invalid_checks<<",\"near_cancellation\":"<<near
           <<",\"standalone\":"<<standalone<<",\"accumulation\":"<<accumulation
           <<",\"latency_retire_observed\":["<<lat_min<<','<<lat_max<<"],\"bins\":[";
        for (unsigned op=0;op<2;++op) for (unsigned n=0;n<13;++n) { if(op||n) out<<','; out<<bins[op][n]; }
        out<<"],\"flags\":["; for(unsigned i=0;i<32;++i){if(i)out<<',';out<<flag_bins[i];}
        out<<"],\"iterations\":["; for(unsigned i=0;i<13;++i){if(i)out<<',';out<<iteration_bins[i];}
        out<<"],\"coverage_claim\":\"Functional pilot; not structural AC04 or exhaustive raw32 MAC\"}\n";
        #if VM_COVERAGE
        ctx.coveragep()->write((std::string(argv[5])+".dat").c_str());
        #endif
        std::cout<<"SHARED_MAC_PASS F="<<TEST_FUSED<<" completed="<<completed<<" aborted="<<aborted<<" stage="<<stage_checks<<'\n';
        d.final();
    } catch(const std::exception& e) { std::cerr<<e.what()<<'\n'; return 1; }
}
