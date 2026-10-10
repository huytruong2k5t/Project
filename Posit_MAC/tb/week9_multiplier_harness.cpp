// Verilator path-A harness. Fixture expectations were checked against L1,
// SoftPosit (ES0/1/2 exact RNE), and an independent ES3 integer/bit-list oracle.
// Execution evidence is recorded by verify_week9_verilator.sh; fixtures are frozen.
// Each input is checked directly against L1; exact/RNE also calls L0 or ES3 oracle.
#include <fstream>
#include <iostream>
#include <stdexcept>
#include "verilated.h"
#if VM_COVERAGE
#include "verilated_cov.h"
#endif
#include "Vposit_mul_iter.h"
#include "l1/l1_multiplier_iter.hpp"
#include "softposit_api.h"
#include "week9_exact_reference.hpp"
#ifndef PROFILE_ROUNDING
#define PROFILE_ROUNDING 0
#endif

void tick(Vposit_mul_iter& top) {
    top.clk=0; top.eval();
    top.clk=1; top.eval();
    top.clk=0; top.eval();
}
void require(bool condition,const char* message) {
    if(!condition) throw std::runtime_error(message);
}
void reset(Vposit_mul_iter& top) {
    top.rst_n=0; top.in_valid=0; top.out_ready=1;
    tick(top); tick(top);
    require(!top.in_ready && !top.out_valid,"reset flush");
    top.rst_n=1; top.out_ready=0;
    for(unsigned k=0;k<3;++k) {
        require(!top.in_ready,"startup barrier");
        tick(top);
    }
    require(top.in_ready,"startup release");
}
int main(int argc,char** argv) {
    Verilated::commandArgs(argc,argv);
    if(argc!=2 && argc!=3) return 2;
    try {
        Vposit_mul_iter top;
        top.clk=0; top.rst_n=0; top.a=0; top.b=0; top.in_valid=0;
        top.cfg_mode=0; top.cfg_n=0; top.cfg_ops=0; top.out_ready=0;
        top.eval(); reset(top);
        std::ifstream file(argv[1]);
        require(bool(file),"missing fixture");
        // Reserved OPS and excessive approximate iteration count must be rejected.
        top.in_valid=1; top.cfg_ops=2;
        for(unsigned k=0;k<3;++k) { tick(top); require(!top.in_ready,"reserved config accepted"); }
        top.cfg_ops=0; top.cfg_mode=1; top.cfg_n=9;
        for(unsigned k=0;k<3;++k) { tick(top); require(!top.in_ready,"invalid n accepted"); }
        top.in_valid=0; top.cfg_mode=0; top.cfg_n=0;
        uint64_t row=0,completed=0,aborted=0,long_stalls=0;
        uint64_t l1_checks=0,l0_checks=0,es3_checks=0;
        uint64_t a,b,mode,n,ops,bits,flags,iterations;
        while(file>>std::hex>>a) {
            require(bool(file>>b>>mode>>n>>ops>>bits>>flags>>iterations),"malformed fixture");
            l1::IterConfig cfg;
            cfg.exact=(mode==0); cfg.n=unsigned(n); cfg.ops=unsigned(ops);
            cfg.scheme=PROFILE_SCHEME ? l1::ShiftRound::STICKY_ACC : l1::ShiftRound::FLOOR;
            cfg.rounding=PROFILE_ROUNDING ? l1::RoundMode::TRUNC : l1::RoundMode::RNE;
            const auto expected=l1::L1MultiplierIter<PROFILE_NB,PROFILE_ES,PROFILE_FRAC_W>::mul(
                static_cast<l1::posit_storage_t<PROFILE_NB>>(a),
                static_cast<l1::posit_storage_t<PROFILE_NB>>(b),cfg);
            unsigned expected_flags=0;
            const auto& unpacked=expected.unpacked;
            if(unpacked.is_nar) expected_flags=16;
            else if(!unpacked.is_zero) {
                constexpr int limit=(PROFILE_NB-2)*(1<<PROFILE_ES);
                const bool high=unpacked.sf>limit || (unpacked.sf==limit &&
                    (unpacked.frac!=(uint64_t(1)<<63) || !unpacked.exact));
                expected_flags=(high?8:0)|(unpacked.sf < -limit?4:0)|
                    (expected.inexact?2:0)|(expected.approx_cut?1:0);
            }
            require(expected.bits==bits && expected_flags==flags &&
                    expected.iterations==iterations,"fixture/direct L1 mismatch");
            ++l1_checks;
            if(cfg.exact && !PROFILE_ROUNDING) {
                uint32_t reference;
                if constexpr(PROFILE_NB==8) reference=l0_p8_mul(uint8_t(a),uint8_t(b));
                else if constexpr(PROFILE_NB==16) reference=l0_p16_mul(uint16_t(a),uint16_t(b));
                else if constexpr(PROFILE_ES==2) reference=l0_p32_mul(uint32_t(a),uint32_t(b));
                else reference=exact_reference<PROFILE_NB,PROFILE_ES>(uint32_t(a),uint32_t(b));
                require(expected.bits==reference,"L1/exact oracle mismatch");
                if constexpr(PROFILE_ES==3) ++es3_checks; else ++l0_checks;
            }
            top.a=a; top.b=b; top.cfg_mode=mode; top.cfg_n=n; top.cfg_ops=ops;
            top.in_valid=1; top.out_ready=0; top.eval();
            require(top.in_ready,"input not ready");
            tick(top);
            top.a=~a; top.b=~b; top.cfg_mode=!mode; top.cfg_n=15-n; top.cfg_ops=0;
            if(row%211==100) {
                for(unsigned k=0;k<row%31;++k) tick(top);
                top.cfg_mode=0; top.cfg_n=0;
                reset(top);
                for(unsigned k=0;k<40;++k) {tick(top);require(!top.out_valid,"ghost output");}
                ++aborted;
            } else {
                unsigned cycles=0;
                while(!top.out_valid) {
                    tick(top); ++cycles;
                    require(!top.in_ready,"slot overwrite");
                    require(cycles<=50,"result timeout");
                }
                require(cycles==(iterations?iterations:1)+6+!PROFILE_ROUNDING,"latency");
                if(top.d!=bits || top.flags!=flags) {
                    std::cerr<<"first mismatch row="<<std::dec<<row<<" a="<<std::hex<<a
                        <<" b="<<b<<" result="<<top.d<<" expected="<<bits
                        <<" flags="<<unsigned(top.flags)<<" expected_flags="<<flags<<'\n';
                    throw std::runtime_error("RTL/L1 mismatch");
                }
                unsigned stall_cycles=(row%97==7)?96:row%5;
                if(stall_cycles==96) ++long_stalls;
                for(unsigned k=0;k<stall_cycles;++k) {
                    tick(top);
                    require(top.out_valid && !top.in_ready && top.d==bits && top.flags==flags,"stall stability");
                }
                top.in_valid=0; top.out_ready=1; tick(top);
                require(!top.out_valid,"duplicate output");
                ++completed;
            }
            ++row;
            if(row%100000==0) std::cout<<"VERILATOR PROGRESS rows="<<row<<std::endl;
        }
        require(file.eof(),"invalid fixture token");
        top.final();
#if VM_COVERAGE
        require(argc==3,"missing coverage output path");
        VerilatedCov::write(argv[2]);
#endif
        require(row>0,"empty fixture");
        std::cout<<"VERILATOR MULTIPLIER PASS rows="<<row<<" completed="<<completed
            <<" reset_aborts="<<aborted<<" long_stalls="<<long_stalls<<" mismatches=0 L1_checks="<<l1_checks<<" L0_checks="<<l0_checks
            <<" ES3_checks="<<es3_checks<<"\n";
    } catch(const std::exception& e) {
        std::cerr<<e.what()<<'\n';
        return 1;
    }
}
