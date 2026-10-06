#include "paper_babic.hpp"
#include "paper_measurement.hpp"
#include <chrono>
#include <iomanip>
#include <iostream>
using namespace l1;
bool below(uint32_t a,uint32_t ideal,unsigned d) {
    int delta=int(a>>23)-int(ideal>>23);
    if(delta<=-2 || delta>=2) return false;
    uint64_t x=(a&0x7fffff)|0x800000,y=(ideal&0x7fffff)|0x800000;
    if(delta>=0) x<<=delta;else y<<=-delta;
    return (x>y?x-y:y-x)*d<y;
}
uint64_t number(const char*s) {
    std::string value(s);
    if(value.empty() || value.find_first_not_of("0123456789")!=std::string::npos) throw std::invalid_argument("unsigned decimal required");
    return std::stoull(value);
}
int main(int argc,char**argv) try {
    uint64_t samples=argc>1?number(argv[1]):1000000,seed=argc>2?number(argv[2]):314159;
    if(!samples || argc>3) throw std::invalid_argument("samples seed");
    paper_init_fp32_rne();uint64_t checks=0;double ae[4]={};
    for(unsigned a=1;a<256;++a) for(unsigned b=1;b<256;++b) for(unsigned n=1;n<=4;++n) {
        auto result=paper_babic_product(a,b,n);
        if(result.product+result.remainder!=a*b) throw std::runtime_error("integer residual identity");
        ae[n-1]+=100.*result.remainder/(a*b);++checks;
    }
    std::cout<<"INTEGER_8BIT PASS checks="<<checks<<" AE_percent="<<std::fixed<<std::setprecision(4);
    for(double x:ae) std::cout<<x/65025<<',';
    std::cout<<"\nLOCAL_FP32_EXTENSION input_fraction=23 input_cut=none output=FP32_RNE; not published source code\n";
    const unsigned den[]={1000,200,100,20};
    const double ref[3][4]={{19.14,47.37,65.13,99.13},{70.52,95.52,99.43,100},{98.03,100,100,100}};
    uint64_t counts[3][4]={};PaperGenerator gen(seed,PaperDistribution::UniformValue);PaperCounters counters;PaperFingerprint hash;
    auto start=std::chrono::steady_clock::now();
    while(counters.accepted<samples) {
        auto a=gen.next_bits(),b=gen.next_bits();auto pair=paper_evaluate_pair(a,b);
        counters.record(pair.reason);hash.add(a);hash.add(b);hash.add(uint32_t(pair.reason));hash.add(pair.ideal_bits);
        if(pair.reason!=PaperReject::Accepted) continue;
        uint32_t ma=(a&0x7fffff)|0x800000,mb=(b&0x7fffff)|0x800000;
        for(unsigned row=0;row<3;++row) {
            auto result=paper_babic_product(ma,mb,row+2);
            if(result.product+result.remainder!=uint64_t(ma)*mb) throw std::runtime_error("FP32 mantissa residual identity");
            // Integer partial product <=48 bits converts to binary64 exactly.
            double exact=std::ldexp(double(result.product),int(a>>23)+int(b>>23)-254-46);
            volatile float output=float(exact);
            for(unsigned t=0;t<4;++t) counts[row][t]+=below(float_bits(output),pair.ideal_bits,den[t]);
        }
        if(counters.accepted%10000000==0) std::cout<<"CHECKPOINT accepted="<<counters.accepted<<std::endl;
    }
    double gap=0;
    std::cout<<"n,threshold_percent,count,percent,delta_Babic_pp\n"<<std::setprecision(6);
    for(unsigned row=0;row<3;++row) for(unsigned t=0;t<4;++t) {
        double pct=100.*counts[row][t]/samples;
        gap=std::max(gap,std::fabs(pct-ref[row][t]));
        std::cout<<row+2<<','<<100./den[t]<<','<<counts[row][t]<<','<<pct<<','<<pct-ref[row][t]<<'\n';
    }
    std::cout<<"samples="<<samples<<" seed="<<seed<<" attempted="<<counters.attempted<<" zero="<<counters.input_zero
             <<" draws="<<gen.draws<<" fingerprint="<<std::hex<<hash.hash<<std::dec
             <<" max_delta_pp="<<gap<<" numeric_acceptance="<<(samples>=200000000 && gap<=1?"PASS":"NOT_REPRODUCED")
             <<" elapsed="<<std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count()<<'\n';
    return samples>=200000000 && gap>1?1:0;
} catch(const std::exception&e) {std::cerr<<e.what()<<'\n';return 2;}
