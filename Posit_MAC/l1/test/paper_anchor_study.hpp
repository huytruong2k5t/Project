#pragma once
// Research-only profiles; published widths and LUT remain reconstruction assumptions.
#include <chrono>
#include <iomanip>
#include <iostream>
#include <string>
#include "paper_multiplier.hpp"
#include "paper_measurement.hpp"
using namespace l1;
enum class Profile { Baseline, TieB, RelativePrediction, ExactPredictionResidual,
                     Guard12, ExactSacResidual, PackRne, Anchor0, Anchor1, Anchor2, Anchor12, Prefix12, Prefix12Anchor, PostCutInput, PostCutAnchor };
constexpr unsigned PROFILE_COUNT=15;
inline const char* names[]={"baseline","tie_b","relative_prediction","exact_prediction_residual",
                     "acc_guard12","exact_sac_residual","pack_rne","anchor0","anchor1","anchor2","anchor12","prefix12","prefix12_anchor","post_cut_input","post_cut_anchor"};
inline unsigned prediction_exact(unsigned f) {
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
inline unsigned prediction_prefix12(unsigned f) {
    PaperSac sac((128+f)<<5,12);int approximation=0;
    for(unsigned j=0;j<2 && sac.mantissa;++j) {
        bool up=sac.mantissa>=6144;int p=sac.exponent+int(up);
        approximation+=sac.coefficient*(1<<(12+p));sac.advance(up);
    }
    return unsigned(std::abs(int((128+f)<<5)-approximation));
}
inline uint32_t experimental_mantissa(uint64_t x,uint64_t y,int sf_a,int sf_b,unsigned n,Profile profile,bool fp32_output=false) {
    unsigned ia=unsigned((x-4096)>>5),ib=unsigned((y-4096)>>5);
    unsigned ea=paper_prediction_lut()[ia],eb=paper_prediction_lut()[ib];
    bool swap=eb<ea;
    if(profile==Profile::TieB) swap=eb<=ea;
    if(profile==Profile::RelativePrediction) swap=eb*(128+ia)<ea*(128+ib);
    if(profile==Profile::ExactPredictionResidual) swap=prediction_exact(ib)<prediction_exact(ia);
    if(profile==Profile::Prefix12 || profile==Profile::Prefix12Anchor) swap=prediction_prefix12(ib)<prediction_prefix12(ia);
    if(swap) std::swap(x,y);
    bool anchor_first=(profile>=Profile::Anchor0 && profile<=Profile::Anchor12) || profile==Profile::Prefix12Anchor || profile==Profile::PostCutAnchor;
    unsigned guard=profile==Profile::Guard12 || profile==Profile::Anchor12 || profile==Profile::Prefix12Anchor?12:
                   profile==Profile::Anchor1?1:profile==Profile::Anchor2?2:0;
    int anchor=anchor_first?int(x>=6144):0;
    PaperSac sac(x,12,profile!=Profile::ExactSacResidual);
    bool post_only=profile==Profile::PostCutInput || profile==Profile::PostCutAnchor;
    long double exact_sum=0;int64_t acc=0;
    for(unsigned j=0;j<n && sac.mantissa;++j) {
        bool up=sac.mantissa>=6144;
        int shift=sac.exponent+int(up)+int(guard)-anchor;
        uint64_t term=shift>=0?y<<shift:(-shift>=64?0:y>>(-shift));
        acc+=sac.coefficient*int64_t(term);
        if(post_only) exact_sum+=sac.coefficient*std::ldexp(static_cast<long double>(y),shift);
        sac.advance(up);
    }
    if(post_only) acc=int64_t(std::floor(exact_sum));
    if(acc<=0) throw std::runtime_error("nonpositive experimental result");
    uint64_t hidden=uint64_t(4096)<<guard;
    int sf=sf_a+sf_b+anchor;bool sticky=false;
    while(uint64_t(acc)>=2*hidden) {sticky|=acc&1;acc>>=1;++sf;}
    while(uint64_t(acc)<hidden) {acc<<=1;--sf;}
    posit_unpacked<32,3> u{false,false,false,sf,uint64_t(acc)<<(51-guard),!sticky};
    if(fp32_output) {
        if(sf < -126 || sf > 127) throw std::runtime_error("FP32 comparator normal output only");
        uint32_t significand=uint32_t(u.frac>>40);
        return (uint32_t(sf+127)<<23)|(significand&0x7fffff);
    }
    return pack<32,3>(u,profile==Profile::PackRne?RoundMode::RNE:RoundMode::TRUNC);
}
inline uint32_t experimental(uint32_t a,uint32_t b,unsigned n,Profile profile) {
    auto ua=parse<32,3>(a),ub=parse<32,3>(b);
    return experimental_mantissa(ua.frac>>51,ub.frac>>51,ua.sf,ub.sf,n,profile);
}
