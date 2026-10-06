// Experimental one-factor-at-a-time study. No production configuration changed.
#include <chrono>
#include <iomanip>
#include <iostream>
#include <string>
#include "paper_multiplier.hpp"
#include "paper_measurement.hpp"
using namespace l1;
enum class Profile { Baseline, TieB, RelativePrediction, ExactPredictionResidual,
                     Guard12, ExactSacResidual, PackRne };
const char* names[]={"baseline","tie_b","relative_prediction","exact_prediction_residual",
                     "acc_guard12","exact_sac_residual","pack_rne"};
unsigned prediction_exact(unsigned f) {
    // Independent two-term nearest-power approximation without one's complement.
    unsigned m=128+f;
    int first=m>=192?256:128;
    int residue=int(m)-first;
    unsigned magnitude=unsigned(residue<0?-residue:residue),power=1;
    if(!magnitude) return 0;
    while((power<<1)<=magnitude) power<<=1;
    if(2*magnitude>=3*power) power<<=1;
    int approximation=first+(residue<0?-int(power):int(power));
    int error=int(m)-approximation;
    return unsigned(error<0?-error:error);
}
uint32_t experimental(uint32_t a,uint32_t b,unsigned n,Profile profile) {
    auto ua=parse<32,3>(a),ub=parse<32,3>(b);
    uint64_t x=ua.frac>>51,y=ub.frac>>51;
    unsigned ia=unsigned((x-4096)>>5),ib=unsigned((y-4096)>>5);
    unsigned ea=paper_prediction_lut()[ia],eb=paper_prediction_lut()[ib];
    bool swap=eb<ea;
    if(profile==Profile::TieB) swap=eb<=ea;
    if(profile==Profile::RelativePrediction) swap=eb*(128+ia)<ea*(128+ib);
    if(profile==Profile::ExactPredictionResidual) swap=prediction_exact(ib)<prediction_exact(ia);
    if(swap) std::swap(x,y);
    unsigned guard=profile==Profile::Guard12?12:0;
    PaperSac sac(x,12,profile!=Profile::ExactSacResidual);
    int64_t acc=0;
    for(unsigned j=0;j<n && sac.mantissa;++j) {
        bool up=sac.mantissa>=6144;
        int shift=sac.exponent+int(up)+int(guard);
        uint64_t term=shift>=0?y<<shift:(-shift>=64?0:y>>(-shift));
        acc+=sac.coefficient*int64_t(term);
        sac.advance(up);
    }
    if(acc<=0) throw std::runtime_error("nonpositive experimental result");
    uint64_t hidden=uint64_t(4096)<<guard;
    int sf=ua.sf+ub.sf;bool sticky=false;
    while(uint64_t(acc)>=2*hidden) {sticky|=acc&1;acc>>=1;++sf;}
    while(uint64_t(acc)<hidden) {acc<<=1;--sf;}
    posit_unpacked<32,3> u{false,false,false,sf,uint64_t(acc)<<(51-guard),!sticky};
    return pack<32,3>(u,profile==Profile::PackRne?RoundMode::RNE:RoundMode::TRUNC);
}
uint64_t number(const std::string& s) {
    if(s.empty() || s.find_first_not_of("0123456789")!=std::string::npos)
        throw std::invalid_argument("unsigned decimal required");
    return std::stoull(s);
}
int main(int argc,char**argv) try {
    uint64_t samples=10000000,seed=314159;
    bool self_test=false;
    int selected=-1;
    for(int i=1;i<argc;++i) {
        std::string key=argv[i];
        if(key=="--self-test") {self_test=true;continue;}
        if(i+1==argc) throw std::invalid_argument("missing value");
        if(key=="--profile") {
            std::string name=argv[++i];
            for(unsigned v=0;v<7;++v) if(name==names[v]) selected=int(v);
            if(selected<0) throw std::invalid_argument("unknown profile");
            continue;
        }
        auto v=number(argv[++i]);
        if(key=="--samples") samples=v;
        else if(key=="--seed") seed=v;
        else throw std::invalid_argument("unknown argument");
    }
    if(!samples) throw std::invalid_argument("samples must be positive");
    paper_init_fp32_rne();
    if(self_test) {
        uint64_t checks=0;PaperGenerator generator(20261004,PaperDistribution::UniformValue);
        for(unsigned j=0;j<100000;++j) {
            auto a=generator.next_bits(),b=generator.next_bits();
            auto p=paper_evaluate_pair(a,b);if(p.reason!=PaperReject::Accepted) continue;
            for(unsigned n=2;n<=4;++n) {
                PaperConfig cfg;cfg.n=n;
                auto baseline=PaperMultiplier<>::mul(p.posit_a,p.posit_b,cfg).bits;
                if(experimental(p.posit_a,p.posit_b,n,Profile::Baseline)!=baseline)
                    throw std::runtime_error("baseline differential");
                ++checks;
                auto sel=paper_ops_select((parse<32,3>(p.posit_a).frac>>51)&4095,
                                          (parse<32,3>(p.posit_b).frac>>51)&4095);
                auto tie=experimental(p.posit_a,p.posit_b,n,Profile::TieB);
                auto reversed=PaperMultiplier<>::mul(p.posit_b,p.posit_a,cfg).bits;
                if(tie!=(sel.tie?reversed:baseline)) throw std::runtime_error("tie override");
                ++checks;
                cfg.complement=false;
                if(experimental(p.posit_a,p.posit_b,n,Profile::ExactSacResidual)!=
                   PaperMultiplier<>::mul(p.posit_a,p.posit_b,cfg).bits)
                    throw std::runtime_error("SAC residual differential");
                ++checks;
                cfg.complement=true;cfg.rounding=RoundMode::RNE;
                if(experimental(p.posit_a,p.posit_b,n,Profile::PackRne)!=
                   PaperMultiplier<>::mul(p.posit_a,p.posit_b,cfg).bits)
                    throw std::runtime_error("pack rounding differential");
                ++checks;
                // Guard accumulation checked against exact dyadic long-double sum.
                auto ua=parse<32,3>(p.posit_a),ub=parse<32,3>(p.posit_b);
                uint64_t x=ua.frac>>51,y=ub.frac>>51;if(sel.swapped) std::swap(x,y);
                PaperSac sac(x,12);long double sum=0;
                for(unsigned k=0;k<n && sac.mantissa;++k) {
                    bool up=sac.mantissa>=6144;
                    long double term=std::ldexp(static_cast<long double>(y),12+sac.exponent+int(up));
                    sum+=sac.coefficient*std::floor(term);
                    sac.advance(up);
                }
                // Independent Q24 per-term FLOOR oracle; SAC remains Q12.
                auto bits=experimental(p.posit_a,p.posit_b,n,Profile::Guard12);
                long double exact=std::ldexp(sum,ua.sf+ub.sf-24);
                int exponent=0;long double mantissa=std::frexp(exact,&exponent)*2;
                posit_unpacked<32,3> reference{false,false,false,exponent-1,
                    uint64_t(std::floor(std::ldexp(mantissa,24)))<<39,true};
                if(bits!=pack<32,3>(reference,RoundMode::TRUNC))
                    throw std::runtime_error("guard exact dyadic oracle");
                ++checks;
            }
        }
        for(unsigned f=0;f<128;++f) {
            PaperSac sac(128+f,7,false);int approximation=0;
            for(unsigned j=0;j<2 && sac.mantissa;++j) {
                bool up=sac.mantissa>=192;
                approximation+=sac.coefficient*(1<<(7+sac.exponent+int(up)));sac.advance(up);
            }
            if(prediction_exact(f)!=unsigned(std::abs(int(128+f)-approximation)))
                throw std::runtime_error("exact predictor oracle");
            ++checks;
        }
        std::cout<<"SELF_TEST PASS checks="<<checks<<" seed=20261004\n";return 0;
    }
    const unsigned den[]={1000,200,100,20};
    const double proposed[3][4]={{9.87,32.19,50.03,95.57},{44.69,83.17,95.05,99.99},{87.09,99.79,99.99,99.99}};
    uint64_t counts[7][3][4]={},changed[7][3]={},ties=0;
    int64_t paired[7][3][4]={};uint64_t discordant[7][3][4]={};
    PaperGenerator gen(seed,PaperDistribution::UniformValue);PaperCounters counters;PaperFingerprint fingerprint;
    auto start=std::chrono::steady_clock::now();
    while(counters.accepted<samples) {
        auto a=gen.next_bits(),b=gen.next_bits();auto p=paper_evaluate_pair(a,b);
        counters.record(p.reason);fingerprint.add(a);fingerprint.add(b);
        fingerprint.add(uint32_t(p.reason));fingerprint.add(p.ideal_bits);
        if(p.reason!=PaperReject::Accepted) continue;
        auto ua=parse<32,3>(p.posit_a),ub=parse<32,3>(p.posit_b);
        ties+=paper_ops_select((ua.frac>>51)&4095,(ub.frac>>51)&4095).tie;
        for(unsigned row=0;row<3;++row) {
            uint32_t baseline=0;bool base_ok[4]={};
            for(unsigned profile=0;profile<7;++profile) {
                if(selected>=0 && profile && int(profile)!=selected) continue;
                auto result=experimental(p.posit_a,p.posit_b,row+2,Profile(profile));
                if(!profile) baseline=result;
                changed[profile][row]+=result!=baseline;
                auto err=paper_error_fraction(result,p.ideal_bits);
                for(unsigned j=0;j<4;++j) {
                    bool ok=err.below(den[j]);counts[profile][row][j]+=ok;
                    if(!profile) base_ok[j]=ok;
                    else {paired[profile][row][j]+=int(ok)-int(base_ok[j]);discordant[profile][row][j]+=ok!=base_ok[j];}
                }
            }
        }
    }
    if(!counters.consistent()) throw std::runtime_error("counter invariant");
    std::cout<<"samples="<<samples<<" seed="<<seed<<" distribution=uniform-value ops_bits=7 fraction_bits=12\n";
    std::cout<<"profile,n,threshold_percent,count,percent,delta_Proposed_pp,paired_delta_baseline_pp,paired_se_pp,changed_outputs\n";
    std::cout<<std::fixed<<std::setprecision(6);
    for(unsigned v=0;v<7;++v) for(unsigned row=0;row<3;++row) for(unsigned j=0;j<4;++j) {
        if(selected>=0 && v && int(v)!=selected) continue;
        double percent=100.*counts[v][row][j]/samples;
        double mean=double(paired[v][row][j])/samples;
        double variance=double(discordant[v][row][j])/samples-mean*mean;
        double se=100*std::sqrt(std::max(0.,variance)/samples);
        std::cout<<names[v]<<','<<row+2<<','<<100./den[j]<<','<<counts[v][row][j]<<','<<percent
                 <<','<<percent-proposed[row][j]<<','<<100*mean<<','<<se<<','<<changed[v][row]<<'\n';
    }
    std::cout<<"attempted="<<counters.attempted<<" accepted="<<counters.accepted<<" zero="<<counters.input_zero
             <<" regime="<<counters.regime<<" ideal_zero="<<counters.ideal_zero<<" ties="<<ties
             <<" draws="<<gen.draws<<" fingerprint="<<std::hex<<fingerprint.hash<<std::dec
             <<" elapsed="<<std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count()<<'\n';
    return 0;
} catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 2;}
