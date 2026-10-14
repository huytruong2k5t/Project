#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>
#include "../../tb/week11_model.hpp"

// Research runner only. Frozen L1/RTL profiles are not modified.
namespace survey {
constexpr unsigned F = 26;
constexpr uint32_t NAR = 0x80000000u;
constexpr std::array<unsigned, 9> WIDTHS{8, 10, 12, 14, 16, 18, 20, 24, 26};
constexpr std::array<long double, 9> LIMITS{0.000001L, 0.00001L, 0.0001L,
    0.001L, 0.01L, 0.1L, 0.5L, 1.L, 5.L}; // Percent, strict less-than.
uint64_t checks = 0;

uint64_t next(uint64_t& state) {
    uint64_t z = (state += 0x9e3779b97f4a7c15ULL);
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ULL;
    z = (z ^ (z >> 27)) * 0x94d049bb133111ebULL;
    return z ^ (z >> 31);
}
void require(bool value, const char* message) {
    if (!value) throw std::runtime_error(message);
    ++checks;
}
struct Decoded { uint64_t sig; int scale; bool sign; };
Decoded decode(uint32_t bits) {
    const bool sign = (bits & NAR) != 0;
    const uint32_t mag = sign ? 0u - bits : bits;
    int bit = 30, run = 0;
    const bool polarity = (mag >> bit) & 1;
    while (bit >= 0 && bool((mag >> bit) & 1) == polarity) { ++run; --bit; }
    if (bit >= 0) --bit;
    int exponent = 0;
    for (unsigned i = 0; i < 3; ++i) {
        exponent *= 2;
        if (bit >= 0) exponent |= (mag >> bit--) & 1;
    }
    const unsigned fb = unsigned(bit + 1);
    const uint64_t sig = ((uint64_t(1) << fb) | (mag & ((uint64_t(1) << fb) - 1))) << (F - fb);
    return {sig, (polarity ? run - 1 : -run) * 8 + exponent, sign};
}
long double real(uint32_t bits) {
    if (!bits) return 0;
    const auto v = decode(bits);
    return std::ldexp(static_cast<long double>(v.sig), v.scale - int(F)) * (v.sign ? -1 : 1);
}
unsigned population(uint64_t bits) {
    unsigned count = 0;
    for (; bits; bits >>= 1) count += bits & 1;
    return count;
}
int64_t rank(uint32_t bits) {
    return bits < NAR ? int64_t(bits) : int64_t(bits) - (int64_t(1) << 32);
}
struct Eval { l1::PrepackProduct p; unsigned iterations; };
template<unsigned W> Eval model(uint32_t a, uint32_t b, unsigned n) {
    l1::IterConfig cfg;
    cfg.n = n;
    cfg.ops = 1;
    cfg.scheme = l1::ShiftRound::FLOOR;
    cfg.rounding = l1::RoundMode::RNE;
    // N_MAX=26 is local to the survey. n=full is not the frozen RTL n<=8 profile.
    const auto result = l1::L1MultiplierIter<32, 3, W, 26>::mul(a, b, cfg);
    const auto x = decode(a), y = decode(b);
    const uint64_t mask = (uint64_t(1) << W) - 1;
    uint64_t fx = (x.sig >> (F-W)) & mask;
    uint64_t fy = (y.sig >> (F-W)) & mask;
    if (population(fy) < population(fx)) std::swap(fx, fy);
    const uint64_t ym = (uint64_t(1) << W) | fy;
    uint64_t total = ym;
    unsigned terms = 0;
    bool tail = false;
    // Independent bit-position traversal; no SAC/SBM/model calls.
    for (unsigned pos = 1; pos <= W && terms < n; ++pos) {
        if (!(fx & (uint64_t(1) << (W-pos)))) continue;
        total += ym >> pos;
        tail |= (ym & ((uint64_t(1) << pos)-1)) != 0;
        ++terms;
    }
    require(result.prepack.magnitude == total && result.iterations == terms &&
        result.prepack.fractional_bits == W && result.prepack.scale == x.scale+y.scale &&
        result.prepack.sign == (x.sign != y.sign) && !result.prepack.numerical_sticky &&
        result.prepack.term_cut == tail, "independent recurrence mismatch");
    return {result.prepack, result.iterations};
}
Eval evaluate(unsigned w, uint32_t a, uint32_t b, unsigned n) {
    switch (w) {
        case 8: return model<8>(a,b,n); case 10: return model<10>(a,b,n);
        case 12: return model<12>(a,b,n); case 14: return model<14>(a,b,n);
        case 16: return model<16>(a,b,n); case 18: return model<18>(a,b,n);
        case 20: return model<20>(a,b,n); case 24: return model<24>(a,b,n);
        case 26: return model<26>(a,b,n);
    }
    throw std::invalid_argument("unsupported survey width");
}
struct Stats {
    unsigned width, budget;
    std::string policy;
    uint64_t matches=0, cut=0, iterations=0, max_distance=0, in_range=0;
    long double in_range_error_sum=0;
    std::vector<long double> internal, output;
    std::array<uint64_t,LIMITS.size()> cdf{};
    uint32_t worst_a=0, worst_b=0, worst_out=0, worst_ref=0;
    long double worst=-1;
    void add(uint32_t a, uint32_t b, uint32_t reference, long double ideal,
             const l1::PrepackProduct& p, unsigned terms, bool was_cut) {
        const uint32_t packed = week11::dyadic<32,3>(p);
        require(packed == l1::pack<32,3>(week11::normalize<32,3>(p)), "prepack-preserving RNE mismatch");
        const long double raw = std::ldexp(static_cast<long double>(p.magnitude),
            p.scale-int(p.fractional_bits)) * (p.sign ? -1 : 1);
        const long double e = 100 * std::fabs((real(packed)-ideal)/ideal);
        const long double ep = 100 * std::fabs((raw-ideal)/ideal);
        require(std::isfinite(e) && std::isfinite(ep), "nonfinite error");
        internal.push_back(ep); output.push_back(e);
        matches += packed == reference; iterations += terms; cut += was_cut;
        const uint64_t distance=uint64_t(std::llabs(rank(packed)-rank(reference)));
        max_distance=std::max(max_distance,distance);
        const long double mag=std::fabs(ideal);
        if (mag >= std::ldexp(1.L,-240) && mag <= std::ldexp(1.L,240)) {
            ++in_range; in_range_error_sum += e;
        }
        for (unsigned j=0;j<LIMITS.size();++j) cdf[j] += e < LIMITS[j];
        if (e>worst) { worst=e; worst_a=a; worst_b=b; worst_out=packed; worst_ref=reference; }
    }
};
long double percentile(const std::vector<long double>& sorted, long double p) {
    return sorted[std::max(size_t(1),size_t(std::ceil(p*sorted.size())))-1];
}
long double mean(const std::vector<long double>& values) {
    long double sum=0; for (auto x:values) sum+=x; return sum/values.size();
}
void print(std::ostream& csv, const std::string& group, uint64_t hash, Stats& s) {
    std::sort(s.internal.begin(),s.internal.end());
    std::sort(s.output.begin(),s.output.end());
    const auto count=s.output.size();
    csv << group << ',' << s.width << ',' << s.policy << ',' << s.budget << ',' << count
        << ',' << std::hex << hash << std::dec << ',' << s.matches << ',' << 100.L*s.matches/count
        << ',' << mean(s.internal) << ',' << percentile(s.internal,.5L)
        << ',' << percentile(s.internal,.95L) << ',' << percentile(s.internal,.99L) << ',' << s.internal.back()
        << ',' << mean(s.output) << ',' << percentile(s.output,.5L)
        << ',' << percentile(s.output,.95L) << ',' << percentile(s.output,.99L) << ',' << s.output.back()
        << ',' << s.in_range << ',' << (s.in_range?s.in_range_error_sum/s.in_range:0)
        << ',' << static_cast<long double>(s.iterations)/count << ',' << s.cut << ',' << s.max_distance;
    for (auto x:s.cdf) csv << ',' << x;
    csv << ',' << std::hex << s.worst_a << ',' << s.worst_b << ',' << s.worst_out
        << ',' << s.worst_ref << std::dec << '\n';
}
void fingerprint(uint64_t& hash,uint32_t raw) {
    for (unsigned byte=0;byte<4;++byte) { hash^=(raw>>(8*byte))&255; hash*=1099511628211ULL; }
}
uint32_t operand(uint64_t& rng, unsigned group) {
    if (group==0) {
        const uint32_t mag=0x40000000u | (uint32_t(next(rng))&0x03ffffffu);
        return (next(rng)&1) ? 0u-mag : mag; // |A| in [1,2), 26 available fraction bits.
    }
    if (group==1) {
        l1::PrepackProduct p;
        p.magnitude=(uint64_t(1)<<F)|(next(rng)&((uint64_t(1)<<F)-1));
        p.scale=int(next(rng)&63)-32;
        p.fractional_bits=F; p.sign=next(rng)&1;
        return week11::dyadic<32,3>(p); // RNE conversion, then evaluate actual Posit inputs.
    }
    uint32_t raw;
    do { raw=uint32_t(next(rng)); } while (!raw || raw==NAR);
    return raw;
}
void special_checks() {
    const std::array<uint32_t,7> values{0,NAR,1,0x7fffffff,0xffffffff,0x40000000,0xc0000000};
    for (auto a:values) for (auto b:values) {
        l1::IterConfig cfg; cfg.ops=1; cfg.rounding=l1::RoundMode::RNE; cfg.n=8;
        const auto result=l1::L1MultiplierIter<32,3,12>::mul(a,b,cfg);
        if (!a || !b || a==NAR || b==NAR)
            require(result.bits == ((a==NAR || b==NAR)?NAR:0),"special case mismatch");
        const auto exact=l1::L1MultiplierIter<32,3,12>::mul(a,b,[]{
            l1::IterConfig c; c.exact=true; c.rounding=l1::RoundMode::RNE; return c;
        }());
        require(week11::dyadic<32,3>(exact.prepack)==exact_reference<32,3>(a,b),"directed exact oracle mismatch");
    }
}
} // namespace survey

