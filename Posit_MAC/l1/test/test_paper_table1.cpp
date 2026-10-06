#include <array>
#include <cfenv>
#include <chrono>
#include <cmath>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <limits>
#include <random>
#include <string>
#include "paper_multiplier.hpp"
#include "paper_measurement.hpp"
using namespace l1;
uint64_t number(const std::string& s) {
    if(s.empty() || s.find_first_not_of("0123456789")!=std::string::npos)
        throw std::invalid_argument("unsigned decimal argument required");
    return std::stoull(s);
}
int main(int argc,char**argv) try {
    uint64_t samples=200000000,seed=314159;
    bool bits_distribution=false,require_match=false;
    bool relative_profile=false,source_profile=false;
    for(int i=1;i<argc;++i) {
        std::string arg=argv[i];
        if(arg=="--require-match") {require_match=true;continue;}
        if(i+1>=argc) throw std::invalid_argument("missing argument");
        std::string val=argv[++i];
        if(arg=="--samples") samples=number(val);
        else if(arg=="--seed") seed=number(val);
        else if(arg=="--profile" && (val=="baseline" || val=="relative" || val=="source")) {relative_profile=val=="relative";source_profile=val=="source";}
        else if(arg=="--distribution" && (val=="uniform-value" || val=="uniform-bits"))
            bits_distribution=val=="uniform-bits";
        else throw std::invalid_argument("unknown argument/value");
    }
    if(!samples || (require_match && samples<200000000))
        throw std::invalid_argument("zero/insufficient acceptance samples");
    paper_init_fp32_rne();
    const uint32_t oracle_cases[][3]={
        {0x3fc00000,0x3f800001,0x3fc00002}, // halfway -> even, upward
        {0x3fc00000,0x3f800003,0x3fc00004}, // halfway -> even, downward
        {0x3f800001,0x3f800001,0x3f800002},
        {0x00800000,0x3f000000,0x00400000}, // normal -> subnormal
        {0x00000001,0x3f000000,0x00000000}, // half minsub -> even zero
        {0x00000001,0x3f400000,0x00000001},
        {0x00000000,0x3f800000,0x00000000},
        {0xbf800000,0x3f800000,0xbf800000}
    };
    for(const auto& c:oracle_cases)
        if(float_bits(fp32_oracle(from_bits(c[0]),from_bits(c[1])))!=c[2])
            throw std::runtime_error("FP32 oracle directed test failed");
    std::mt19937_64 conversion_rng(20261004);
    for(unsigned i=0;i<100000;++i) {
        float x=std::ldexp(float(conversion_rng()&0xffffff),-24);
        if(value(encode(x))!=static_cast<long double>(x))
            throw std::runtime_error("uniform-value FP32 -> posit conversion identity");
        if(x!=0) {
            auto prepared=paper_prepare_fp32(float_bits(x));
            auto posit=parse<32,3>(encode(x));
            if(prepared.classification!=PaperFp32Class::Normal ||
               ((posit.frac>>51)&4095)!=prepared.fraction12)
                throw std::runtime_error("FP32 cut11 / posit fraction12 mismatch");
        }
    }
    std::cout<<"FP32 oracle ties/subnormal/zero/sign: 8 PASS; conversion identity/cut11: 100000 PASS seed=20261004\n";
    const unsigned denominators[4]={1000,200,100,20};
    const double proposed[3][4]={{9.87,32.19,50.03,95.57},{44.69,83.17,95.05,99.99},{87.09,99.79,99.99,99.99}};
    const double kim[3][4]={{9.30,32.12,50.01,95.58},{43.94,83.01,95.03,100},{86.69,99.81,100,100}};
    uint64_t count[4][3][4]={},steps[4][3]={},swaps[4]={};
    const char* profiles[]={"baseline","minpop","relative","source"};
    const unsigned variants=source_profile?4:relative_profile?3:2;
    PaperCounters counters;
    PaperFingerprint fingerprint;
    PaperGenerator generator(seed,bits_distribution?PaperDistribution::UniformBits:PaperDistribution::UniformValue);
    std::cout<<"NB=32 ES=3 FRAC_W=12 n=2..4 complement=ones per-term=FLOOR pack=TRUNC\n"
             <<"samples/row="<<samples<<" seed="<<seed<<" distribution="
             <<(bits_distribution?"uniform-bits":"uniform-value")
             <<" oracle=FP32_RNE ops=PredictN2_7bit_vs_MinPopcount_12bit\n"
             <<"ASSUMPTIONS: generator/seed/tie-A/predictor reconstruction/accumulator are local; not published source RTL.\n"
             <<"Reject input zero, converted regime m>15 and FP32 Ideal=0; N counts accepted pairs.\n";
    std::cout<<"acceptance_profile="<<(source_profile?"source":relative_profile?"relative":"baseline")<<'\n';
    auto start=std::chrono::steady_clock::now();
    uint64_t accepted=0;
    while(accepted<samples) {
        uint32_t raw_a=generator.next_bits(),raw_b=generator.next_bits();
        auto pair=paper_evaluate_pair(raw_a,raw_b);
        counters.record(pair.reason);
        fingerprint.add(raw_a);fingerprint.add(raw_b);
        fingerprint.add(uint32_t(pair.reason));fingerprint.add(pair.ideal_bits);
        if(pair.reason!=PaperReject::Accepted) continue;
        uint32_t a=pair.posit_a,b=pair.posit_b;
        for(unsigned variant=0;variant<variants;++variant) {
            PaperConfig cfg;cfg.ops=variant==2?PaperOps::PredictN2Relative:(variant?PaperOps::MinPopcount:PaperOps::PredictN2);
            if(variant==3) cfg=paper_source_config();
            for(unsigned row=0;row<3;++row) {
                cfg.n=row+2;
                auto result=PaperMultiplier<>::mul(a,b,cfg);
                auto err=paper_error_fraction(result.bits,pair.ideal_bits);
                for(unsigned j=0;j<4;++j) if(err.below(denominators[j])) ++count[variant][row][j];
                steps[variant][row]+=result.iterations;
                if(row==0) swaps[variant]+=result.swapped;
            }
        }
        ++accepted;
        if(accepted%10000000==0) std::cout<<"CHECKPOINT accepted="<<accepted<<std::endl;
    }
    double maximum=0;
    std::cout<<std::fixed<<std::setprecision(6)
             <<"profile,n,Err<0.1%,Err<0.5%,Err<1%,Err<5%,avg_steps,max_delta_Proposed_pp,max_delta_Kim_pp\n";
    for(unsigned variant=0;variant<variants;++variant)
    for(unsigned row=0;row<3;++row) {
        std::cout<<profiles[variant]<<','<<row+2;
        double delta=0,delta_kim=0;
        for(unsigned j=0;j<4;++j) {
            double pct=100.*double(count[variant][row][j])/samples;
            std::cout<<','<<pct;
            delta=std::max(delta,std::fabs(pct-proposed[row][j]));
            delta_kim=std::max(delta_kim,std::fabs(pct-kim[row][j]));
        }
        if(variant==(source_profile?3u:relative_profile?2u:0u)) maximum=std::max(maximum,delta);
        std::cout<<','<<double(steps[variant][row])/samples<<','<<delta<<','<<delta_kim<<'\n';
    }
    if(!counters.consistent() || counters.accepted!=samples) throw std::runtime_error("counter invariant");
    std::cout<<"accepted="<<accepted<<" attempted="<<counters.attempted<<" excluded_zero="<<counters.input_zero
             <<" excluded_m="<<counters.regime<<" excluded_zero_ideal="<<counters.ideal_zero
             <<" excluded_invalid="<<counters.invalid_input<<" excluded_nonfinite="<<counters.nonfinite_ideal
             <<" generator_draws="<<generator.draws
             <<" baseline_swaps="<<swaps[0]<<" minpop_swaps="<<swaps[1]<<'\n';
    std::cout<<"pair_fingerprint_fnv1a64="<<std::hex<<fingerprint.hash<<std::dec<<'\n';
    if(relative_profile || source_profile) std::cout<<"relative_swaps="<<swaps[2]<<'\n';
    if(source_profile) std::cout<<"source_swaps="<<swaps[3]<<" source_ops=absolute_prefix_Q12 anchor=first guard=12 source_width_unconfirmed=1\n";
    bool matched=maximum<=1. && samples>=200000000;
    std::cout<<"Table_I_numeric_acceptance="<<(matched?"PASS":"NOT_REPRODUCED")
             <<" max_delta_pp="<<maximum<<" elapsed_seconds="
             <<std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count()<<'\n';
    return require_match && !matched?1:0;
} catch(const std::exception&e) {std::cerr<<e.what()<<'\n';return 2;}
