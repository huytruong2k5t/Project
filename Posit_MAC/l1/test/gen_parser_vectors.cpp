#include <fstream>
#include <iostream>
#include <random>
#include <array>
#include <algorithm>
#include "posit_parser.hpp"
using namespace l1;
// Independent sequential field decoder, unlike L1's fixed-width shifts.
template<int NB,int ES> posit_unpacked<NB,ES> fields(uint32_t p) {
    posit_unpacked<NB,ES> u{};u.exact=true;u.sign=p>>(NB-1);
    if(!p) {u.is_zero=true;return u;}
    if(p==(uint32_t(1)<<(NB-1))) {u.is_nar=true;return u;}
    uint32_t mask=uint32_t((uint64_t(1)<<NB)-1);
    uint32_t mag=u.sign?(-p)&mask:p;
    int cursor=NB-2;bool r=(mag>>cursor)&1;int run=0;
    while(cursor>=0 && bool((mag>>cursor)&1)==r) {++run;--cursor;}
    int k=r?run-1:-run;if(cursor>=0) --cursor;
    int e=0;for(int j=0;j<ES;++j) {e<<=1;if(cursor>=0) e|=(mag>>cursor--)&1;}
    u.sf=k*(1<<ES)+e;u.frac=uint64_t(1)<<63;
    for(int j=62;cursor>=0;--cursor,--j) u.frac|=uint64_t((mag>>cursor)&1)<<j;
    return u;
}
uint64_t total=0;
template<int NB,int ES> void emit(std::ofstream& out,uint32_t p) {
    auto a=parse<NB,ES>(p),b=fields<NB,ES>(p);
    if(a.sign!=b.sign || a.is_zero!=b.is_zero || a.is_nar!=b.is_nar || a.sf!=b.sf || a.frac!=b.frac)
        throw std::runtime_error("L1/independent field oracle mismatch");
    constexpr int F=NB-3-ES;
    uint64_t f=(a.frac>>(63-F))&((uint64_t(1)<<F)-1);
    out<<std::hex<<p<<' '<<std::dec<<a.sign<<' '<<a.is_zero<<' '<<a.is_nar<<' '<<a.sf<<' '<<std::hex<<f<<'\n';
    ++total;
}
template<int NB,int ES> void generate(const std::string& directory,uint64_t samples,uint64_t seed) {
    std::string name=directory+"/parser_"+std::to_string(NB)+"_"+std::to_string(ES)+".txt";
    std::ofstream out(name);if(!out) throw std::runtime_error("open vector file");
    uint64_t before=total;
    if constexpr(NB<=16) {for(uint32_t p=0;p<(uint32_t(1)<<NB);++p) emit<NB,ES>(out,p);}
    else {
        const uint32_t corner[]={0,0x80000000,1,2,0xffffffff,0xfffffffe,0x7fffffff,0x80000001,0x40000000,0xc0000000};
        for(auto p:corner) emit<NB,ES>(out,p);
        std::mt19937_64 rng(seed);uint64_t lengths[2][32]{},cells[8][2]{};
        constexpr unsigned lo[]={1,4,8,12,16,18,23,28},hi[]={3,7,11,15,17,22,27,31};
        for(uint64_t i=0;i<samples;++i) {
            // Cycle all 61 finite regime polarity/run combinations, both signs.
            unsigned slot=(i/2)%61;bool rc=slot>=30;unsigned run=rc?slot-29:slot+1;
            uint32_t mag=0;
            for(unsigned j=0;j<run;++j) if(rc) mag|=uint32_t(1)<<(30-j);
            unsigned remaining=31-run;
            if(remaining) {if(!rc) mag|=uint32_t(1)<<(remaining-1);--remaining;}
            unsigned eb=std::min(unsigned(ES),remaining),fb=remaining-eb;
            uint32_t fm=fb?(uint32_t(1)<<fb)-1:0,f=uint32_t(rng())&fm;
            switch((i/122)%6) {case 0:f=0;break;case 1:f=fm;break;case 2:f=0xaaaaaaaa&fm;break;case 3:f=0x55555555&fm;break;case 4:f=fb?uint32_t(1)<<(rng()%fb):0;break;default:break;}
            mag|=((uint32_t(rng())&((uint32_t(1)<<eb)-1))<<fb)|f;
            bool negative=i&1;emit<NB,ES>(out,negative?0u-mag:mag);++lengths[rc][run];
            for(unsigned g=0;g<8;++g) if(run>=lo[g] && run<=hi[g]) ++cells[g][negative];
        }
        uint64_t minimum=UINT64_MAX,grid=UINT64_MAX;
        for(unsigned r=0;r<2;++r) for(unsigned j=1;j<=(r?31:30);++j) minimum=std::min(minimum,lengths[r][j]);
        for(auto& row:cells) for(auto n:row) grid=std::min(grid,n);
        if(minimum<10000 || grid<4000) throw std::runtime_error("parser stratified coverage");
        std::cout<<"COVER NB="<<NB<<" ES="<<ES<<" min_polarity_run="<<minimum<<" min_group_sign="<<grid<<'\n';
    }
    out.close();if(!out) throw std::runtime_error("write vectors");
    std::cout<<"VECTORS NB="<<NB<<" ES="<<ES<<" count="<<total-before<<" seed="<<seed<<" L1_AND_FIELD_ORACLE_PASS\n";
}
int main(int argc,char** argv) {try {
    if(argc!=2) throw std::invalid_argument("usage: gen_parser_vectors OUTPUT_DIRECTORY");
    generate<8,0>(argv[1],0,20261005);generate<16,1>(argv[1],0,20261005);
    generate<32,2>(argv[1],1200000,20261005);generate<32,3>(argv[1],1200000,20261005);
    std::cout<<"GENERATOR PASS total="<<total<<'\n';
} catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}}
