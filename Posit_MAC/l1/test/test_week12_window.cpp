#include <array>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>
#include "posit_fused_window.hpp"
#include "../../tb/week12_corpus.hpp"
#include "../../tb/week12_fused_reference.hpp"
#include "../../tb/week11_model.hpp"

namespace {
using O=week12_reference::Oracle<32,3>;
unsigned metadata(const l1::PrepackProduct& p) {
    if (p.is_zero || p.is_nar) return 0;
    return ((p.input_cut||p.iteration_cut||p.term_cut)?2u:0u)|(p.iteration_cut?1u:0u);
}
std::string hex128(unsigned __int128 v) {
    std::string text;
    do {text.push_back("0123456789abcdef"[unsigned(v&15)]);v>>=4;} while (v);
    std::reverse(text.begin(),text.end());return text;
}
void require(bool condition,const char* message) {if (!condition) throw std::runtime_error(message);}

template<unsigned W> int run(const std::string& corpus,uint64_t count,const std::string& prefix) {
    using M=l1::FusedWindow<32,3,12,W>;
    l1::FusedWindowAccumulator<32,3,12,W> state;
    std::ifstream input(corpus,std::ios::binary);
    std::ofstream trace(prefix+"_trace.jsonl");
    require(bool(input)&&bool(trace),"corpus or trace open");
    std::array<uint64_t,9> n_hits{};
    std::array<uint64_t,2> ops_hits{};
    uint64_t near=0,near_after=0,borrow=0,tails=0,zero=0,nar=0,prior_zero=0;
    uint64_t tie_even=0,tie_odd=0,sat_max=0,sat_min=0;
    uint64_t resets=0,clears=0,accum=0,commits_epoch=0;
    uint64_t nf_differences=0,standalone_differences=0,corner_checks=0;
    uint32_t reference_state=0,nf_state=0;
    bool logged_borrow=false,logged_tie_even=false,logged_tie_odd=false;
    auto check=[&](const l1::PrepackProduct& p,uint32_t c,const typename M::Result& actual,bool main,uint64_t serial) {
        const auto expected=O::add(p,c,metadata(p));
        if (actual.bits!=expected.bits || actual.flags!=expected.flags) {
            std::cerr<<"W="<<W<<" serial="<<serial<<" p="<<p.magnitude<<" scale="<<p.scale
                     <<" c="<<std::hex<<c<<" got="<<actual.bits<<'/'<<actual.flags
                     <<" ref="<<expected.bits<<'/'<<expected.flags<<std::dec<<'\n';
            throw std::runtime_error("F_W bits/flags versus full-grid oracle");
        }
        const auto& t=actual.trace;
        if (actual.bits!=O::NAR && !expected.zero) {
            const auto sliced=O::slice(p,c,expected,W);
            require(t.anchor==sliced.anchor && t.magnitude==sliced.magnitude && t.residual==sliced.tail,
                    "retained sum or signed residual versus independent grid slice");
            require(t.sf==expected.sf && t.sign==expected.sign,"normalize sf/sign");
            require(t.guard==expected.guard && t.round==expected.round && t.sticky==expected.sticky,
                    "final GRS versus full-grid stream");
            const auto cv=O::decode(c);
            const bool independent_near=!p.is_zero&&p.magnitude&&cv.coefficient&&(p.sign!=cv.sign)
                && std::abs(p.scale+O::highest(p.magnitude)-int(p.fractional_bits)-cv.sf)<=4;
            require(t.near_before==independent_near,"near-cancellation counter");
        }
        const bool even_tie=t.guard&&!t.round&&!t.sticky&&!t.retained_lsb;
        const bool odd_tie=t.guard&&!t.round&&!t.sticky&&t.retained_lsb;
        const bool notable=(t.borrow&&!logged_borrow)||(even_tie&&!logged_tie_even)||(odd_tie&&!logged_tie_odd);
        if (serial<32 || notable) {
            trace<<"{\"main\":"<<(main?"true":"false")<<",\"serial\":"<<serial
                 <<",\"P\":"<<p.magnitude<<",\"scale\":"<<p.scale<<",\"q\":"<<p.fractional_bits
                 <<",\"C_eff\":"<<c<<",\"anchor\":"<<t.anchor<<",\"P_ret\":\""<<hex128(t.p_retained)
                 <<"\",\"C_ret\":\""<<hex128(t.c_retained)<<"\",\"sum_magnitude\":\""<<hex128(t.magnitude)
                 <<"\",\"residual\":"<<t.residual<<",\"residual_sign\":"<<t.residual_sign
                 <<",\"borrow\":"<<t.borrow<<",\"sf\":"<<t.sf<<",\"sign\":"<<t.sign
                 <<",\"G\":"<<t.guard<<",\"R\":"<<t.round<<",\"S\":"<<t.sticky
                 <<",\"bits\":"<<actual.bits<<",\"flags\":"<<actual.flags<<"}\n";
        }
        logged_borrow|=t.borrow;logged_tie_even|=even_tie;logged_tie_odd|=odd_tie;
        tie_even+=even_tie;tie_odd+=odd_tie;sat_max+=(actual.flags&8)!=0;sat_min+=(actual.flags&4)!=0;
        borrow+=t.borrow;tails+=t.residual;
        if (main) {
            near+=t.near_before;near_after+=t.near_after;
            zero+=expected.zero;nar+=actual.bits==O::NAR;
            prior_zero+=expected.zero&&(actual.flags&2);
        } else ++corner_checks;
    };
    for (uint64_t i=0;i<count;++i) {
        week12::Case row{};
        input.read(reinterpret_cast<char*>(&row),sizeof(row));
        require(bool(input)&&row.reserved==0&&(row.control&~7u)==0,"corpus row schema");
        const bool mode=row.control&1,clear=row.control&2,reset=row.control&4;
        if (reset) {state.reset();reference_state=0;nf_state=0;commits_epoch=0;++resets;}
        l1::IterConfig cfg;cfg.n=row.n;cfg.ops=row.ops;cfg.rounding=l1::RoundMode::RNE;
        const auto p=l1::L1MultiplierIter<32,3,12>::mul(row.a,row.b,cfg).prepack;
        const uint32_t effective=mode?(clear?0:reference_state):row.c;
        const auto actual=state.step(row.a,row.b,row.c,mode,clear,cfg);
        require(actual.c_eff==effective,"F C_eff versus independent state");
        check(p,effective,actual,true,i);
        const auto expected=O::add(p,effective,metadata(p));
        const uint32_t nf_effective=mode?(clear?0:nf_state):row.c;
        const auto nf=week11::Model<32,3,12>::mac(row.a,row.b,nf_effective,false,row.n,row.ops);
        nf_differences+=nf.bits!=actual.bits;
        standalone_differences+=!mode&&nf.bits!=actual.bits;
        if (mode) {reference_state=expected.bits;nf_state=nf.bits;++accum;}
        require(uint32_t(state.value())==reference_state,"F accumulator value");
        ++commits_epoch;require(state.commits()==commits_epoch,"transaction commit count");
        clears+=clear;++n_hits[row.n];++ops_hits[row.ops];
        if ((i+1)%250000==0) std::cout<<"W12 WINDOW progress W="<<W<<" checked="<<i+1<<std::endl;
    }
    // Synthetic admitted prepack records: extremes, metadata, cancellation and residual sign.
    const uint64_t magnitudes[]={4096,4097,8191,8192,16383};
    const int scales[]={-480,-240,-1,0,1,239,240,480};
    const uint32_t corners[]={0,1,2,O::NAR-1,O::NAR,O::NAR+1,O::MASK,0x40000000u,0xc0000000u,0x3fffffffu};
    for (auto mag:magnitudes) for (int scale:scales) for (unsigned sign=0;sign<2;++sign)
        for (uint32_t c:corners) for (unsigned meta=0;meta<8;++meta) {
            l1::PrepackProduct p;
            p.magnitude=mag;p.scale=scale;p.fractional_bits=12;p.magnitude_bits=14;p.sign=sign;
            p.input_cut=meta&1;p.iteration_cut=meta&2;p.term_cut=meta&4;
            const auto value=M::add(p,c);
            check(p,c,value,false,corner_checks);
        }
    // Construct even/odd halfway cases independent of random hit probability.
    l1::PrepackProduct one;one.magnitude=4096;one.fractional_bits=12;one.magnitude_bits=14;
    const l1::posit_unpacked<32,3> half_ulp{false,false,false,-27,uint64_t(1)<<63,true};
    const l1::posit_unpacked<32,3> three_halves{false,false,false,-26,uint64_t(3)<<62,true};
    for (auto c:{uint32_t(l1::pack(half_ulp)),uint32_t(l1::pack(three_halves))}) check(one,c,M::add(one,c),false,corner_checks);
    // Invalid requests do not clear/commit the accumulator.
    const auto saved=state.value();const auto commits=state.commits();
    for (unsigned invalid=0;invalid<6;++invalid) {
        l1::IterConfig cfg;cfg.rounding=l1::RoundMode::RNE;
        if (invalid==0) cfg.exact=true;
        if (invalid==1) cfg.n=9;
        if (invalid==2) cfg.ops=2;
        if (invalid==3) cfg.scheme=l1::ShiftRound::STICKY_ACC;
        if (invalid==4) cfg.rounding=l1::RoundMode::TRUNC;
        bool rejected=false;
        try {state.step(0x40000000u,0x40000000u,0,invalid!=5,true,cfg);}
        catch (const std::invalid_argument&) {rejected=true;}
        require(rejected && state.value()==saved && state.commits()==commits,"invalid request changed state");
    }
    require(tie_even&&tie_odd&&borrow&&tails&&sat_max&&sat_min&&prior_zero&&accum&&clears&&resets,
            "missing flags/residual/state corner coverage");
    require(near*10>=3*count&&near_after*10>=3*count,"near-cancellation distribution below30%");
    for (auto hits:n_hits) require(hits>=(count>=1000000?100000:10000),"per-n distribution");
    std::ofstream report(prefix+".json");require(bool(report),"window report");
    report<<"{\n\"status\":\"PASS\",\"W\":"<<W<<",\"Q\":"<<W-3<<",\"seed_base\":20261014,\"cases\":"<<count
          <<",\"near_before\":"<<near<<",\"near_after\":"<<near_after<<",\"borrow\":"<<borrow<<",\"tail\":"<<tails
          <<",\"zero\":"<<zero<<",\"NaR\":"<<nar<<",\"zero_prior_inexact\":"<<prior_zero
          <<",\"tie_even\":"<<tie_even<<",\"tie_odd\":"<<tie_odd<<",\"sat_max\":"<<sat_max<<",\"sat_min\":"<<sat_min
          <<",\"resets\":"<<resets<<",\"acc_clr\":"<<clears<<",\"acc_transactions\":"<<accum
          <<",\"NF_F_differences\":"<<nf_differences<<",\"standalone_NF_F_differences\":"<<standalone_differences
          <<",\"corner_checks\":"<<corner_checks<<",\"invalid_rejected\":6,\"F_W_F_ref_bit_differences\":0,\"mismatches\":0,\"n_hits\":[";
    for (unsigned n=0;n<9;++n) report<<(n?",":"")<<n_hits[n];
    report<<"],\"ops_hits\":["<<ops_hits[0]<<','<<ops_hits[1]<<"]}\n";
    std::cout<<"W12 WINDOW PASS W="<<W<<" cases="<<count<<" corners="<<corner_checks<<" near="<<near
             <<" F_W_F_ref_differences=0 mismatches=0"<<std::endl;
    return 0;
}
}
int main(int argc,char**argv) try {
    if (argc!=5) throw std::invalid_argument("usage: test_week12_window corpus count W report_prefix");
    const uint64_t count=std::stoull(argv[2]);
    const unsigned width=unsigned(std::stoul(argv[3]));
    if (count<100000) throw std::invalid_argument("pilot requires100000");
    switch (width) {
        case 32:return run<32>(argv[1],count,argv[4]);
        case 48:return run<48>(argv[1],count,argv[4]);
        case 64:return run<64>(argv[1],count,argv[4]);
        case 96:return run<96>(argv[1],count,argv[4]);
        default:throw std::invalid_argument("window candidate");
    }
} catch (const std::exception& error) {std::cerr<<"FAIL "<<error.what()<<'\n';return 1;}
