#include <array>
#include <fstream>
#include <iostream>
#include <random>
#include <stdexcept>
#include <string>
#include "posit_fused_window.hpp"
#include "../../tb/week12_corpus.hpp"
#include "../../tb/week12_fused_reference.hpp"
#include "../../tb/nf_coverage_corpus.hpp"

namespace {
using O=week12_reference::Oracle<32,3>;
constexpr uint64_t STRATIFIED=1056768,NEAR=1152000,TOTAL=STRATIFIED+NEAR;
unsigned incoming(const l1::PrepackProduct& p) {
    return p.is_zero||p.is_nar?0:((p.input_cut||p.iteration_cut||p.term_cut)?2u:0u)|(p.iteration_cut?1u:0u);
}
void require(bool condition,const char* message) {if (!condition) throw std::runtime_error(message);}
l1::IterConfig config(const week12::Case& row) {
    l1::IterConfig cfg;cfg.n=row.n;cfg.ops=row.ops;cfg.rounding=l1::RoundMode::RNE;return cfg;
}
void generate(const char* path) {
    std::mt19937_64 rng(20261014);
    std::ofstream out(path,std::ios::binary);require(bool(out),"coverage corpus open");
    uint32_t reference_state=0;
    for (uint64_t i=0;i<TOTAL;++i) {
        week12::Case row{0,0,uint32_t(rng()),uint8_t(i%9),uint8_t((i/9)%2),0,0};
        const bool reset=i%4093==0;
        bool mode=i%4==3,clear=mode&&i%97==3;
        if (reset) reference_state=0;
        if (i<STRATIFIED) {
            const unsigned cross=unsigned(i%256),repeat=unsigned(i/256);
            row.a=nf_coverage::Corpus<32,3>::stratified(rng,cross%8,(cross/64)&1,repeat&1);
            row.b=nf_coverage::Corpus<32,3>::stratified(rng,(cross/8)%8,(cross/128)&1,(repeat/2)&1);
        } else {
            const unsigned delta=unsigned((i-STRATIFIED)%5);
            if (mode&&!clear&&reference_state&&reference_state!=O::NAR) {
                auto u=l1::parse<32,3>(reference_state);u.sign=!u.sign;u.sf-=int(delta);
                row.a=uint32_t(l1::pack(u));row.b=0x40000000u;
            } else {
                mode=false;clear=false;
                row.a=(uint32_t(rng())&0x0fffffffu)|0x30000000u;
                row.b=(uint32_t(rng())&0x0fffffffu)|0x30000000u;
                if (i&1) row.a=0u-row.a;
                if (i&2) row.b=0u-row.b;
                const auto p=l1::L1MultiplierIter<32,3,12>::mul(row.a,row.b,config(row)).prepack;
                auto u=week11::normalize<32,3>(p);u.sign=!u.sign;u.sf+=int(delta);
                row.c=uint32_t(l1::pack(u));
            }
        }
        row.control=uint8_t(mode|(clear<<1)|(reset<<2));
        const uint32_t effective=mode?(clear?0:reference_state):row.c;
        const auto p=l1::L1MultiplierIter<32,3,12>::mul(row.a,row.b,config(row)).prepack;
        const auto ref=O::add(p,effective,incoming(p));
        if (mode) reference_state=ref.bits;
        out.write(reinterpret_cast<const char*>(&row),sizeof(row));
    }
    require(bool(out),"coverage corpus write");
    std::cout<<"W12 COVERAGE GENERATED records="<<TOTAL<<" seed=20261014\n";
}
struct RunInfo {unsigned group,polarity_bin;bool negative;};
RunInfo run_info(uint32_t raw) {
    require(raw&&raw!=O::NAR,"coverage finite raw A/B required");
    const bool negative=(raw&O::NAR)!=0;
    const uint32_t mag=negative?0u-raw:raw;
    const bool polarity=(mag>>30)&1;
    unsigned run=0;
    for (int b=30;b>=0&&bool((mag>>b)&1)==polarity;--b) ++run;
    constexpr unsigned hi[]={3,7,11,15,17,22,27,31};
    unsigned group=0;while (run>hi[group]) ++group;
    return {group,(polarity?30u:0u)+run-1,negative};
}
template<size_t N> void array_json(std::ostream& out,const std::array<uint64_t,N>& values) {
    out<<'[';for (size_t i=0;i<N;++i) out<<(i?",":"")<<values[i];out<<']';
}
void monitor(const char* path,const char* report_path) {
    std::ifstream in(path,std::ios::binary);require(bool(in),"coverage corpus input");
    l1::FusedWindowAccumulator<32,3,12,32> state;
    uint32_t ref_state=0;
    std::array<uint64_t,256> crosses{};
    std::array<uint64_t,61> runs{};
    std::array<uint64_t,9> n_hits{},iterations{};
    std::array<uint64_t,6> popcount{};
    std::array<std::array<uint64_t,5>,2> delta{},delta_after{};
    uint64_t borrow=0,tails=0,near=0,near_after=0,resets=0,clears=0,acc_steps=0;
    for (uint64_t i=0;i<TOTAL;++i) {
        week12::Case row{};in.read(reinterpret_cast<char*>(&row),sizeof(row));
        require(bool(in)&&row.n<=8&&row.ops<=1&&row.reserved==0,"coverage row");
        const bool mode=row.control&1,clear=row.control&2;
        if (row.control&4) {state.reset();ref_state=0;++resets;}
        const auto a=run_info(row.a),b=run_info(row.b);
        ++crosses[a.group+8*b.group+64*unsigned(a.negative)+128*unsigned(b.negative)];
        ++runs[a.polarity_bin];++runs[b.polarity_bin];++n_hits[row.n];
        const auto cfg=config(row);
        const auto m=l1::L1MultiplierIter<32,3,12>::mul(row.a,row.b,cfg);
        const auto& p=m.prepack;
        const uint32_t effective=mode?(clear?0:ref_state):row.c;
        const auto ref=O::add(p,effective,incoming(p));
        const auto value=state.step(row.a,row.b,row.c,mode,clear,cfg);
        require(value.c_eff==effective&&value.bits==ref.bits&&value.flags==ref.flags,"coverage F model/oracle/state mismatch");
        if (value.bits!=O::NAR&&!ref.zero) {
            const auto sliced=O::slice(p,effective,ref,32);
            require(sliced.anchor==value.trace.anchor&&sliced.magnitude==value.trace.magnitude
                &&sliced.tail==value.trace.residual,"coverage retained sum/residual");
        }
        if (effective&&effective!=O::NAR&&!p.is_nar&&!p.is_zero) {
            const auto c=O::decode(effective);
            const unsigned d=unsigned(std::abs(p.scale+O::highest(p.magnitude)-int(p.fractional_bits)-c.sf));
            if (p.sign!=c.sign&&d<=4) {++delta[mode][d];++near;}
            const auto& t=value.trace;
            if (p.sign!=c.sign&&t.p_retained&&t.c_retained) {
                const auto after=unsigned(std::abs(int(l1::FusedWindow<32,3>::top(t.p_retained))-int(l1::FusedWindow<32,3>::top(t.c_retained))));
                if (after<=4) {++delta_after[mode][after];++near_after;}
            }
        }
        const uint64_t fa=O::decode(row.a).coefficient&((uint64_t(1)<<26)-1);
        const uint64_t fb=O::decode(row.b).coefficient&((uint64_t(1)<<26)-1);
        unsigned ca=unsigned(__builtin_popcountll(fa>>14)),cb=unsigned(__builtin_popcountll(fb>>14));
        if (row.ops) ca=std::min(ca,cb);
        const unsigned bucket=ca==0?0:ca==1?1:ca==2?2:ca<=4?3:ca<=8?4:5;
        ++popcount[bucket];++iterations[m.iterations];
        borrow+=value.trace.borrow;tails+=value.trace.residual;clears+=clear;acc_steps+=mode;
        if (mode) ref_state=ref.bits;
        require(uint32_t(state.value())==ref_state,"coverage commit state");
        if ((i+1)%500000==0) std::cout<<"W12 COVERAGE progress="<<i+1<<std::endl;
    }
    const auto min_cross=*std::min_element(crosses.begin(),crosses.end());
    const auto min_run=*std::min_element(runs.begin(),runs.end());
    require(min_cross>=4000&&min_run>=10000,"regime stratification insufficient");
    require(near*10>=TOTAL*3&&near_after*10>=TOTAL*3,"coverage near distribution");
    for (auto hits:n_hits) require(hits>=100000,"coverage n distribution");
    for (auto hits:popcount) require(hits>0,"coverage popcount bucket");
    for (auto mode:delta) for (auto hits:mode) require(hits>0,"coverage delta/mode bucket");
    for (auto mode:delta_after) for (auto hits:mode) require(hits>0,"coverage delta_after/mode bucket");
    std::ofstream out(report_path);require(bool(out),"coverage report output");
    out<<"{\n\"status\":\"PASS\",\"cases\":"<<TOTAL<<",\"W\":32,\"seed\":20261014,\"mismatches\":0,\"F_W_F_ref_differences\":0"
       <<",\"near_before\":"<<near<<",\"near_after\":"<<near_after<<",\"min_cross\":"<<min_cross<<",\"min_run_polarity\":"<<min_run
       <<",\"borrow\":"<<borrow<<",\"tail\":"<<tails<<",\"resets\":"<<resets<<",\"acc_clr\":"<<clears<<",\"acc_transactions\":"<<acc_steps
       <<",\"crosses\":";array_json(out,crosses);out<<",\"run_polarity\":";array_json(out,runs);
    out<<",\"n_hits\":";array_json(out,n_hits);out<<",\"popcount\":";array_json(out,popcount);out<<",\"iterations\":";array_json(out,iterations);
    out<<",\"delta_before_standalone\":";array_json(out,delta[0]);out<<",\"delta_before_acc_mode\":";array_json(out,delta[1]);
    out<<",\"delta_after_standalone\":";array_json(out,delta_after[0]);out<<",\"delta_after_acc_mode\":";array_json(out,delta_after[1]);out<<"}\n";
    std::cout<<"W12 COVERAGE PASS cases="<<TOTAL<<" min_cross="<<min_cross<<" min_run="<<min_run
             <<" near="<<near<<" mismatches=0\n";
}
}
int main(int argc,char**argv) try {
    if (argc==3&&std::string(argv[1])=="generate") {generate(argv[2]);return 0;}
    if (argc==4&&std::string(argv[1])=="monitor") {monitor(argv[2],argv[3]);return 0;}
    throw std::invalid_argument("usage: week12_coverage generate corpus.bin OR monitor corpus.bin report.json");
} catch (const std::exception& error) {std::cerr<<"FAIL "<<error.what()<<'\n';return 1;}
