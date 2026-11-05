#pragma once
#include <map>
#include <ostream>
#include <string>

// Named, versioned bins. Sample transactions only at retire; pipeline bins are
// separately labelled (they can include a transaction subsequently reset-aborted).
// The reporter owns the required-bin list, not this hit-only map.
struct NfFCoverage {
    std::map<std::string,uint64_t> hits;
    void hit(const std::string& name) { ++hits[name]; }
    static unsigned pop_group(unsigned p) {
        return p<3?p:(p<5?3:(p<9?4:5));
    }
    void operands(uint32_t a,uint32_t b,uint32_t c,unsigned n,unsigned ops,
                  bool accumulate,bool clear,unsigned flags) {
        hit("config/ops"+std::to_string(ops)+"/n"+std::to_string(n));
        hit(accumulate?"scenario/feedback":"scenario/standalone");
        if (clear) hit("scenario/clear_feedback");
        hit("flags/"+std::to_string(flags));
        const uint32_t raw[]={a,b,c};
        const char* ports[]={"a","b","c"};
        const uint32_t corner[]={0,0x80000000u,1,0xffffffffu,0x7fffffffu,0x80000001u,0x40000000u,0xc0000000u};
        for (unsigned i=0;i<3;++i) {
            for(unsigned k=0;k<8;++k) if(raw[i]==corner[k]) hit(std::string("corner/")+ports[i]+"/"+std::to_string(k));
        }
        if(a==0x80000000u && !b) hit("corner/nar_times_zero");
        if(!a && b==0x80000000u) hit("corner/zero_times_nar");
        if((!a || !b) && c && c!=0x80000000u) hit("corner/zero_product_nonzero_c");
        if(a && b && a!=0x80000000u && b!=0x80000000u) {
            const auto av=opt17_reference::Oracle::decode(a),bv=opt17_reference::Oracle::decode(b);
            const unsigned fa=unsigned(av.coefficient>>14)&4095,fb=unsigned(bv.coefficient>>14)&4095;
            const unsigned pa=unsigned(__builtin_popcount(fa)),pb=unsigned(__builtin_popcount(fb));
            hit("popcount/a/"+std::to_string(pop_group(pa)));
            hit("popcount/b/"+std::to_string(pop_group(pb)));
            if(ops) hit(pa==pb?"ops/tie_a":(pb<pa?"ops/swap_b":"ops/keep_a"));
        }
    }
    void pipeline(bool pack_sample,unsigned special,unsigned rounding,
                  bool add_sample,unsigned shift,bool clamped,bool sub,
                  bool lzc_sample,unsigned lzc) {
        if(pack_sample) {
            hit("pipeline/pack/special/"+std::to_string(special));
            if(!special) {
                hit("pipeline/pack/grs/"+std::to_string(rounding&7));
                if((rounding&7)==4) hit(rounding&8?"pipeline/pack/tie_odd":"pipeline/pack/tie_even");
                hit((rounding&4) && (rounding&11)?"pipeline/pack/round_up":"pipeline/pack/round_down");
            }
        }
        if(add_sample) {
            hit("pipeline/add/shift/"+std::to_string(shift));
            hit(clamped?"pipeline/add/clamped":"pipeline/add/unclamped");
            hit(sub?"pipeline/add/sub":"pipeline/add/add");
        }
        if(lzc_sample) hit("pipeline/add/lzc/"+std::to_string(lzc));
    }
    void write(std::ostream& out) const {
        out<<"{\"schema\":1,\"sampling\":\"retire for transaction bins; valid/ready for pipeline bins\",\"hits\":{";
        bool first=true;
        for(const auto& p:hits) { if(!first) out<<',';first=false;out<<'"'<<p.first<<"\":"<<p.second; }
        out<<"}}";
    }
};
