#include <filesystem>
#include <fstream>
#include <iostream>
#include <random>
#include <stdexcept>
#include <vector>
#include "l1_multiplier_iter.hpp"
#include "../../l0/softposit_api.h"

// Independent decode, integer product and bit-list encoder for ES=3.
// Does not call the L1 parser, multiplier, normalizer or packer.
template<int NB,int ES> uint32_t exact_reference(uint32_t a,uint32_t b) {
    const uint32_t mask=uint32_t((uint64_t(1)<<NB)-1),nar=uint32_t(1)<<(NB-1);
    if(a==nar||b==nar) return nar;
    if(!a||!b) return 0;
    auto decode=[&](uint32_t p) {
        uint32_t m=(p&nar)?(0u-p)&mask:p;
        int bit=NB-2,run=0;
        bool r=(m>>bit)&1;
        while(bit>=0 && bool((m>>bit)&1)==r) {++run;--bit;}
        if(bit>=0) --bit;
        int e=0;
        for(int k=0;k<ES;++k) {e*=2;if(bit>=0)e|=(m>>bit--)&1;}
        const unsigned fb=unsigned(bit+1);
        const uint64_t sig=(uint64_t(1)<<fb)|(m&((uint64_t(1)<<fb)-1));
        return std::pair<uint64_t,int>{sig,(r?run-1:-run)*(1<<ES)+e-int(fb)};
    };
    auto x=decode(a),y=decode(b);
    uint64_t p=x.first*y.first;
    int top=0;
    for(uint64_t v=p;v>>=1;) ++top;
    int sf=x.second+y.second+top,lim=(NB-2)*(1<<ES);
    uint32_t mag;
    if(sf>=lim) mag=nar-1;
    else if(sf < -lim) mag=1;
    else {
        int k=sf/(1<<ES);
        if(sf<0 && sf%(1<<ES)) --k;
        int e=sf-k*(1<<ES);
        std::vector<bool> bits;
        bits.insert(bits.end(),k>=0?k+1:-k,k>=0);
        bits.push_back(k<0);
        for(int i=ES-1;i>=0;--i) bits.push_back((e>>i)&1);
        for(int i=top-1;i>=0;--i) bits.push_back((p>>i)&1);
        while(bits.size()<unsigned(NB+1)) bits.push_back(false);
        mag=0;
        for(int i=0;i<NB-1;++i) mag=2*mag+bits[i];
        bool tail=false;
        for(unsigned i=NB;i<bits.size();++i) tail|=bits[i];
        if(bits[NB-1] && ((mag&1)||tail)) ++mag;
        mag=std::max(1u,std::min(nar-1,mag));
    }
    return (((a^b)&nar)?0u-mag:mag)&mask;
}
uint64_t total=0,l0_checks=0,es3_checks=0;
// Build a finite operand at a chosen regime run/polarity without using L1.
// Groups are clipped for small NB. The all-zero payload is excluded here;
// Zero and NaR remain explicit corners below.
template<int NB> uint32_t stratified_operand(unsigned group,unsigned sign,
                                             uint64_t cycle,std::mt19937_64& rng) {
    constexpr unsigned lows[]={1,4,8,12,16,18,23,28};
    constexpr unsigned highs[]={3,7,11,15,17,22,27,31};
    unsigned lo=lows[group],hi=std::min(highs[group],unsigned(NB-1));
    unsigned run=lo+unsigned(cycle%(hi-lo+1));
    unsigned polarity=unsigned((cycle/(hi-lo+1))%2);
    if(run==NB-1) polarity=1;
    uint32_t magnitude=0;
    int bit=NB-2;
    for(unsigned i=0;i<run;++i,--bit) magnitude|=polarity<<bit;
    if(bit>=0) magnitude|=(1u-polarity)<<bit--;
    if(bit>=0) {
        uint32_t tail_mask=uint32_t((uint64_t(1)<<(bit+1))-1);
        uint32_t tail=uint32_t(rng())&tail_mask;
        // Rotate structural patterns independently of the 36 config cells.
        // Tail includes exponent bits; decoding/coverage checks the real fraction.
        switch((cycle/36)%8) {
        case 0: tail=0; break;
        case 1: tail=tail_mask; break;
        case 2: tail=0xaaaaaaaau&tail_mask; break;
        case 3: tail=0x55555555u&tail_mask; break;
        case 4: tail=1u<<unsigned(rng()%unsigned(bit+1)); break;
        case 5: tail=(1u<<unsigned(rng()%unsigned(bit+1)))|
                    (1u<<unsigned(rng()%unsigned(bit+1))); break;
        default: break;
        }
        magnitude|=tail;
    }
    uint32_t mask=uint32_t((uint64_t(1)<<NB)-1);
    return sign?(0u-magnitude)&mask:magnitude;
}
template<int NB,int ES> void generate(const std::filesystem::path& dir,uint64_t count,bool stratified) {
    constexpr unsigned F=NB-3-ES,FW=std::min(F,12u);
    const uint32_t mask=uint32_t((uint64_t(1)<<NB)-1),nar=uint32_t(1)<<(NB-1);
    std::mt19937_64 rng(20261009+NB+ES);
    for(unsigned scheme=0;scheme<2;++scheme) {
        for(unsigned rounding=0;rounding<2;++rounding) {
            std::ofstream out(dir/ ("mul_"+std::to_string(NB)+"_"+std::to_string(ES)+"_"+
                std::to_string(scheme)+"_"+std::to_string(rounding)+".txt"));
            uint64_t cells[2][2][9]{};
            for(uint64_t row=0;row<count;++row) {
                uint32_t a=uint32_t(rng())&mask,b=uint32_t(rng())&mask;
                constexpr unsigned groups=NB==8?2:(NB==16?4:8);
                constexpr unsigned grid=4*groups*groups;
                if(stratified) {
                    unsigned cell=unsigned(row%grid);
                    unsigned ga=(cell/4)%groups,gb=cell/(4*groups);
                    unsigned signs=cell%4;
                    uint64_t cycle=row/grid;
                    a=stratified_operand<NB>(ga,signs/2,cycle,rng);
                    b=stratified_operand<NB>(gb,signs%2,cycle,rng);
                }
                const uint32_t corners[]={0,1,2,nar-1,nar,nar+1,mask,nar/2,nar/2+1};
                if(row<81) {a=corners[row/9];b=corners[row%9];}
                if(!stratified && row%127==81) {a=nar/2+((nar/2-1)>>1);b=mask-1;}
                l1::IterConfig cfg;
                const uint64_t config_row=stratified?row/grid:row;
                cfg.exact=(config_row%2)==0;
                cfg.ops=(config_row/2)%2;
                cfg.n=(config_row/4)%9;
                cfg.scheme=scheme?l1::ShiftRound::STICKY_ACC:l1::ShiftRound::FLOOR;
                cfg.rounding=rounding?l1::RoundMode::TRUNC:l1::RoundMode::RNE;
                const auto r=l1::L1MultiplierIter<NB,ES,FW>::mul(a,b,cfg);
                if(cfg.exact && !rounding) {
                    uint32_t oracle;
                    if constexpr (NB==8) oracle=l0_p8_mul(a,b);
                    else if constexpr (NB==16) oracle=l0_p16_mul(a,b);
                    else if constexpr (ES==2) oracle=l0_p32_mul(a,b);
                    else oracle=exact_reference<NB,ES>(a,b);
                    if(r.bits!=oracle) throw std::runtime_error("exact oracle mismatch");
                    if constexpr (ES==3) ++es3_checks; else ++l0_checks;
                }
                unsigned flags=0;
                auto u=r.unpacked;
                if(u.is_nar) flags=16;
                else if(!u.is_zero) {
                    const int lim=(NB-2)*(1<<ES);
                    const bool high=u.sf>lim || (u.sf==lim &&
                        (u.frac!=(uint64_t(1)<<63)||!u.exact));
                    flags=(high?8:0)|(u.sf < -lim?4:0)|(r.inexact?2:0)|(r.approx_cut?1:0);
                }
                ++cells[!cfg.exact][cfg.ops][cfg.n];
                out<<std::hex<<a<<' '<<b<<' '<<!cfg.exact<<' '<<cfg.n<<' '<<cfg.ops<<' '
                    <<uint32_t(r.bits)<<' '<<flags<<' '<<r.iterations<<'\n';
                ++total;
            }
            std::ofstream coverage(dir/("coverage_"+std::to_string(NB)+"_"+std::to_string(ES)+"_"+
                std::to_string(scheme)+"_"+std::to_string(rounding)+".csv"));
            coverage<<"mode,ops,n,transactions\n";
            for(unsigned m=0;m<2;++m) for(unsigned p=0;p<2;++p) for(unsigned n=0;n<9;++n)
                coverage<<m<<','<<p<<','<<n<<','<<cells[m][p][n]<<'\n';
        }
    }
}
int main(int argc,char** argv) {
    if(argc!=3 && argc!=4) return 2;
    bool stratified=argc==4 && std::string(argv[3])=="stratified";
    if(argc==4 && !stratified) return 2;
    std::filesystem::create_directories(argv[1]);
    uint64_t per_profile=std::stoull(argv[2]);
    generate<8,0>(argv[1],per_profile,stratified); generate<16,1>(argv[1],per_profile,stratified);
    generate<32,2>(argv[1],per_profile,stratified); generate<32,3>(argv[1],per_profile,stratified);
    std::cout<<"MULTIPLIER GENERATOR PASS rows="<<total<<" L0_RNE="<<l0_checks
             <<" ES3_independent_RNE="<<es3_checks<<" seed=20261009 sampling="
             <<(stratified?"stratified":"uniform_bits")<<'\n';
}
