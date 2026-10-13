#include <fstream>
#include <iostream>
#include <random>
#include "../../tb/week11_fused_model.hpp"

int main() try {
    std::mt19937_64 rng(20261013);
    std::ofstream out("results/week11/fused_pilot.txt");
    uint64_t differences=0,zero=0,checked=0;
    for(unsigned i=0;i<100000;++i) {
        const uint32_t a=uint32_t(rng()), b=uint32_t(rng());
        uint32_t c=uint32_t(rng());
        l1::IterConfig cfg;
        cfg.n=i%9; cfg.ops=1; cfg.rounding=l1::RoundMode::RNE;
        const auto m=l1::L1MultiplierIter<32,3,12>::mul(a,b,cfg);
        const uint32_t product=week11::dyadic<32,3>(m.prepack);
        if(i%4==0) c=0u-product;
        if(i%4==1) c=0u-product+1;
        if(i%4==2) c=0;
        const auto f=week11::FusedFullSum<32,3>::add(m.prepack,c);
        const auto nf=week10_reference::Adder<32,3>::add(product,c);
        differences+=f.bits!=nf.rne;
        zero+=f.zero;
        out<<m.prepack.magnitude<<' '<<m.prepack.scale<<' '<<m.prepack.fractional_bits
           <<' '<<m.prepack.sign<<' '<<m.prepack.is_zero<<' '<<m.prepack.is_nar
           <<' '<<c<<' '<<f.bits<<' '<<f.sign<<' '<<f.top<<' '<<f.zero<<'\n';
        ++checked;
    }
    std::cout<<"W11 F PILOT GENERATED checked="<<checked<<" NF_F_differences="<<differences
             <<" exact_zero="<<zero<<" seed=20261013; independent Python audit required\n";
} catch(const std::exception& e) {std::cerr<<"FAIL "<<e.what()<<'\n';return 1;}
