#include "paper_anchor_study.hpp"
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
            for(unsigned v=0;v<PROFILE_COUNT;++v) if(name==names[v]) selected=int(v);
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
                // Post-sum cut oracle: independent signed residual on Q96,
                // exact signed product terms accumulated on Q64 before one cut.
                for(auto candidate:{Profile::PostCutInput,Profile::PostCutAnchor}) {
                    int anchor=candidate==Profile::PostCutAnchor?int(x>=6144):0;
                    using U128=unsigned __int128;using I128=__int128;
                    U128 residual=U128(x)<<84;I128 sum_q64=0;int sign=1;
                    for(unsigned k=0;k<n && residual;++k) {
                        unsigned top=0;for(U128 v=residual;v>>=1;) ++top;
                        bool up=residual>=(U128(3)<<(top-1));
                        int power=int(top)-96+int(up);
                        if(power-anchor+64<0) throw std::runtime_error("postcut oracle grid too narrow");
                        sum_q64+=sign*I128(U128(y)<<(power-anchor+64));
                        if(up) {residual=(U128(1)<<(top+1))-residual-(U128(1)<<(top-12));sign=-sign;}
                        else residual-=U128(1)<<top;
                    }
                    uint64_t normalized=uint64_t(sum_q64>>64);int sf=ua.sf+ub.sf+anchor;bool sticky=false;
                    while(normalized>=8192) {sticky|=normalized&1;normalized>>=1;++sf;}
                    while(normalized<4096) {normalized<<=1;--sf;}
                    posit_unpacked<32,3> ref{false,false,false,sf,normalized<<51,!sticky};
                    if(experimental(p.posit_a,p.posit_b,n,candidate)!=pack<32,3>(ref,RoundMode::TRUNC))
                        throw std::runtime_error("postcut Q96/Q64 oracle");
                    ++checks;
                }
                // Independent dyadic oracle: 27 bits suffice for Q12/n<=4 terms.
                for(auto candidate:{Profile::Anchor0,Profile::Anchor1,Profile::Anchor2,Profile::Anchor12}) {
                    unsigned g=candidate==Profile::Anchor1?1:candidate==Profile::Anchor2?2:candidate==Profile::Anchor12?12:0;
                    unsigned anch=unsigned(x>=6144);
                    PaperSac reference_sac(x,12);int64_t sum_q=0;
                    for(unsigned k=0;k<n && reference_sac.mantissa;++k) {
                        bool up=reference_sac.mantissa>=6144;
                        long double dyadic=std::ldexp(static_cast<long double>(y),reference_sac.exponent+int(up)+int(g)-int(anch));
                        sum_q+=reference_sac.coefficient*int64_t(std::floor(dyadic));
                        reference_sac.advance(up);
                    }
                    long double val=std::ldexp(static_cast<long double>(sum_q),ua.sf+ub.sf+int(anch)-12-int(g));
                    int scale=0;long double mant=std::frexp(val,&scale)*2;
                    long double scaled=std::ldexp(mant,12+int(g));
                    uint64_t normalized=uint64_t(std::floor(scaled));
                    posit_unpacked<32,3> ref{false,false,false,scale-1,normalized<<(51-g),scaled==normalized};
                    if(experimental(p.posit_a,p.posit_b,n,candidate)!=pack<32,3>(ref,RoundMode::TRUNC))
                        throw std::runtime_error("anchor independent dyadic oracle");
                    ++checks;
                }
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
    uint64_t counts[PROFILE_COUNT][3][4]={},changed[PROFILE_COUNT][3]={},ties=0;
    int64_t paired[PROFILE_COUNT][3][4]={};uint64_t discordant[PROFILE_COUNT][3][4]={};
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
            for(unsigned profile=0;profile<PROFILE_COUNT;++profile) {
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
    for(unsigned v=0;v<PROFILE_COUNT;++v) for(unsigned row=0;row<3;++row) for(unsigned j=0;j<4;++j) {
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
