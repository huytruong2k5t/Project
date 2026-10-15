#include <deque>
#include <fstream>
#include <iostream>
#include <random>
#include <stdexcept>
#include "Vfused_add_pipe.h"
#include "verilated.h"
#include "verilated_cov.h"
#include "posit_fused_window.hpp"
#include "week12_fused_reference.hpp"
using M=l1::FusedWindow<32,3,12,32>;
using O=week12_reference::Oracle<32,3>;
void require(bool v,const char* msg) {if(!v)throw std::runtime_error(msg);}
int s11(unsigned v){return v&1024?int(v)-2048:int(v);}
int main(int argc,char** argv) try {
    Verilated::commandArgs(argc,argv);
    Vfused_add_pipe d;
    std::mt19937_64 rng(20261016);
    struct Item {M::Result result;unsigned loss;};
    std::deque<Item> q;
    Item next{};
    bool source=false,held=false;
    unsigned held_sign=0,held_zero=0,held_nar=0,held_sf=0,held_sticky=0,held_flags=0;
    uint64_t held_frac=0,completed=0,accepted=0,aborts=0,cycles=0,stalls=0,max_depth=0,adjacent=0;
    bool prior_retire=false;
    d.clk=0;d.reset_n=0;d.in_valid=0;d.out_ready=0;
    d.p_magnitude=0;d.p_scale=0;d.p_sign=0;d.p_zero=1;d.is_nar_in=0;d.loss_in=0;
    d.c_sf=0;d.c_frac=0;d.c_sign=0;d.c_zero=1;d.eval();
    while(completed<100000||!q.empty()) {
        ++cycles;
        bool reset=cycles<4||cycles%4093<2;
        if(reset){aborts+=q.size();q.clear();source=false;held=false;prior_retire=false;}
        if(!reset&&!source&&completed<100000) {
            l1::PrepackProduct p;
            p.fractional_bits=12;p.magnitude_bits=14;
            p.magnitude=4096+rng()%12288;p.scale=int(rng()%961)-480;p.sign=rng()&1;
            uint32_t c=uint32_t(rng());
            // Dense scale separation and cancellation cases as well as full range.
            if(accepted%3==0) {
                c=0x40000000u+uint32_t(rng()&0x03ffffffu);
                auto cv=O::decode(c);p.scale=cv.sf+int(accepted%9)-4;
                p.sign=true;
            }
            if(accepted%31==0){p.is_zero=true;p.magnitude=0;}
            if(accepted%37==0)c=0;
            if(accepted%97==0)c=O::NAR;
            const bool nar=c==O::NAR;
            next.result=M::add(p,c);next.loss=nar?0:unsigned(rng()%4);
            auto cv=O::decode(nar?0:c);
            d.p_magnitude=p.magnitude;d.p_scale=unsigned(p.scale)&2047;d.p_sign=p.sign;d.p_zero=p.is_zero;
            d.is_nar_in=nar;d.loss_in=next.loss;
            d.c_sf=unsigned(cv.sf)&2047;d.c_frac=cv.coefficient&0x03ffffffu;d.c_sign=cv.sign;d.c_zero=!cv.coefficient;
            source=true;
        }
        d.reset_n=!reset;d.in_valid=source&&!reset;
        d.out_ready=!reset&&cycles%256>=40&&rng()%4!=0;
        d.clk=0;d.eval();
        if(!reset&&held)require(d.out_valid&&d.sign==held_sign&&d.is_zero==held_zero&&d.is_nar==held_nar
            &&d.sf==held_sf&&d.frac==held_frac&&d.sticky==held_sticky&&d.flags_out==held_flags,"pipe stalled payload");
        bool retire=d.out_valid&&d.out_ready;
        if(!reset&&d.out_valid) {
            require(!q.empty(),"pipe extra output");
            const auto e=q.front();const auto& t=e.result.trace;const bool nar=(e.result.flags&16)!=0;
            require(bool(d.is_nar)==nar&&d.flags_out==(unsigned(nar)*16+e.loss),"pipe metadata/order");
            if(!nar) {
                require(bool(d.sign)==t.sign&&bool(d.is_zero)==t.zero&&bool(d.sticky)==t.residual,"pipe sign/zero/tail");
                if(!t.zero) {
                    const auto h=M::top(t.magnitude);
                    const uint64_t frac=(uint64_t(t.magnitude)<<(30-h))&0x3fffffffu;
                    require(s11(d.sf)==t.sf&&d.frac==(frac<<23),"pipe normalized value");
                }
            }
            if(retire){q.pop_front();++completed;adjacent+=prior_retire;}
        }
        if(!reset&&d.in_valid&&d.in_ready){q.push_back(next);++accepted;source=false;}
        max_depth=std::max(max_depth,uint64_t(q.size()));
        held=!reset&&d.out_valid&&!d.out_ready;stalls+=held;
        held_sign=d.sign;held_zero=d.is_zero;held_nar=d.is_nar;held_sf=d.sf;
        held_frac=d.frac;held_sticky=d.sticky;held_flags=d.flags_out;prior_retire=retire;
        d.clk=1;d.eval();
        require(cycles<1000000,"pipe timeout");
    }
    require(accepted==completed+aborts&&max_depth==5&&adjacent&&stalls&&aborts,"pipe coverage/accounting");
    std::ofstream out("pipe.json");
    out<<"{\"status\":\"PASS\",\"seed\":20261016,\"completed\":"<<completed<<",\"accepted\":"<<accepted
       <<",\"reset_aborted\":"<<aborts<<",\"mismatch\":0,\"max_inflight\":"<<max_depth
       <<",\"consecutive_retire\":"<<adjacent<<",\"stalled_cycles\":"<<stalls<<"}\n";
    d.final();VerilatedCov::write("pipe.coverage.dat");
    std::cout<<"W13 PIPE PASS completed="<<completed<<" max_inflight="<<max_depth<<" mismatch=0\n";
    return 0;
}catch(const std::exception& e){std::cerr<<"W13 PIPE FAIL "<<e.what()<<'\n';return 1;}
