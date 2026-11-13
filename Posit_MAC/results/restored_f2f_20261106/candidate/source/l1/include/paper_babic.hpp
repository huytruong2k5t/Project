#pragma once
#include <cstdint>
#include <stdexcept>
namespace l1 {
struct BabicProduct {uint64_t product,remainder;unsigned stages;};
// Integer recurrence from Babic2010 Eq.(7)-(15), separate from Kim/Posit core.
inline BabicProduct paper_babic_product(uint32_t a,uint32_t b,unsigned n) {
    if(!n || n>24 || a>0xffffff || b>0xffffff) throw std::invalid_argument("Babic integer domain");
    uint64_t acc=0;unsigned used=0;
    while(a && b && used<n) {
        uint32_t ha=1,hb=1;
        while((ha<<1)<=a) ha<<=1;
        while((hb<<1)<=b) hb<<=1;
        uint32_t ra=a-ha,rb=b-hb;
        acc+=uint64_t(ha)*hb+uint64_t(ra)*hb+uint64_t(rb)*ha;
        a=ra;b=rb;++used;
    }
    return {acc,uint64_t(a)*b,used};
}
}
