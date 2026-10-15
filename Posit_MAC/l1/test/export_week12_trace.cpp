#include <algorithm>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include "posit_fused_window.hpp"
#include "../../tb/week12_corpus.hpp"
std::string hex128(unsigned __int128 value) {
    std::string text;
    do {text.push_back("0123456789abcdef"[unsigned(value&15)]);value>>=4;} while (value);
    std::reverse(text.begin(),text.end());return text;
}
int main(int argc,char**argv) try {
    if (argc!=3) throw std::invalid_argument("usage: export_week12_trace corpus trace.jsonl");
    using M=l1::FusedWindow<32,3,12,32>;
    l1::FusedWindowAccumulator<32,3,12,32> state;
    std::ifstream in(argv[1],std::ios::binary);std::ofstream out(argv[2]);
    if (!in || !out) throw std::runtime_error("trace IO");
    auto emit=[&](const l1::PrepackProduct& p,uint32_t c,const M::Result& value) {
        const auto& t=value.trace;
        out<<"{\"P\":"<<p.magnitude<<",\"scale\":"<<p.scale<<",\"q\":"<<p.fractional_bits
           <<",\"p_sign\":"<<p.sign<<",\"p_zero\":"<<p.is_zero<<",\"p_nar\":"<<p.is_nar
           <<",\"input_cut\":"<<p.input_cut<<",\"iteration_cut\":"<<p.iteration_cut<<",\"term_cut\":"<<p.term_cut
           <<",\"C_eff\":"<<c<<",\"anchor\":"<<t.anchor
           <<",\"P_ret\":\""<<hex128(t.p_retained)<<"\",\"C_ret\":\""<<hex128(t.c_retained)
           <<"\",\"magnitude\":\""<<hex128(t.magnitude)<<"\",\"residual\":"<<t.residual
           <<",\"residual_sign\":"<<t.residual_sign<<",\"borrow\":"<<t.borrow
           <<",\"sign\":"<<t.sign<<",\"sf\":"<<t.sf<<",\"G\":"<<t.guard<<",\"R\":"<<t.round
           <<",\"S\":"<<t.sticky<<",\"bits\":"<<value.bits<<",\"flags\":"<<value.flags<<"}\n";
    };
    for (unsigned i=0;i<128;++i) {
        week12::Case row{};in.read(reinterpret_cast<char*>(&row),sizeof(row));
        if (!in) throw std::runtime_error("trace short corpus");
        if (row.control&4) state.reset();
        l1::IterConfig cfg;cfg.n=row.n;cfg.ops=row.ops;cfg.rounding=l1::RoundMode::RNE;
        const auto p=l1::L1MultiplierIter<32,3,12>::mul(row.a,row.b,cfg).prepack;
        const auto result=state.step(row.a,row.b,row.c,row.control&1,row.control&2,cfg);
        emit(p,result.c_eff,result);
    }
    l1::PrepackProduct one;one.magnitude=4096;one.fractional_bits=12;one.magnitude_bits=14;
    for (int sf:{-31,-27,-26,0,240}) for (bool sign:{false,true}) {
        l1::posit_unpacked<32,3> c{sign,false,false,sf,uint64_t(1)<<63,true};
        const auto bits=uint32_t(l1::pack(c));emit(one,bits,M::add(one,bits));
    }
    std::cout<<"W12 TRACE EXPORTED cases=138\n";
} catch (const std::exception& error) {std::cerr<<"FAIL "<<error.what()<<'\n';return 1;}
