#include <filesystem>
#include <fstream>
#include <iostream>
#include "../../tb/nf_coverage_corpus.hpp"
#include "../../l0/softposit_api.h"

template<int NB, int ES> void generate(const std::filesystem::path& dir) {
    using Corpus=nf_coverage::Corpus<NB,ES>;
    using Model=typename Corpus::Model;
    constexpr uint32_t nar=Corpus::NAR, mask=Corpus::MASK, one=Corpus::ONE;
    constexpr uint32_t fmask=(uint32_t(1)<<Corpus::F)-1;
    const uint32_t corners[]={0,nar,one,(0u-one)&mask,1,mask,nar-1,nar+1};
    const uint32_t fractions[]={0,fmask,0xaaaaaaaa&fmask,0x55555555&fmask};
    std::ofstream out(dir/("mac_"+std::to_string(NB)+"_"+std::to_string(ES)+".txt"));
    if (!out) throw std::runtime_error("cannot create corner fixture");
    unsigned rows=0, max_iterations=0, l0_checks=0;
    auto emit=[&](uint32_t a, uint32_t b, uint32_t c, unsigned mode, unsigned n, unsigned ops) {
        const auto result=Model::mac(a,b,c,!mode,n,ops);
        max_iterations=std::max(max_iterations,result.iterations);
        if (!mode && ES!=3) {
            uint32_t ref;
            if constexpr (NB==8) ref=l0_p8_add(l0_p8_mul(a,b),c);
            else if constexpr (NB==16) ref=l0_p16_add(l0_p16_mul(a,b),c);
            else ref=l0_p32_add(l0_p32_mul(a,b),c);
            if (ref!=result.bits) throw std::runtime_error("corner L0 disagreement");
            ++l0_checks;
        }
        out<<std::hex<<a<<' '<<b<<' '<<c<<' '<<result.bits<<' '<<result.flags
           <<std::dec<<' '<<mode<<' '<<n<<' '<<ops<<" 0 0 "<<(rows%97==0)
           <<" 0 "<<std::max(1u,result.iterations)+10<<'\n';
        ++rows;
    };
    for (unsigned mode=0;mode<2;++mode) {
        for (unsigned n=0;n<=8;++n) {
            for (unsigned ops=0;ops<2;++ops) {
                for (auto a:corners) for (auto b:corners) for (auto c:corners)
                    emit(a,b,c,mode,n,ops);
                for (auto fa:fractions) for (auto fb:fractions) {
                    for (unsigned signs=0;signs<4;++signs) {
                        uint32_t a=one|fa, b=one|fb;
                        if (signs&1) a=(0u-a)&mask;
                        if (signs&2) b=(0u-b)&mask;
                        emit(a,b,0,mode,n,ops);
                    }
                }
            }
        }
    }
    if (max_iterations!=Corpus::F) throw std::runtime_error("missing all-ones exact depth");
    std::cout<<"CORNER "<<NB<<'/'<<ES<<" rows="<<rows<<" max_iterations="<<max_iterations
             <<" L0_checks="<<l0_checks<<" mismatches=0\n";
}
int main() try {
    const std::filesystem::path dir="results/nf_corners_20261014/fixtures";
    std::filesystem::create_directories(dir);
    generate<8,0>(dir);
    generate<16,1>(dir);
    generate<32,2>(dir);
    generate<32,3>(dir);
} catch (const std::exception& e) {
    std::cerr<<"FAIL "<<e.what()<<'\n';
    return 1;
}
