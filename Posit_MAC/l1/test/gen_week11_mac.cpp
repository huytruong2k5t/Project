#include <filesystem>
#include <fstream>
#include <iostream>
#include <random>
#include "../../tb/week11_model.hpp"

template<int NB, int ES> void generate(const std::filesystem::path& dir) {
    constexpr unsigned F=NB-3-ES, FW=F<12 ? F : 12;
    constexpr uint32_t nar=uint32_t(1)<<(NB-1), mask=uint32_t((uint64_t(1)<<NB)-1);
    using Model=week11::Model<NB,ES,FW>;
    std::ofstream out(dir/("mac_"+std::to_string(NB)+"_"+std::to_string(ES)+".txt"));
    std::mt19937_64 rng(20261013+NB*100+ES);
    uint32_t accumulator=0;
    unsigned completed=0, aborted=0;
    for (unsigned i=0;i<7200;++i) {
        const bool reset=i%97==0;
        const unsigned abort_delay=i%101==0 ? 1+(i/101)%24 : 0;
        if (reset) accumulator=0;
        uint32_t a=uint32_t(rng())&mask, b=uint32_t(rng())&mask, c=uint32_t(rng())&mask;
        const unsigned n=i%9, ops=(i/9)%2, mode=(i/18)%2;
        const bool acc_mode=(i/36)%2, acc_clr=acc_mode && (i/72)%7==0;
        const uint32_t one=uint32_t(1)<<(NB-2);
        switch(i%16) {
            case 0: a=0;b=nar;break;
            case 1: a=nar;b=0;break;
            case 2: c=nar;break;
            case 3: a=0;break;
            case 4: b=0;break;
            case 5: c=0;break;
            case 6: a=nar-1;b=nar-1;c=(0u-(nar-1))&mask;break;
            case 7: a=1;b=1;c=1;break;
            case 8: a=one;b=one;c=(0u-one)&mask;break;
            case 9: a=one;b=one;c=(0u-one+1)&mask;break;
            default:break;
        }
        const uint32_t effective=acc_mode ? (acc_clr ? 0 : accumulator) : c;
        const auto result=Model::mac(a,b,effective,!mode,n,ops);
        out<<std::hex<<a<<' '<<b<<' '<<c<<' '<<result.bits<<' '<<result.flags
           <<std::dec<<' '<<mode<<' '<<n<<' '<<ops<<' '<<acc_mode<<' '<<acc_clr
           <<' '<<reset<<' '<<abort_delay<<' '<<std::max(1u,result.iterations)+10<<'\n';
        if (abort_delay) { accumulator=0; ++aborted; }
        else { if(acc_mode) accumulator=result.bits; ++completed; }
    }
    std::cout<<"FIXTURE "<<NB<<'/'<<ES<<" completed="<<completed<<" aborted="<<aborted<<'\n';
}
int main() try {
    const std::filesystem::path dir="results/week11/fixtures";
    std::filesystem::create_directories(dir);
    generate<8,0>(dir); generate<16,1>(dir); generate<32,2>(dir); generate<32,3>(dir);
} catch(const std::exception& e) {std::cerr<<"FAIL "<<e.what()<<'\n';return 1;}
