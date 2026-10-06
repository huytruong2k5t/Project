#include <iostream>
#include <string>
#include <vector>
#include "mac_oracle.hpp"
#include "../../l0/softposit_api.h"
uint64_t checks=0;
void require(bool ok,const char* message) {if(!ok) throw std::runtime_error(message);}
template<int NB,int ES> uint32_t reference_mul(uint32_t a,uint32_t b,RoundMode mode) {
    // Independent integer product of decoded significands, without multiplier core.
    auto u=parse<NB,ES>(a),v=parse<NB,ES>(b);
    if(u.is_nar || v.is_nar) return uint32_t(1)<<(NB-1);
    if(u.is_zero || v.is_zero) return 0;
    constexpr int F=posit_constants<NB,ES>::FRAC_MAX;
    uint64_t p=(u.frac>>(63-F))*(v.frac>>(63-F));
    int top=63-__builtin_clzll(p);
    posit_unpacked<NB,ES> r{u.sign!=v.sign,false,false,u.sf+v.sf+top-2*F,p<<(63-top),true};
    return pack<NB,ES>(r,mode);
}
template<int NB,int ES> uint32_t soft_reference(uint32_t a,uint32_t b,uint32_t c) {
    if constexpr(NB==8) return l0_p8_add(l0_p8_mul(a,b),c);
    if constexpr(NB==16) return l0_p16_add(l0_p16_mul(a,b),c);
    if constexpr(NB==32 && ES==2) return l0_p32_add(l0_p32_mul(a,b),c);
    return wide_reference<NB,ES>(reference_mul<NB,ES>(a,b,RoundMode::RNE),c,RoundMode::RNE);
}
template<int NB,int ES> void triple(uint32_t a,uint32_t b,uint32_t c,MacConfig cfg={}) {
    cfg.version=MacVersion::V0;auto v0=PositMac<NB,ES>::mac(a,b,c,cfg);
    cfg.version=MacVersion::V1;auto v1=PositMac<NB,ES>::mac(a,b,c,cfg);
    constexpr uint32_t nar=uint32_t(1)<<(NB-1);
    uint32_t expected;
    if(a==nar || b==nar || c==nar) expected=nar;
    else if(!a || !b) expected=c;
    else if(cfg.exact && cfg.rounding==RoundMode::RNE) expected=soft_reference<NB,ES>(a,b,c);
    else {
        uint32_t p;
        if(cfg.exact) p=reference_mul<NB,ES>(a,b,cfg.rounding);
        else {IterConfig ic;ic.n=cfg.n;ic.ops=cfg.ops;ic.scheme=cfg.scheme;ic.rounding=cfg.rounding;
            p=L1MultiplierIter<NB,ES>::mul(a,b,ic).bits;}
        expected=wide_reference<NB,ES>(p,c,cfg.rounding);
    }
    ++checks;
    if(v0.bits!=expected || v1.bits!=expected || v0.flags.bits()!=v1.flags.bits()) {
        std::cerr<<"FAIL NB="<<NB<<" ES="<<ES<<" a="<<std::hex<<a<<" b="<<b<<" c="<<c
                 <<" v0="<<uint32_t(v0.bits)<<" v1="<<uint32_t(v1.bits)<<" expected="<<expected<<std::dec<<'\n';
        throw std::runtime_error("MAC mismatch");
    }
    if(expected==nar) require(v1.flags.bits()==16,"NaR flags precedence");
}
template<int NB,int ES> void corners() {
    constexpr uint32_t nar=uint32_t(1)<<(NB-1),mask=uint32_t((uint64_t(1)<<NB)-1),one=uint32_t(1)<<(NB-2);
    std::vector<uint32_t> values={0,nar,1,2,3,nar-1,nar-2,nar+1,nar+2,mask,mask-1,one,one-1,one+1,(-one)&mask};
    for(auto a:values) for(auto b:values) for(auto c:values) {
        triple<NB,ES>(a,b,c);
        MacConfig t;t.rounding=RoundMode::TRUNC;triple<NB,ES>(a,b,c,t);
        t.exact=false;t.n=(a+b+c)%9;t.ops=(a^b)&1;
        t.scheme=(c&1)?ShiftRound::FLOOR:ShiftRound::STICKY_ACC;triple<NB,ES>(a,b,c,t);
        t.rounding=RoundMode::RNE;triple<NB,ES>(a,b,c,t);
    }
    auto hi=PositMac<NB,ES>::mac(nar-1,nar-1,0);
    auto lo=PositMac<NB,ES>::mac(1,1,0);
    require(hi.flags.sat_max && hi.flags.inexact,"maximum saturation flags");
    require(lo.flags.sat_min && lo.flags.inexact,"minimum saturation flags");
    require(!PositMac<NB,ES>::mac(one,one,(-one)&mask).flags.sat_min,"cancellation is not underflow");
    auto cancel_hi=PositMac<NB,ES>::mac(nar-1,nar-1,nar+1);
    require(cancel_hi.bits==0 && cancel_hi.flags.sat_max && cancel_hi.flags.inexact,"intermediate overflow survives cancellation");
    auto cancel_lo=PositMac<NB,ES>::mac(1,1,mask);
    require(cancel_lo.bits==0 && cancel_lo.flags.sat_min && cancel_lo.flags.inexact,"intermediate underflow survives cancellation");
    require(PositMac<NB,ES>::mac(one,one,0).flags.bits()==0,"exact identity flags");
    std::cout<<"CORNERS NB="<<NB<<" ES="<<ES<<" PASS exact/approx RNE/TRUNC\n";
}
template<int ES> void sampled(uint64_t samples,uint64_t seed,bool acceptance) {
    std::mt19937_64 rng(seed);uint64_t lengths[3][2][32]{},signs[8]{},near=0,grid[256]{},density[6]{};
    for(uint64_t i=0;i<samples;++i) {
        uint64_t cell=i%4096,serial=i/4096;
        uint32_t a=stratified(rng,(cell/512)%8,cell&4,serial,ES);
        uint32_t b=stratified(rng,(cell/64)%8,cell&2,serial+43,ES);
        uint32_t c=stratified(rng,(cell/8)%8,cell&1,serial+71,ES);
        ++grid[(cell/512)*32+((cell/64)%8)*4+((cell&4)?2:0)+((cell&2)?1:0)];
        // 40% of blocks direct C at the opposite rounded product, including cancellation.
        if(serial%5<2) {
            uint32_t p=reference_mul<32,ES>(a,b,RoundMode::RNE);
            int64_t magnitude=int64_t((p>>31)?0u-p:p)+int64_t((i/8)%5)-2;
            magnitude=std::max<int64_t>(1,std::min<int64_t>(0x7fffffff,magnitude));
            c=(p>>31)?uint32_t(magnitude):0u-uint32_t(magnitude);
            if(std::abs(parse<32,ES>(p).sf-parse<32,ES>(c).sf)>4) c=0u-p;
        }
        auto product=parse<32,ES>(reference_mul<32,ES>(a,b,RoundMode::RNE)),uc=parse<32,ES>(c);
        near+=product.sign!=uc.sign && std::abs(product.sf-uc.sf)<=4;
        triple<32,ES>(a,b,c);
        ++signs[(a>>31)*4+(b>>31)*2+(c>>31)];
        uint32_t operands[]={a,b,c};
        for(unsigned j=0;j<3;++j) {uint32_t m=(operands[j]>>31)?0u-operands[j]:operands[j];
            bool rc=(m>>30)&1;unsigned run=0;
            for(int k=30;k>=0 && bool((m>>k)&1)==rc;--k) ++run;
            ++lengths[j][rc][run];}
        auto ua=parse<32,ES>(a);uint64_t f=ua.frac&0x7fffffffffffffffULL;
        unsigned pop=__builtin_popcountll(f);++density[pop<=2?pop:pop<=4?3:pop<=8?4:5];
        if((i+1)%1000000==0) std::cout<<"CHECKPOINT ES="<<ES<<" triples="<<i+1<<std::endl;
    }
    uint64_t minimum=UINT64_MAX;
    for(unsigned j=0;j<3;++j) for(unsigned rc=0;rc<2;++rc) for(unsigned r=1;r<=(rc?31:30);++r)
        minimum=std::min(minimum,lengths[j][rc][r]);
    for(auto n:signs) require(n>0,"missing sign combination");
    for(auto n:density) require(n>0,"missing fraction density");
    uint64_t grid_min=*std::min_element(std::begin(grid),std::end(grid));
    bool covered=!acceptance || (samples>=10000000 && minimum>=10000 && grid_min>=4000 && near*10>=samples*3);
    std::cout<<"P32 ES="<<ES<<" samples="<<samples<<" seed="<<seed<<" min_regime_per_operand="<<minimum
             <<" near_opposite="<<near<<" min_AB_grid="<<grid_min<<" coverage="<<(covered?"PASS":"FAIL")<<'\n';
    for(unsigned k=0;k<6;++k) std::cout<<"DENSITY ES="<<ES<<" bucket="<<k<<" operands="<<density[k]<<'\n';
    if(acceptance) {
        for(unsigned j=0;j<3;++j) for(unsigned rc=0;rc<2;++rc) for(unsigned r=1;r<=(rc?31:30);++r)
            if(lengths[j][rc][r]<10000) std::cout<<"LOW_COVER operand="<<j<<" rc="<<rc<<" run="<<r<<" count="<<lengths[j][rc][r]<<'\n';
        require(covered,"stratified acceptance coverage");
    }
}
void accumulator() {
    MacAccumulator<32,2> acc;std::mt19937_64 rng(314159);uint32_t state=0;uint64_t commits=0;
    for(unsigned i=0;i<10000;++i) {
        uint32_t a=rng(),b=rng(),c=rng();bool mode=i%3!=0,clear=mode && i%17==0;
        uint32_t effective=mode?(clear?0:state):c;
        auto r=acc.step(a,b,c,mode,clear);require(r.bits==soft_reference<32,2>(a,b,effective),"accumulator arithmetic");
        if(mode) {state=r.bits;++commits;}
        require(acc.value()==state && acc.commits()==commits,"single commit/state isolation");++checks;
    }
    constexpr uint32_t one=0x40000000,nar=0x80000000;
    acc.reset();require(acc.value()==0 && acc.commits()==0 && !acc.is_nar(),"reset");
    require(acc.step(one,one,nar,true,true).bits==one,"acc mode ignores external NaR");
    require(acc.step(nar,one,0,true,false).flags.bits()==16 && acc.is_nar(),"NaR poison");
    require(acc.step(0,one,0,true,false).bits==nar,"NaR persists");
    require(acc.step(one,one,0,true,true).bits==one && !acc.is_nar(),"clear removes NaR before MAC");
    auto before=acc.commits();bool rejected=false;
    try {acc.step(one,one,0,false,true);} catch(const std::invalid_argument&) {rejected=true;}
    require(rejected && acc.value()==one && acc.commits()==before,"invalid clear atomicity");
    MacConfig bad;bad.ops=2;rejected=false;
    try {acc.step(one,one,0,true,true,bad);} catch(const std::invalid_argument&) {rejected=true;}
    require(rejected && acc.value()==one && acc.commits()==before,"invalid config atomicity");
    std::cout<<"ACCUMULATOR 10000 transactions + directed state checks PASS\n";
}
int main(int argc,char** argv) {try {
    bool acceptance=false;uint64_t samples=100000,seed=314159;
    for(int i=1;i<argc;++i) {std::string a=argv[i];
        if(a=="--acceptance") acceptance=true;
        else if(a=="--samples" && i+1<argc) samples=std::stoull(argv[++i]);
        else if(a=="--seed" && i+1<argc) seed=std::stoull(argv[++i]);
        else throw std::invalid_argument("unknown argument");}
    corners<8,0>();corners<16,1>();corners<32,2>();corners<32,3>();accumulator();
    if(acceptance) {for(unsigned a=0;a<256;++a) for(unsigned b=0;b<256;++b) for(unsigned c=0;c<256;++c) triple<8,0>(a,b,c);
        std::cout<<"P8_EXHAUSTIVE triples=16777216 PASS\n";}
    sampled<2>(samples,seed,acceptance);sampled<3>(samples,seed,acceptance);
    std::cout<<"MAC_GATE1B "<<(acceptance?"ACCEPTANCE":"SMOKE")<<" PASS checks="<<checks<<" mismatches=0\n";
} catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}}
