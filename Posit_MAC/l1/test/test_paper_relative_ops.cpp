#include <iostream>
#include <numeric>
// Retain the independently implemented experimental datapath as a differential oracle.
#define main sensitivity_program_main
#include "test_paper_sensitivity.cpp"
#undef main
uint64_t relative_checks=0;
void check_relative(bool ok,const char* message) {
    ++relative_checks;if(!ok) throw std::runtime_error(message);
}
// Independent Q24 residual oracle for the original seven-bit prediction errors.
unsigned relative_reference_error(unsigned f) {
    uint32_t residual=(128+f)*131072;int sign=1,approximation=0;
    for(unsigned j=0;j<2 && residual;++j) {
        unsigned top=0;for(auto t=residual;t/=2;) ++top;
        bool up=uint64_t(residual)*2>=3*(uint64_t(1)<<top);
        approximation+=sign*(1<<(int(top)-17+int(up)));
        if(up) {residual=(uint32_t(1)<<(top+1))-residual-(uint32_t(1)<<(top-7));sign=-sign;}
        else residual-=uint32_t(1)<<top;
    }
    return unsigned(std::abs(int(128+f)-approximation));
}
int main() try {
    int order[128][128];unsigned changes=0,ties=0;
    for(unsigned a=0;a<128;++a) for(unsigned b=0;b<128;++b) {
        unsigned ea=relative_reference_error(a),eb=relative_reference_error(b);
        unsigned ga=std::gcd(ea,128+a),gb=std::gcd(eb,128+b);
        bool equal=ea/ga==eb/gb && (128+a)/ga==(128+b)/gb;
        long double ra=static_cast<long double>(ea)/(128+a),rb=static_cast<long double>(eb)/(128+b);
        order[a][b]=equal?0:(rb<ra?-1:1);
        auto s=paper_ops_select_relative<7>(a,b);
        check_relative(s.swapped==(order[a][b]<0) && s.tie==equal,"rational score / tie");
        check_relative(s.error_a==ea && s.error_b==eb,"independent prediction errors");
        changes+=s.swapped!=paper_ops_select<7>(a,b).swapped;ties+=equal;
    }
    check_relative(changes>0 && ties>0,"relative comparator exercised");
    for(unsigned a=0;a<4096;++a) for(unsigned b=0;b<4096;++b) {
        auto s=paper_ops_select_relative(a,b);int expected=order[a>>5][b>>5];
        check_relative(s.swapped==(expected<0),"4096 squared selection / low5 invariance");
        check_relative(s.tie==(expected==0),"4096 squared relative ties");
    }
    for(unsigned a=0;a<128;++a) for(unsigned b=0;b<128;++b) {
        auto s=paper_ops_select_relative<27>((a<<20)|0xfffff,(b<<20)|0x55555);
        check_relative(s.swapped==(order[a][b]<0) && s.tie==(order[a][b]==0),"W27 index / bounds");
    }
    bool rejects=false;try {paper_ops_select_relative(4096,0);} catch(const std::invalid_argument&) {rejects=true;}
    check_relative(rejects,"fraction outside domain");
    paper_init_fp32_rne();std::mt19937_64 rng(20261004);
    for(unsigned j=0;j<100000;++j) {
        uint32_t a=uint32_t(rng()),b=uint32_t(rng());
        auto ua=parse<32,3>(a),ub=parse<32,3>(b);
        bool special=ua.is_zero || ub.is_zero || ua.is_nar || ub.is_nar;
        bool swap=!special && order[((ua.frac>>51)&4095)>>5][((ub.frac>>51)&4095)>>5]<0;
        for(unsigned n=1;n<=8;++n) {
            PaperConfig cfg;cfg.n=n;cfg.ops=PaperOps::PredictN2Relative;
            cfg.rounding=(j&1)?RoundMode::RNE:RoundMode::TRUNC;cfg.complement=(j&2)!=0;
            auto got=PaperMultiplier<>::mul(a,b,cfg);cfg.ops=PaperOps::FixedA;
            auto expected=PaperMultiplier<>::mul(swap?b:a,swap?a:b,cfg);
            check_relative(got.bits==expected.bits && got.swapped==swap,"core direction/sign/specials/n/rounding");
            check_relative(got.iterations==expected.iterations && got.remainder==expected.remainder &&
                got.shift_tail==expected.shift_tail && got.input_cut==expected.input_cut,"core metadata");
        }
    }
    PaperGenerator generator(314159,PaperDistribution::UniformValue);
    for(unsigned j=0;j<100000;++j) {
        auto a=generator.next_bits(),b=generator.next_bits();auto p=paper_evaluate_pair(a,b);
        if(p.reason!=PaperReject::Accepted) continue;
        for(unsigned n=2;n<=4;++n) {
            PaperConfig cfg;cfg.n=n;cfg.ops=PaperOps::PredictN2Relative;
            check_relative(PaperMultiplier<>::mul(p.posit_a,p.posit_b,cfg).bits==
                experimental(p.posit_a,p.posit_b,n,Profile::RelativePrediction),"research tool differential");
        }
    }
    std::cout<<"PASS checks="<<relative_checks<<" seed=20261004 corpus_seed=314159 changed_prefix_pairs="
             <<changes<<" rational_ties="<<ties<<'\n';return 0;
} catch(const std::exception& e) {std::cerr<<"FAIL "<<e.what()<<'\n';return 1;}
