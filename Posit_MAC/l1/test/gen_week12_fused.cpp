#include <fstream>
#include <iostream>
#include <random>
#include <stdexcept>
#include "../../tb/week12_corpus.hpp"
#include "../../tb/week11_model.hpp"
int main(int argc,char**argv) try {
    if (argc!=3) throw std::invalid_argument("usage: gen_week12_fused output.bin samples");
    const uint64_t count=std::stoull(argv[2]);
    std::ofstream out(argv[1],std::ios::binary);
    if (!out || count<100000) throw std::runtime_error("corpus output/count");
    std::mt19937_64 rng(20261014);
    for (uint64_t i=0;i<count;++i) {
        week12::Case row{uint32_t(rng()),uint32_t(rng()),uint32_t(rng()),
            uint8_t(i%9),uint8_t((i/9)%2),0,0};
        const bool acc=i%4==3,clear=acc&&i%97==3,reset=i%4093==0;
        row.control=uint8_t(acc|(clear<<1)|(reset<<2));
        switch (i%20) {
            case 0:row.a=0;break;
            case 1:row.a=0x80000000u;break;
            case 2:row.c=0x80000000u;break;
            case 3:row.c=0;break;
            case 4:row.b=0;break;
            default:
                if (i%20<=16) {
                    l1::IterConfig cfg;cfg.n=row.n;cfg.ops=row.ops;
                    const auto p=l1::L1MultiplierIter<32,3,12>::mul(row.a,row.b,cfg).prepack;
                    row.c=0u-week11::dyadic<32,3>(p);
                    if (i%3==0) ++row.c;
                    if (i%3==1) --row.c;
                }
                break;
        }
        out.write(reinterpret_cast<const char*>(&row),sizeof(row));
    }
    if (!out) throw std::runtime_error("corpus write");
    std::cout<<"W12 CORPUS GENERATED count="<<count<<" seed=20261014 record_bytes=16\n";
} catch (const std::exception& error) {std::cerr<<"FAIL "<<error.what()<<'\n';return 1;}