int main(int argc,char** argv) try {
    using namespace survey;
    if (argc!=4) throw std::invalid_argument("usage: fraction_survey samples_per_group seed output.csv");
    const uint64_t samples=std::stoull(argv[1]), seed=std::stoull(argv[2]);
    if (!samples || std::numeric_limits<long double>::digits<64)
        throw std::invalid_argument("positive sample count and >=64-bit long-double significand required");
    special_checks();
    std::ofstream csv(argv[3]);
    if (!csv) throw std::runtime_error("cannot open CSV");
    csv << std::setprecision(18);
    csv << "group,width,policy,budget,samples,corpus_fnv1a,matches,match_pct,pre_mean_pct,pre_p50_pct,pre_p95_pct,pre_p99_pct,pre_max_pct,out_mean_pct,out_p50_pct,out_p95_pct,out_p99_pct,out_max_pct,in_range_samples,in_range_mean_pct,mean_iterations,iteration_cut,max_code_distance";
    for (auto x:LIMITS) csv << ",lt_" << x << "_pct_count";
    csv << ",worst_a_hex,worst_b_hex,worst_out_hex,worst_ref_hex\n";
    const std::array<std::string,3> groups{"near_one","balanced_scale","uniform_bits"};
    for (unsigned group=0;group<groups.size();++group) {
        std::vector<Stats> rows;
        for (auto w:WIDTHS) {
            for (unsigned n:{2u,4u,8u}) rows.push_back(Stats{w,n,"n"+std::to_string(n),0,0,0,0,0,0,{},{},{}});
            rows.push_back(Stats{w,w,"full",0,0,0,0,0,0,{},{},{}});
            rows.push_back(Stats{w,0,"input_only",0,0,0,0,0,0,{},{},{}});
        }
        rows.push_back(Stats{F,F,"exact",0,0,0,0,0,0,{},{},{}});
        uint64_t rng=seed+group*0x100000001b3ULL,hash=14695981039346656037ULL;
        for (uint64_t i=0;i<samples;++i) {
            const uint32_t a=operand(rng,group), b=operand(rng,group);
            fingerprint(hash,a); fingerprint(hash,b);
            const auto da=decode(a),db=decode(b);
            const long double ideal=real(a)*real(b);
            const uint32_t reference=exact_reference<32,3>(a,b);
            l1::IterConfig config; config.exact=true; config.ops=1; config.rounding=l1::RoundMode::RNE;
            const auto exact=l1::L1MultiplierIter<32,3,12>::mul(a,b,config);
            require(week11::dyadic<32,3>(exact.prepack)==reference,"exact source/oracle mismatch");
            for (auto& row:rows) {
                if (row.policy=="exact") {
                    row.add(a,b,reference,ideal,exact.prepack,exact.iterations,false);
                } else if (row.policy=="input_only") {
                    l1::PrepackProduct p;
                    p.magnitude=(da.sig>>(F-row.width))*(db.sig>>(F-row.width));
                    p.fractional_bits=2*row.width; p.scale=da.scale+db.scale; p.sign=da.sign!=db.sign;
                    row.add(a,b,reference,ideal,p,0,false);
                } else {
                    const auto m=evaluate(row.width,a,b,row.budget);
                    const uint64_t mask=(uint64_t(1)<<row.width)-1;
                    const unsigned pops=std::min(population((da.sig>>(F-row.width))&mask),population((db.sig>>(F-row.width))&mask));
                    row.add(a,b,reference,ideal,m.p,m.iterations,pops>row.budget);
                }
            }
        }
        for (auto& row:rows) print(csv,groups[group],hash,row);
        csv.flush();
        std::cout << "GROUP COMPLETE " << groups[group] << " samples=" << samples
            << " corpus_fnv1a=" << std::hex << hash << std::dec << '\n';
    }
    std::cout << "COMPLETE independent_checks=" << checks << " mismatches=0 seed=" << seed
        << " samples_per_group=" << samples << " long_double_digits="
        << std::numeric_limits<long double>::digits << '\n';
    return 0;
} catch(const std::exception& e) { std::cerr << "FAIL " << e.what() << '\n'; return 1; }
