#pragma once
#include <algorithm>
#include <cstdint>
#include <utility>
#include <vector>
// Independent integer/bit-list ES3 oracle, shared from the verified generator.
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
