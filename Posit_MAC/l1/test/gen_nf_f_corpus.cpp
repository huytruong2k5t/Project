#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <stdexcept>
#include "l1_multiplier_exact.hpp"
#include "../../tb/week9_exact_reference.hpp"

int main(int argc,char**argv) try {
    if(argc!=3) throw std::invalid_argument("usage: gen_nf_f_corpus output_file samples");
    const uint64_t samples=std::stoull(argv[2]);
    if(samples<100000) throw std::invalid_argument("paired pilot requires at least100000 triples");
    const std::filesystem::path path=argv[1];
    std::filesystem::create_directories(path.parent_path());
    std::ofstream out(path);
    if(!out) throw std::runtime_error("cannot create corpus");
    std::mt19937_64 rng(20261012);
    uint64_t product_checks=0;
    for(uint64_t i=0;i<samples;++i) {
        uint32_t a=uint32_t(rng()),b=uint32_t(rng()),c=uint32_t(rng());
        switch(i%10) {
            case 0:a=0;break;
            case 1:c=0;break;
            case 2: {
                const uint32_t product=exact_reference<32,3>(a,b);
                if(product!=uint32_t(l1::L1MultiplierExact<32,3>::mul(a,b)))
                    throw std::runtime_error("cancellation corpus product oracle");
                ++product_checks;
                c=0u-product;
                break;
            }
            case 3: {
                const uint32_t product=exact_reference<32,3>(a,b);
                if(product!=uint32_t(l1::L1MultiplierExact<32,3>::mul(a,b)))
                    throw std::runtime_error("near-cancellation corpus product oracle");
                ++product_checks;
                c=(0u-product)+(((i/10)&1)?1u:uint32_t(-1));
                break;
            }
            case 4:a=0x80000000u;break;
            default:break;
        }
        out<<std::hex<<std::setfill('0')<<std::setw(8)<<a<<' '<<std::setw(8)<<b
           <<' '<<std::setw(8)<<c<<'\n';
    }
    std::cout<<"PAIRED INPUT CORPUS PASS samples="<<samples<<" seed=20261012"
             <<" cancellation_product_checks="<<product_checks
             <<"; input fixture only, no NF/F accuracy measured\n";
    return 0;
} catch(const std::exception& error) {
    std::cerr<<"FAIL: "<<error.what()<<'\n';return 1;
}
