#include <filesystem>
#include <fstream>
#include <iostream>
#include <random>
#include "sac.hpp"
#include "sbm.hpp"
int main(int argc,char** argv) {
    if(argc!=2) return 2;
    std::filesystem::create_directories(argv[1]);
    std::mt19937_64 rng(20261009);
    for(unsigned f:{1u,5u,12u,26u,27u}) {
        const unsigned fw=std::min(f,12u);
        for(unsigned scheme=0;scheme<2;++scheme) {
            std::ofstream out(std::filesystem::path(argv[1]) /
                ("core_"+std::to_string(f)+"_"+std::to_string(scheme)+".txt"));
            for(unsigned row=0;row<4000;++row) {
                bool mode=row&1;
                unsigned w=mode?fw:f,n=row%9;
                uint64_t x=rng()&((uint64_t(1)<<w)-1);
                uint64_t y=(uint64_t(1)<<w)|(rng()&((uint64_t(1)<<w)-1));
                if(row<2*w) x=uint64_t(1)<<(row/2);
                if(row%31==0) x=0;
                if(row%31==1) x=(uint64_t(1)<<w)-1;
                unsigned q=mode?fw+2*scheme:2*f;
                l1::SacState sac(x,w);
                l1::SbmState sbm(y,w,q);
                bool numerical=false;
                while(sac.fx && sac.iterations<(mode?n:f)) {
                    sac.step();
                    numerical |= (sbm.y & ((uint64_t(1)<<sac.scale)-1))!=0;
                    sbm.add(sac.scale,!mode||scheme==1);
                }
                unsigned pad=mode&&scheme==0?2:0;
                out<<std::hex<<mode<<' '<<x<<' '<<y<<' '<<n<<' '<<(sbm.acc<<pad)<<' '
                   <<sbm.sticky<<' '<<numerical<<' '<<sac.iterations<<' '<<(sac.fx!=0)<<' '
                   <<std::dec<<int(row%801)-400<<' '<<(row&2?1:0)<<' '<<(row&4?1:0)<<'\n';
            }
        }
    }
    std::cout<<"CORE GENERATOR PASS transactions=40000 seed=20261009\n";
}
