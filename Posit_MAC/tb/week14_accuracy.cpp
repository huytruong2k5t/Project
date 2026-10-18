#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>
#include <vector>
#include "posit_fused_window.hpp"
#include "week11_model.hpp"
#include "week12_fused_reference.hpp"
using O=week12_reference::Oracle<32,3>;
using U=week12_reference::u128;
using F=l1::FusedWindow<32,3,12,32>;
using NF=week11::Model<32,3,12>;
long double value(uint32_t bits) {
    if(bits==O::NAR)return 0; // Only a placeholder in excluded NaR trace rows.
    auto v=O::decode(bits);
    return (v.sign?-1.L:1.L)*std::ldexp(static_cast<long double>(v.coefficient),v.sf-26);
}
long double ideal_value(const O::Result& r) {
    long double v=0;
    for(int i=int(O::WORDS)-1;i>=0;--i)v=std::ldexp(v,64)+static_cast<long double>(r.magnitude[unsigned(i)]);
    return (r.sign?-1.L:1.L)*std::ldexp(v,-O::BASE);
}
int compare(const O::Wide& a,const O::Wide& b) {
    for(int i=int(O::WORDS)-1;i>=0;--i)
        if(a[unsigned(i)]!=b[unsigned(i)])return a[unsigned(i)]>b[unsigned(i)]?1:-1;
    return 0;
}
O::Wide error_grid(const O::Result& r,uint32_t bits) {
    if(bits==O::NAR)return {};
    const auto y=O::decode(bits);
    auto a=r.magnitude,b=O::expand(y.coefficient,y.sf-26);
    O::Wide out{};
    if(r.sign!=y.sign) {
        uint64_t carry=0;
        for(unsigned i=0;i<O::WORDS;++i){const U t=U(a[i])+b[i]+carry;out[i]=uint64_t(t);carry=uint64_t(t>>64);}
    } else {
        if(compare(a,b)<0)std::swap(a,b);
        uint64_t borrow=0;
        for(unsigned i=0;i<O::WORDS;++i){const U t=U(b[i])+borrow;out[i]=a[i]-uint64_t(t);borrow=U(a[i])<t;}
    }
    return out;
}
bool threshold(const O::Wide& error,const O::Wide& reference,unsigned multiplier) {
    O::Wide scaled{};uint64_t carry=0;
    for(unsigned i=0;i<O::WORDS;++i){const U t=U(error[i])*multiplier+carry;scaled[i]=uint64_t(t);carry=uint64_t(t>>64);}
    return !carry&&compare(scaled,reference)<0;
}
long double grid_value(const O::Wide& magnitude) {
    O::Result r{};r.magnitude=magnitude;return ideal_value(r);
}
struct Stats {
    uint64_t finite=0,nar=0,zero=0,zero_match=0;
    std::array<uint64_t,4> correct{};
    long double square=0,max_err=0,max_abs_zero=0;
    uint64_t max_ulp=0;
    std::vector<long double> errors;
    void sample(uint32_t got,const O::Result& reference,long double r,bool special) {
        if(special||got==O::NAR){++nar;return;}
        const long double y=value(got);
        if(r==0){++zero;zero_match+=got==0;max_abs_zero=std::max(max_abs_zero,std::fabs(y));return;}
        ++finite;
        const auto exact_error=error_grid(reference,got);
        const long double rel=grid_value(exact_error)/std::fabs(r),err=100*rel;
        square+=rel*rel;max_err=std::max(max_err,err);errors.push_back(err);
        constexpr unsigned multipliers[]={1000,200,100,20};
        for(unsigned j=0;j<4;++j)correct[j]+=threshold(exact_error,reference.magnitude,multipliers[j]);
        const int64_t delta=int64_t(int32_t(got))-int64_t(int32_t(reference.bits));
        max_ulp=std::max(max_ulp,uint64_t(delta<0?-delta:delta));
    }
    void write(std::ostream& out) {
        std::sort(errors.begin(),errors.end());
        out<<"{\"finite_nonzero\":"<<finite<<",\"nar\":"<<nar<<",\"reference_zero\":"<<zero
           <<",\"zero_match\":"<<zero_match<<",\"max_absolute_error_at_zero\":"<<max_abs_zero
           <<",\"relative_nmse\":"<<(finite?square/finite:0)<<",\"max_err_percent\":"<<max_err
           <<",\"max_ulp\":"<<max_ulp<<",\"correct_counts\":[";
        for(unsigned j=0;j<4;++j)out<<(j?",":"")<<correct[j];
        out<<"],\"percentile_50_90_99\":[";
        for(unsigned j=0;j<3;++j){const unsigned p[]={50,90,99};out<<(j?",":"")<<(errors.empty()?0:errors[(errors.size()-1)*p[j]/100]);}
        out<<"]}";
    }
};
int main(int argc,char** argv) {
    if(argc!=5)return 2;
    const unsigned n=std::stoul(argv[1]);const uint64_t count=std::stoull(argv[2]);
    const std::string prefix=argv[3];const uint64_t seed=std::stoull(argv[4]);
    std::mt19937_64 rng(seed);Stats nf,f,nf_directed,f_directed,nf_random,f_random,nf_calibration,f_calibration;
    uint64_t win=0,lose=0,tie=0,paired_finite=0;
    std::ofstream trace(prefix+".jsonl");trace<<std::setprecision(24);
    for(uint64_t i=0;i<count;++i) {
        uint32_t a=rng(),b=rng(),c=rng();
        // Published prefix is a separate directed stratum, not IID application accuracy.
        if(i<128) {
            constexpr uint32_t x[]={0,0x80000000,0x40000000,0xc0000000,1,0x7fffffff,0x40000001,0xffffffff};
            a=x[i%8];b=x[(i/8)%8];c=x[(i/16)%8];
            if(i>=112){a=0x40000000;b=0x40000000;c=0xc0000000+(i-112);}
        }
        l1::IterConfig cfg;cfg.n=n;cfg.ops=1;cfg.scheme=l1::ShiftRound::FLOOR;cfg.rounding=l1::RoundMode::RNE;
        const auto m=l1::L1MultiplierIter<32,3,12>::mul(a,b,cfg);
        const auto y_nf=NF::mac(a,b,c,false,n,1);const auto y_f=F::add(m.prepack,c);
        const auto av=O::decode(a==O::NAR?0:a),bv=O::decode(b==O::NAR?0:b);
        l1::PrepackProduct exact{};
        exact.is_nar=a==O::NAR||b==O::NAR;exact.is_zero=a==0||b==0;
        exact.sign=av.sign!=bv.sign;exact.scale=av.sf+bv.sf;
        exact.fractional_bits=52;exact.magnitude=av.coefficient*bv.coefficient;
        const auto ref=O::add(exact,c);const bool special=exact.is_nar||c==O::NAR;
        const long double r=ideal_value(ref);
        nf.sample(y_nf.bits,ref,r,special);f.sample(y_f.bits,ref,r,special);
        if(i<128){nf_directed.sample(y_nf.bits,ref,r,special);f_directed.sample(y_f.bits,ref,r,special);}
        else {nf_random.sample(y_nf.bits,ref,r,special);f_random.sample(y_f.bits,ref,r,special);}
        if(i<1024){nf_calibration.sample(y_nf.bits,ref,r,special);f_calibration.sample(y_f.bits,ref,r,special);}
        if(!special&&r!=0) {
            ++paired_finite;const int comparison=compare(error_grid(ref,y_f.bits),error_grid(ref,y_nf.bits));
            win+=comparison<0;lose+=comparison>0;tie+=comparison==0;
        }
        if(i<1024) {
            trace<<"{\"i\":"<<i<<",\"n\":"<<n<<",\"a\":"<<a<<",\"b\":"<<b<<",\"c\":"<<c
                 <<",\"nf\":"<<y_nf.bits<<",\"f\":"<<y_f.bits<<",\"ref\":"<<ref.bits
                 <<",\"nar\":"<<special<<",\"ideal\":\""<<r<<"\",\"metrics\":[";
            for(unsigned k=0;k<2;++k) {
                const auto y=k?y_f.bits:y_nf.bits;const auto grid=error_grid(ref,y);const auto error=grid_value(grid);
                trace<<(k?",":"")<<"{\"absolute\":\""<<error<<"\",\"err_percent\":\""<<((special||r==0)?0:100*error/std::fabs(r))<<"\",\"correct\":[";
                constexpr unsigned multipliers[]={1000,200,100,20};
                for(unsigned j=0;j<4;++j)trace<<(j?",":"")<<threshold(grid,ref.magnitude,multipliers[j]);
                trace<<"]}";
            }
            trace<<"]}\n";
        }
    }
    std::ofstream out(prefix+".json");out<<std::setprecision(24);
    out<<"{\"status\":\"PASS_COLLECTED_PENDING_PYTHON_CHECK\",\"n\":"<<n<<",\"seed\":"<<seed<<",\"samples\":"<<count
       <<",\"policy\":\"standalone shared C_port; exact real A*B+C; directed prefix128 separate stratum\",\"nf\":";
    nf.write(out);out<<",\"f\":";f.write(out);
    out<<",\"directed_nf\":";nf_directed.write(out);out<<",\"directed_f\":";f_directed.write(out);
    out<<",\"random_nf\":";nf_random.write(out);out<<",\"random_f\":";f_random.write(out);
    out<<",\"calibration_nf\":";nf_calibration.write(out);out<<",\"calibration_f\":";f_calibration.write(out);
    out<<",\"paired_finite_nonzero\":"<<paired_finite<<",\"f_win_lose_tie\":["<<win<<','<<lose<<','<<tie<<"]}\n";
    std::cout<<"ACCURACY PILOT n="<<n<<" samples="<<count<<" collected\n";
}
