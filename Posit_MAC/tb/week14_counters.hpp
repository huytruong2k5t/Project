#pragma once
#include <array>
#include <cstdint>
#include <fstream>
#include <stdexcept>

namespace week14 {
// Count completed transactions only. Reset-aborted samples never enter near bins.
struct Counters {
    std::array<uint64_t,100> fused_cross{};
    std::array<uint64_t,10> before{}, after{};
    uint64_t completed=0, near_before=0, near_after=0, special=0, exact_zero=0;
    static unsigned delta_bucket(unsigned d, unsigned f) {
        return d==0 ? 0 : d==1 ? 1 : d<=7 ? 2 : d<=f+2 ? 3 : 4;
    }
    static unsigned lzc_bucket(unsigned n) {
        return n==0 ? 0 : n==1 ? 1 : n<=4 ? 2 : n<=15 ? 3 : 4;
    }
    static unsigned key(bool c_anchor, bool different, unsigned d, unsigned z) {
        if (d>=5 || z>=5) throw std::out_of_range("coverage key");
        return z+5*d+25*unsigned(different)+50*unsigned(c_anchor);
    }
    void sample(bool finite, bool nb, bool na, unsigned mode, unsigned db, unsigned da,
                bool c_anchor, bool different, unsigned d, unsigned z, bool zero) {
        if (mode>1 || db>4 || da>4) throw std::out_of_range("coverage sample");
        ++completed;
        if (!finite) {++special;return;}
        if (nb) {++near_before;++before[db+5*mode];}
        if (na) {++near_after;++after[da+5*mode];}
        if (zero) ++exact_zero;
        else ++fused_cross[key(c_anchor,different,d,z)];
    }
    void write(const std::string& path) const {
        std::ofstream out(path);
        if (!out) throw std::runtime_error("coverage output");
        out<<"{\"completed\":"<<completed<<",\"near_before\":"<<near_before
           <<",\"near_after\":"<<near_after<<",\"nonfinite_or_zero_operand\":"<<special
           <<",\"exact_zero\":"<<exact_zero;
        auto emit=[&](const char* name,const auto& a) {
            out<<",\""<<name<<"\":[";
            for (unsigned i=0;i<a.size();++i) out<<(i?",":"")<<a[i];
            out<<']';
        };
        emit("before_delta_mode",before);emit("after_delta_mode",after);
        emit("anchor_sign_delta_lzc",fused_cross);out<<"}\n";
    }
};
}
