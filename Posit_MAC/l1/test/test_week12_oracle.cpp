#include <cstdint>
#include <fstream>
#include <iostream>
#include <random>
#include <stdexcept>
#include "../../tb/week12_fused_reference.hpp"
#include "../../tb/week11_fused_model.hpp"
#include "../../l0/softposit_api.h"

template<int NB,int ES> uint32_t soft_fma(uint32_t a,uint32_t b,uint32_t c) {
    if constexpr (NB==8) return l0_p8_mulAdd(uint8_t(a),uint8_t(b),uint8_t(c));
    if constexpr (NB==16) return l0_p16_mulAdd(uint16_t(a),uint16_t(b),uint16_t(c));
    return l0_p32_mulAdd(a,b,c);
}

template<int NB,int ES> void smoke(uint64_t samples) {
    using O=week12_reference::Oracle<NB,ES>;
    std::mt19937_64 rng(20261014+100*NB+ES);
    constexpr uint32_t corners[]={0,1,2,O::NAR-1,O::NAR,O::NAR+1,O::MASK, uint32_t(1)<<(NB-2)};
    for (uint64_t i=0;i<samples;++i) {
        uint32_t a=uint32_t(rng())&O::MASK,b=uint32_t(rng())&O::MASK,c=uint32_t(rng())&O::MASK;
        if (i<512) {a=corners[i%8];b=corners[(i/8)%8];c=corners[(i/64)%8];}
        const auto p=O::product(a,b);
        const auto value=O::add(p,c);
        const uint32_t expected=soft_fma<NB,ES>(a,b,c);
        if (value.bits!=expected) {
            std::cerr<<"FMA mismatch NB="<<NB<<" ES="<<ES<<" row="<<i<<" a/b/c="<<std::hex
                     <<a<<'/'<<b<<'/'<<c<<" got="<<value.bits<<" expected="<<expected<<std::dec<<'\n';
            throw std::runtime_error("oracle versus SoftPosit FMA");
        }
    }
    std::cout<<"ORACLE SOFTPOSIT PASS NB="<<NB<<" ES="<<ES<<" checked="<<samples<<" mismatches=0\n";
}

int main(int argc,char**argv) try {
    if (argc!=4) throw std::invalid_argument("usage: test_week12_oracle report.json p8_count smoke_count");
    const uint64_t p8_count=std::stoull(argv[2]),samples=std::stoull(argv[3]);
    if (p8_count>(uint64_t(1)<<24) || samples<100000) throw std::invalid_argument("oracle counts");
    using O8=week12_reference::Oracle<8,0>;
    uint64_t checked=0;
    for (unsigned a=0;a<256 && checked<p8_count;++a) {
        for (unsigned b=0;b<256 && checked<p8_count;++b) {
            const auto p=O8::product(a,b);
            for (unsigned c=0;c<256 && checked<p8_count;++c) {
                const auto result=O8::add(p,c);
                if (result.bits!=l0_p8_mulAdd(uint8_t(a),uint8_t(b),uint8_t(c))) {
                    std::cerr<<"P8 mismatch "<<a<<' '<<b<<' '<<c<<'\n';
                    throw std::runtime_error("p8 exhaustive oracle versus FMA");
                }
                ++checked;
            }
        }
        if (a%32==31) std::cout<<"ORACLE P8 progress="<<checked<<std::endl;
    }
    smoke<16,1>(samples);
    smoke<32,2>(samples);
    using O=week12_reference::Oracle<32,3>;
    std::mt19937_64 rng(20261014);
    uint64_t zeros=0,differences=0;
    for (uint64_t i=0;i<samples;++i) {
        const uint32_t a=uint32_t(rng()),b=uint32_t(rng());
        uint32_t c=uint32_t(rng());
        l1::IterConfig cfg;
        cfg.n=unsigned(i%9);cfg.ops=1;cfg.rounding=l1::RoundMode::RNE;
        const auto p=l1::L1MultiplierIter<32,3,12>::mul(a,b,cfg).prepack;
        const uint32_t packed=week11::dyadic<32,3>(p);
        if (i%4==0) c=0u-packed;
        if (i%4==1) c=0u-packed+1;
        if (i%4==2) c=0;
        const auto result=O::add(p,c);
        const auto old=week11::FusedFullSum<32,3>::add(p,c);
        if (result.bits!=old.bits || result.zero!=old.zero || result.sign!=old.sign)
            throw std::runtime_error("independent oracle versus limb full-sum pilot");
        differences+=result.bits!=week10_reference::Adder<32,3>::add(packed,c).rne;
        zeros+=result.zero;
    }
    std::ofstream out(argv[1]);
    if (!out) throw std::runtime_error("oracle report");
    out<<"{\n\"status\":\"PASS\",\"seed_base\":20261014,\"p8_checked\":"<<checked
       <<",\"p8_exhaustive\":"<<(checked==(uint64_t(1)<<24)?"true":"false")
       <<",\"p16_softposit_fma\":"<<samples<<",\"p32_es2_softposit_fma\":"<<samples
       <<",\"p32_es3_prepack_fullsum\":"<<samples<<",\"zeros\":"<<zeros
       <<",\"NF_F_differences\":"<<differences<<",\"mismatches\":0}\n";
    std::cout<<"W12 ORACLE PASS p8="<<checked<<" p16="<<samples<<" p32_es2="<<samples
             <<" prepack_es3="<<samples<<" mismatches=0"<<std::endl;
} catch (const std::exception& error) {
    std::cerr<<"FAIL "<<error.what()<<'\n';return 1;
}
