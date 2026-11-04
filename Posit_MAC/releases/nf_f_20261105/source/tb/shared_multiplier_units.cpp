#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include "verilated.h"
#include "Vshared_multiplier_units.h"

static void check(bool ok, const char* stage, uint64_t index) {
    if (!ok) throw std::runtime_error(std::string(stage)+" mismatch at "+std::to_string(index));
}
static uint32_t rng(uint64_t& state) {
    state ^= state << 13; state ^= state >> 7; state ^= state << 17;
    return uint32_t(state);
}
int main(int argc, char** argv) {
    try {
        Verilated::commandArgs(argc,argv);
        Vshared_multiplier_units d;
        constexpr uint32_t mask26 = (1u<<26)-1;
        uint64_t ops=0,metadata=0,sac=0,shift=0,acc=0,norm=0;
        for (unsigned a=0;a<4096;++a) for (unsigned b=0;b<4096;++b) {
            d.op_a=a; d.op_b=b;
            d.op_sa=a&1; d.op_sb=b&1;
            const int sfa=int(a%481)-240, sfb=int(b%481)-240;
            d.op_sfa=unsigned(sfa)&2047; d.op_sfb=unsigned(sfb)&2047;
            for (unsigned mode=0;mode<2;++mode) {
                d.op_mode=mode; d.eval();
                const bool swap=mode && __builtin_popcount(b)<__builtin_popcount(a);
                check(d.op_x==(swap?b:a) && d.op_y==4096+(swap?a:b)
                    && d.op_sign==((a^b)&1) && d.op_sf==(unsigned(sfa+sfb)&2047),"OPS",ops++);
            }
        }
        // Independent metadata paths: exhaustive sign/scale buses and both OPS
        // settings, separate from the exhaustive fraction-pair sweep above.
        d.op_a=0xaaa; d.op_b=0x555;
        for (unsigned a=0;a<2048;++a) for (unsigned b=0;b<2048;++b)
            for (unsigned signs=0;signs<4;++signs) for (unsigned mode=0;mode<2;++mode) {
                d.op_sfa=a; d.op_sfb=b; d.op_sa=signs&1; d.op_sb=signs>>1;
                d.op_mode=mode; d.eval();
                check(d.op_x==0xaaa && d.op_y==0x1555 && d.op_sign==((signs^(signs>>1))&1)
                    && d.op_sf==((a+b)&2047),"OPS_METADATA",metadata++);
            }
        for (unsigned fx=0;fx<4096;++fx) for (unsigned s=0;s<16;++s) {
            d.sac_fx=fx; d.sac_scale=s; d.eval();
            unsigned amount=0;
            if (fx) { amount=1; while (!(fx&(1u<<(12-amount)))) ++amount; }
            const unsigned next=fx?((fx<<amount)&4095):0;
            check(d.sac_next==next && d.sac_next_scale==((s+amount)&15)
                && d.sac_exhausted==((fx&(fx-1))==0)
                && d.sac_error==(s>12 || (fx && s+amount>12)),"SAC",sac++);
        }
        for (unsigned y=0;y<8192;++y) for (unsigned s=0;s<16;++s)
            for (unsigned init=0;init<2;++init) {
                d.shift_y=y; d.shift_scale=s; d.shift_init=init; d.eval();
                check(d.shift_base==(y<<12) && d.shift_term==(init?0:(y<<12)>>s),"SBM",shift++);
            }
        uint64_t state=20261102;
        for (unsigned i=0;i<1000000;++i) {
            d.acc_first=i&1; d.acc_base=rng(state)&mask26;
            d.acc_previous=rng(state)&mask26; d.acc_term=rng(state)&mask26;
            if (i<8) { d.acc_previous=mask26; d.acc_base=mask26; d.acc_term=i; }
            d.eval();
            const uint64_t sum=uint64_t(d.acc_first?d.acc_base:d.acc_previous)+d.acc_term;
            check(d.acc_next==(sum&mask26) && d.acc_overflow==(sum>>26),"ACC",acc++);
        }
        d.norm_sf=0; d.norm_sf_inc=1;
        // Exhaust the full magnitude bus, including all bit patterns at carry.
        for (uint32_t m=0;m<(1u<<26);++m) {
            d.norm_m=m; d.eval();
            const unsigned carry=m>>25;
            const uint32_t fraction=carry?((m&((1u<<25)-1))<<1):((m&((1u<<24)-1))<<2);
            check(d.norm_fraction==fraction && d.norm_out_sf==carry,"NORMALIZE",norm++);
        }
        for (unsigned a=0;a<2048;++a) for (unsigned b=0;b<2048;++b)
            for (unsigned carry=0;carry<2;++carry) {
                d.norm_sf=a; d.norm_sf_inc=b; d.norm_m=carry?1u<<25:1u<<24; d.eval();
                check(d.norm_out_sf==(carry?b:a),"NORMALIZE_SCALE",norm++);
            }
        const std::string report=std::string("{\"status\":\"PASS\",\"mismatches\":0,\"ops\":")+std::to_string(ops)
            +",\"ops_metadata\":"+std::to_string(metadata)+",\"sac\":"+std::to_string(sac)+",\"sbm\":"+std::to_string(shift)
            +",\"accumulator\":"+std::to_string(acc)+",\"normalizer\":"+std::to_string(norm)
            +",\"claim\":\"Exhaustive OPS fraction/mode and sign/scale domains separately; exhaustive SAC/SBM buses; normalizer magnitude and scale domains separately; accumulator sampled with directed overflow. Not Cartesian metadata-times-fraction or exhaustive whole MAC.\"}";
        if (argc>1) std::ofstream(argv[1]) << report << '\n';
        std::cout << report << '\n'; d.final();
    } catch (const std::exception& e) { std::cerr<<e.what()<<'\n'; return 1; }
}
