#include <filesystem>
#include <fstream>
#include <iostream>
#include <random>
#include "../../tb/nf_coverage_corpus.hpp"
#include "../../l0/softposit_api.h"

template<int NB, int ES> void generate(const std::filesystem::path& dir) {
    using Corpus=nf_coverage::Corpus<NB,ES>;
    using Model=typename Corpus::Model;
    const uint64_t seed=20261014+NB*100+ES;
    std::mt19937_64 rng(seed);
    uint32_t accumulator=0;
    unsigned completed=0, aborted=0, l0_checks=0;
    std::ofstream out(dir/("mac_"+std::to_string(NB)+"_"+std::to_string(ES)+".txt"));
    if (!out) throw std::runtime_error("cannot create fixture");
    for (unsigned i=0; i<7200; ++i) {
        const bool reset=i%97==0;
        const unsigned abort_delay=i%101==0 ? 1+(i/101)%24 : 0;
        if (reset) accumulator=0;
        const auto v=Corpus::next(rng,i,accumulator);
        const uint32_t effective=v.acc_mode ? (v.acc_clr ? 0 : accumulator) : v.c;
        const auto result=Model::mac(v.a,v.b,effective,!v.mode,v.n,v.ops);
        if (!v.mode && ES!=3) {
            uint32_t ref;
            if constexpr (NB==8) ref=l0_p8_add(l0_p8_mul(v.a,v.b),effective);
            else if constexpr (NB==16) ref=l0_p16_add(l0_p16_mul(v.a,v.b),effective);
            else ref=l0_p32_add(l0_p32_mul(v.a,v.b),effective);
            if (ref!=result.bits) throw std::runtime_error("fixture L0 disagreement");
            ++l0_checks;
        }
        out<<std::hex<<v.a<<' '<<v.b<<' '<<v.c<<' '<<result.bits<<' '<<result.flags
           <<std::dec<<' '<<v.mode<<' '<<v.n<<' '<<v.ops<<' '<<v.acc_mode<<' '<<v.acc_clr
           <<' '<<reset<<' '<<abort_delay<<' '<<std::max(1u,result.iterations)+10<<'\n';
        if (abort_delay) { accumulator=0; ++aborted; }
        else { if (v.acc_mode) accumulator=result.bits; ++completed; }
    }
    std::cout<<"FIXTURE "<<NB<<'/'<<ES<<" seed="<<seed<<" completed="<<completed
             <<" aborted="<<aborted<<" L0_checks="<<l0_checks<<" mismatches=0\n";
}
int main(int argc, char** argv) try {
    const std::filesystem::path dir=argc>1 ? argv[1] : "results/nf_coverage_20261014/fixtures";
    std::filesystem::create_directories(dir);
    generate<8,0>(dir);
    generate<16,1>(dir);
    generate<32,2>(dir);
    generate<32,3>(dir);
} catch (const std::exception& e) {
    std::cerr<<"FAIL "<<e.what()<<'\n';
    return 1;
}
