#include "paper_anchor_study.hpp"
using Wide=unsigned __int128;
uint64_t checks=0;
void check(bool ok,const char*what) {++checks;if(!ok) throw std::runtime_error(what);}
// Q96 independent signed remainder oracle; never calls PaperSac.
posit_unpacked<32,3> reference(uint32_t a,uint32_t b,PaperConfig cfg) {
    auto ua=parse<32,3>(a),ub=parse<32,3>(b);
    if(ua.is_nar || ub.is_nar) return {true,false,true,0,0,true};
    if(ua.is_zero || ub.is_zero) return {false,true,false,0,0,true};
    uint64_t x=ua.frac>>51,y=ub.frac>>51;
    // Research reference LUT is independently computed from the residual chain.
    if(prediction_prefix12(unsigned((y-4096)>>5))<prediction_prefix12(unsigned((x-4096)>>5))) std::swap(x,y);
    int anchor=cfg.anchor_first?int(x>=6144):0,sign=1;
    Wide residual=Wide(x)<<84;int64_t acc=0;
    for(unsigned j=0;j<cfg.n && residual;++j) {
        unsigned top=0;for(Wide v=residual;v>>=1;) ++top;
        bool up=residual>=(Wide(3)<<(top-1));
        int power=int(top)-96+int(up),aligned=power-anchor+int(cfg.accumulator_guard);
        uint64_t term=aligned>=0?y<<aligned:(aligned<=-64?0:y>>(-aligned));
        acc+=sign*int64_t(term);
        if(up) {residual=(Wide(1)<<(top+1))-residual-(Wide(1)<<(top-12));sign=-sign;}
        else residual-=Wide(1)<<top;
    }
    uint64_t hidden=uint64_t(4096)<<cfg.accumulator_guard;
    int sf=ua.sf+ub.sf+anchor;bool sticky=false;
    while(uint64_t(acc)>=2*hidden) {sticky|=acc&1;acc>>=1;++sf;}
    while(uint64_t(acc)<hidden) {acc<<=1;--sf;}
    return {bool(ua.sign^ub.sign),false,false,sf,uint64_t(acc)<<(51-cfg.accumulator_guard),!sticky};
}
void compare(uint32_t a,uint32_t b,PaperConfig cfg) {
    auto result=PaperMultiplier<>::mul(a,b,cfg);
    auto ref=reference(a,b,cfg);
    check(result.bits==pack<32,3>(ref,cfg.rounding),"source independent Q96 oracle");
    check(result.unpacked.sign==ref.sign && result.unpacked.is_zero==ref.is_zero &&
          result.unpacked.is_nar==ref.is_nar && result.unpacked.sf==ref.sf &&
          result.unpacked.frac==ref.frac && result.unpacked.exact==ref.exact,"source unpacked oracle");
}
int main() try {
    for(unsigned i=0;i<128;++i) check(paper_pattern_prediction_error(i)==prediction_prefix12(i),"pattern API oracle");
    for(unsigned x=0;x<4096;++x) for(unsigned y=0;y<4096;++y) {
        auto s=paper_ops_select_pattern(x,y);
        unsigned a=prediction_prefix12(x>>5),b=prediction_prefix12(y>>5);
        check(s.error_a==a && s.error_b==b && s.swapped==(b<a) && s.tie==(a==b),"pattern exhaustive selection");
    }
    std::mt19937_64 rng(20261004);
    const uint32_t corners[]={0,1,0x80000000,0x7fffffff,0xffffffff,0x40000000,0xc0000000,0x48000000,0x47ffffff,0x48000001};
    auto cfg=paper_source_config();
    for(auto a:corners) for(auto b:corners) for(unsigned n=1;n<=8;++n) {cfg.n=n;compare(a,b,cfg);}
    for(unsigned j=0;j<100000;++j) {
        uint32_t a=uint32_t(rng()),b=uint32_t(rng());
        for(unsigned n=1;n<=8;++n) for(unsigned guard:{0u,1u,2u,12u}) for(bool anchor:{false,true}) {
            cfg.n=n;cfg.accumulator_guard=guard;cfg.anchor_first=anchor;
            cfg.rounding=j&1?RoundMode::RNE:RoundMode::TRUNC;compare(a,b,cfg);
        }
    }
    bool rejected=false;cfg.accumulator_guard=13;
    try {PaperMultiplier<>::mul(0x40000000,0x40000000,cfg);} catch(const std::invalid_argument&) {rejected=true;}
    check(rejected,"guard width bounds");
    paper_init_fp32_rne();PaperGenerator generator(314159,PaperDistribution::UniformValue);
    for(unsigned j=0;j<100000;++j) {
        auto pair=paper_evaluate_pair(generator.next_bits(),generator.next_bits());
        if(pair.reason!=PaperReject::Accepted) continue;
        for(unsigned n=2;n<=4;++n) {
            cfg=paper_source_config();cfg.n=n;
            check(PaperMultiplier<>::mul(pair.posit_a,pair.posit_b,cfg).bits==
                  experimental(pair.posit_a,pair.posit_b,n,Profile::Prefix12Anchor),"source research integration");
        }
    }
    std::cout<<"SOURCE_PROFILE PASS checks="<<checks<<" raw_seed=20261004 corpus_seed=314159\n";
    return 0;
} catch(const std::exception&e) {std::cerr<<e.what()<<'\n';return 1;}
