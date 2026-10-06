#include <array>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include <vector>
#include "posit_adder.hpp"
#include "../l0/softposit_api.h"
using namespace l1;
uint64_t checks=0;
template<int NB,int ES> uint32_t soft_add(uint32_t a,uint32_t b) {
    if constexpr(NB==8) return l0_p8_add(uint8_t(a),uint8_t(b));
    if constexpr(NB==16) return l0_p16_add(uint16_t(a),uint16_t(b));
    if constexpr(NB==32 && ES==2) return l0_p32_add(a,b);
    return 0;
}
template<int NB,int ES> void check_pair(uint32_t a,uint32_t b) {
    auto got=l1_add<NB,ES>(a,b);auto expected=soft_add<NB,ES>(a,b);++checks;
    if(got!=expected) {
        std::cerr<<"MISMATCH NB="<<NB<<" ES="<<ES<<" a="<<std::hex<<a<<" b="<<b
                 <<" actual="<<uint32_t(got)<<" expected="<<expected<<std::dec<<'\n';
        throw std::runtime_error("SoftPosit mismatch");
    }
}
// Independent full-width signed-integer oracle, no alignment clamp or jamming.
template<int NB,int ES> uint32_t wide_reference(uint32_t a,uint32_t b,RoundMode mode) {
    constexpr int F=posit_constants<NB,ES>::FRAC_MAX,S=posit_constants<NB,ES>::SF_MAX;
    constexpr unsigned L=(2*S+F+2+63)/64;
    using Wide=std::array<uint64_t,L>;
    auto ua=parse<NB,ES>(a),ub=parse<NB,ES>(b);
    if(ua.is_nar || ub.is_nar) return uint32_t(1)<<(NB-1);
    auto expand=[](const posit_unpacked<NB,ES>& u) {
        Wide w{};if(u.is_zero) return w;
        uint64_t sig=u.frac>>(63-F);unsigned shift=unsigned(u.sf+S),word=shift/64,bit=shift%64;
        w[word]=sig<<bit;if(bit && word+1<L) w[word+1]=sig>>(64-bit);return w;
    };
    Wide x=expand(ua),y=expand(ub),z{};
    bool negative=ua.sign;
    int cmp=0;for(int i=int(L)-1;i>=0;--i) if(x[i]!=y[i]) {cmp=x[i]>y[i]?1:-1;break;}
    if(ua.sign==ub.sign) {
        uint64_t carry=0;
        for(unsigned i=0;i<L;++i) {unsigned __int128 s=static_cast<unsigned __int128>(x[i])+y[i]+carry;z[i]=uint64_t(s);carry=uint64_t(s>>64);}
    } else {
        if(cmp<0) {std::swap(x,y);negative=ub.sign;}
        uint64_t borrow=0;
        for(unsigned i=0;i<L;++i) {unsigned __int128 sub=static_cast<unsigned __int128>(y[i])+borrow;z[i]=x[i]-uint64_t(sub);borrow=static_cast<unsigned __int128>(x[i])<sub;}
    }
    int top=int(L*64)-1;
    auto bit=[&](int i) {return i>=0 && ((z[unsigned(i)/64]>>(unsigned(i)%64))&1)!=0;};
    while(top>=0 && !bit(top)) --top;
    if(top<0) return 0;
    uint64_t frac=0;for(int j=0;j<64;++j) if(bit(top-j)) frac|=uint64_t(1)<<(63-j);
    bool tail=false;for(int j=0;j<top-63;++j) tail|=bit(j);
    posit_unpacked<NB,ES> u{negative,false,false,top-S-F,frac,!tail};
    return pack<NB,ES>(u,mode);
}
template<int NB,int ES> void corners() {
    constexpr uint32_t nar=uint32_t(1)<<(NB-1),mask=uint32_t((uint64_t(1)<<NB)-1),one=uint32_t(1)<<(NB-2);
    const uint32_t values[]={0,nar,1,2,3,nar-1,nar-2,nar+1,nar+2,mask,mask-1,one,one-1,one+1,(-one)&mask};
    uint64_t clamp=0,carry=0,zero=0,deep=0;
    for(auto a:values) for(auto b:values) {
        if constexpr(ES!=3) check_pair<NB,ES>(a,b);
        for(auto mode:{RoundMode::RNE,RoundMode::TRUNC}) {
            AdderTrace t;auto result=l1_add<NB,ES>(a,b,mode,&t);++checks;
            if(result!=wide_reference<NB,ES>(a,b,mode)) throw std::runtime_error("corner wide oracle");
            clamp+=t.clamped;carry+=t.carry;zero+=t.cancellation_zero;deep+=t.left_shift>3;
        }
    }
    if(!clamp || !carry || !zero || !deep) throw std::runtime_error("corner coverage");
    constexpr int F=posit_constants<NB,ES>::FRAC_MAX,S=posit_constants<NB,ES>::SF_MAX;
    posit_unpacked<NB,ES> u{false,false,false,-F-1,uint64_t(1)<<63,true};
    auto half=pack<NB,ES>(u);AdderTrace tie;
    if(l1_add<NB,ES>(one,half,RoundMode::RNE,&tie)!=one || !tie.guard || tie.round || tie.sticky ||
       l1_add<NB,ES>(one+1,half)!=one+2)
        throw std::runtime_error("directed ties-to-even");
    checks+=2;
    for(int d=F+1;d<=F+3;++d) for(bool minus:{false,true}) {
        u.sf=std::max(0,F+3-S);auto a=pack<NB,ES>(u);
        u.sf-=d;u.sign=minus;auto b=pack<NB,ES>(u);u.sign=false;
        AdderTrace t;auto actual=l1_add<NB,ES>(a,b,RoundMode::RNE,&t);++checks;
        if(actual!=wide_reference<NB,ES>(a,b,RoundMode::RNE) || t.alignment_shift>F+2 ||
           t.clamped!=(t.delta_sf>F+2)) throw std::runtime_error("alignment boundary / sign");
    }
    std::cout<<"CORNERS NB="<<NB<<" ES="<<ES<<" PASS clamp="<<clamp<<" carry="<<carry
             <<" cancellation="<<zero<<" deep="<<deep<<'\n';
}
uint32_t stratified(std::mt19937_64& rng,unsigned group,bool negative,uint64_t serial,unsigned es) {
    constexpr unsigned lo[]={1,4,8,12,16,18,23,28},hi[]={3,7,11,15,17,22,27,31};
    bool rc=serial&1;unsigned end=std::min(hi[group],rc?31u:30u);
    unsigned run=lo[group]+unsigned((serial/2)%(end-lo[group]+1));uint32_t mag=0;
    for(int i=30;i>30-int(run);--i) if(rc) mag|=uint32_t(1)<<i;
    unsigned left=31-run;if(left) {if(!rc) mag|=uint32_t(1)<<(left-1);--left;}
    unsigned eb=std::min(es,left),fb=left-eb;
    uint32_t mask=fb?(uint32_t(1)<<fb)-1:0,f=uint32_t(rng())&mask;
    switch((serial/8)%6) {
        case 0:f=0;break;case 1:f=mask;break;case 2:f=0xaaaaaaaa&mask;break;
        case 3:f=0x55555555&mask;break;case 4:f=fb?uint32_t(1)<<(rng()%fb):0;break;default:break;
    }
    mag|=((uint32_t(rng())&((uint32_t(1)<<eb)-1))<<fb)|f;
    return negative?0u-mag:mag;
}
template<int ES> void sampled32(uint64_t samples,uint64_t seed,bool acceptance) {
    std::mt19937_64 rng(seed);uint64_t near=0,clamped=0,left15=0,cancel=0,carry=0;
    uint64_t lengths[2][32]{},signs[4]{},density[6]{},delta[5]{};
    constexpr unsigned F=posit_constants<32,ES>::FRAC_MAX;
    for(uint64_t i=0;i<samples;++i) {
        uint32_t a,b;
        if(i%10<4) {
            uint32_t ma=uint32_t(rng()&0x7fffffff);if(!ma) ma=1;
            int64_t mb=int64_t(ma)+(i&1?1:-1)*int64_t((rng()&31)+1);
            mb=std::max<int64_t>(1,std::min<int64_t>(0x7fffffff,mb));
            bool neg=(i/10)&1;a=neg?0u-ma:ma;b=neg?uint32_t(mb):0u-uint32_t(mb);
            auto u=parse<32,ES>(a),v=parse<32,ES>(b);
            if(std::abs(u.sf-v.sf)>4) b=0u-a;
        } else {
            uint64_t j=(i/10)*6+(i%10-4),cell=j%256,serial=j/256;
            a=stratified(rng,unsigned(cell/32),bool(cell&2),serial,ES);
            b=stratified(rng,unsigned((cell/4)%8),bool(cell&1),serial+(serial/64)%4,ES);
        }
        auto ua=parse<32,ES>(a),ub=parse<32,ES>(b);
        int d=std::abs(ua.sf-ub.sf);bool opposite=ua.sign!=ub.sign;
        near+=opposite && d<=4;++signs[unsigned(ua.sign)*2+ub.sign];
        ++delta[d==0?0:d==1?1:d<=7?2:d<=int(F)?3:4];
        for(uint32_t p:{a,b}) {
            uint32_t mag=(p>>31)?0u-p:p;bool rc=(mag>>30)&1;unsigned m=0;
            for(int k=30;k>=0 && bool((mag>>k)&1)==rc;--k) ++m;
            ++lengths[rc][m];unsigned fb=unsigned(std::max(0,30-int(m)-ES));
            uint32_t f=mag&(fb?(uint32_t(1)<<fb)-1:0);unsigned pop=0;
            for(;f;f&=f-1) ++pop;
            ++density[pop<=2?pop:pop<=4?3:pop<=8?4:5];
        }
        AdderTrace t;auto actual=l1_add<32,ES>(a,b,RoundMode::RNE,&t);++checks;
        auto expected=ES==2?soft_add<32,2>(a,b):wide_reference<32,ES>(a,b,RoundMode::RNE);
        if(actual!=expected) {
            std::cerr<<"P32_FAIL ES="<<ES<<" a="<<std::hex<<a<<" b="<<b<<" got="<<actual<<" expected="<<expected<<std::dec<<'\n';
            throw std::runtime_error("p32 sampled mismatch");
        }
        clamped+=t.clamped;left15+=t.left_shift>15;cancel+=t.cancellation_zero;carry+=t.carry;
    }
    uint64_t minimum=UINT64_MAX;
    for(unsigned rc=0;rc<2;++rc) for(unsigned m=1;m<=(rc?31:30);++m) {
        minimum=std::min(minimum,lengths[rc][m]);
        std::cout<<"REGIME ES="<<ES<<" rc="<<rc<<" m="<<m<<" operands="<<lengths[rc][m]<<'\n';
    }
    bool covered=near*10>=samples*3 && clamped && left15 && cancel && carry;
    for(auto n:signs) covered&=n!=0;
    for(auto n:density) covered&=n!=0;
    for(auto n:delta) covered&=n!=0;
    if(acceptance) covered&=samples>=10000000 && minimum>=10000;
    std::cout<<"P32 ES="<<ES<<" samples="<<samples<<" seed="<<seed<<" near_opposite="<<near
             <<" clamped="<<clamped<<" lzc_gt15="<<left15<<" cancellation="<<cancel<<" carry="<<carry
             <<" min_regime_operands="<<minimum<<" coverage="<<(covered?"PASS":"FAIL")<<'\n';
    for(unsigned k=0;k<6;++k) std::cout<<"DENSITY ES="<<ES<<" bucket="<<k<<" operands="<<density[k]<<'\n';
    for(unsigned k=0;k<4;++k) std::cout<<"SIGN ES="<<ES<<" bucket="<<k<<" pairs="<<signs[k]<<'\n';
    for(unsigned k=0;k<5;++k) std::cout<<"DELTA ES="<<ES<<" bucket="<<k<<" pairs="<<delta[k]<<'\n';
    if(!covered) throw std::runtime_error("sampled coverage");
}
void p16_range(unsigned begin,unsigned end) {
    std::array<posit_unpacked<16,1>,65536> decoded;
    for(unsigned a=0;a<65536;++a) decoded[a]=parse<16,1>(uint16_t(a));
    auto start=std::chrono::steady_clock::now();uint64_t pairs=0;
    for(unsigned a=begin;a<end;++a) {
        for(unsigned b=0;b<65536;++b) {
            auto actual=pack<16,1>(l1_add_unpacked<16,1>(decoded[a],decoded[b]));
            auto expected=l0_p16_add(uint16_t(a),uint16_t(b));++pairs;
            if(actual!=expected) {
                std::cerr<<"P16_FAIL a="<<a<<" b="<<b<<" got="<<actual<<" expected="<<expected<<'\n';
                throw std::runtime_error("p16 exhaustive mismatch");
            }
        }
        if((a+1)%256==0 || a+1==end) std::cout<<"CHECKPOINT next_A="<<a+1<<" pairs="<<pairs
            <<" elapsed="<<std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count()<<std::endl;
    }
    checks+=pairs;std::cout<<"P16_EXHAUSTIVE PASS range=["<<begin<<','<<end<<") pairs="<<pairs
                         <<" predecoded=65536 (same add_unpacked+pack core)\n";
}
uint64_t number(const std::string& s) {
    if(s.empty() || s.find_first_not_of("0123456789")!=std::string::npos) throw std::invalid_argument("unsigned decimal required");
    return std::stoull(s);
}
int main(int argc,char**argv) try {
    uint64_t samples=1000000,seed=314159;bool acceptance=false,range=false;
    unsigned begin=0,end=65536;
    for(int i=1;i<argc;++i) {
        std::string arg=argv[i];if(arg=="--acceptance") {acceptance=true;continue;}
        if(i+1==argc) throw std::invalid_argument("missing value");
        auto v=number(argv[++i]);
        if(arg=="--samples") samples=v;else if(arg=="--seed") seed=v;
        else if(arg=="--p16-start" || arg=="--p16-end") {
            if(v>65536) throw std::invalid_argument("p16 bound");
            range=true;
            if(arg=="--p16-start") begin=unsigned(v);else end=unsigned(v);
        } else throw std::invalid_argument("unknown option");
    }
    if(!samples || begin>=end || (acceptance && samples<10000000)) throw std::invalid_argument("insufficient/invalid samples or range");
    for(unsigned a=0;a<256;++a) for(unsigned b=0;b<256;++b) check_pair<8,0>(a,b);
    corners<8,0>();corners<16,1>();corners<32,2>();corners<32,3>();
    std::mt19937_64 rng(seed);
    for(unsigned j=0;j<1000000;++j) check_pair<16,1>(uint16_t(rng()),uint16_t(rng()));
    for(unsigned j=0;j<100000;++j) {
        uint32_t a=uint32_t(rng()),b=uint32_t(rng());
        for(auto mode:{RoundMode::RNE,RoundMode::TRUNC}) {
            ++checks;if(l1_add<32,2>(a,b,mode)!=wide_reference<32,2>(a,b,mode)) throw std::runtime_error("p32 wide RNE/TRUNC");
            ++checks;if(l1_add<32,3>(a,b,mode)!=wide_reference<32,3>(a,b,mode)) throw std::runtime_error("es3 wide RNE/TRUNC");
        }
    }
    sampled32<2>(samples,seed,acceptance);sampled32<3>(samples,seed+1,acceptance);
    if(acceptance || range) p16_range(begin,end);
    std::cout<<(acceptance && begin==0 && end==65536?"WEEK5_ADDER_ACCEPTANCE PASS":"SELECTED_ADDER_TESTS PASS")
             <<" checks="<<checks<<" (ES3 uses wide integer oracle, not SoftPosit)\n";
    return 0;
} catch(const std::invalid_argument& e) {std::cerr<<e.what()<<'\n';return 2;}
  catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}
