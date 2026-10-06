#pragma once
#include <array>
#include <random>
#include <algorithm>
#include "posit_mac.hpp"
using namespace l1;
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
