// Verilator path-A harness. Fixture expectations were checked against L1,
// SoftPosit (ES0/1/2 exact RNE), and an independent ES3 integer/bit-list oracle.
// Awaiting an installed Verilator: do not count this as executed RTL evidence.
#include <fstream>
#include <iostream>
#include <stdexcept>
#include "verilated.h"
#include "Vposit_mul_iter.h"
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
    if(argc!=2) return 2;
    try {
        Vposit_mul_iter top;
        top.clk=0; top.rst_n=0; top.a=0; top.b=0; top.in_valid=0;
        top.cfg_mode=0; top.cfg_n=0; top.cfg_ops=0; top.out_ready=0;
        top.eval(); reset(top);
        std::ifstream file(argv[1]);
        require(bool(file),"missing fixture");
        uint64_t row=0,completed=0,aborted=0;
        uint64_t a,b,mode,n,ops,bits,flags,iterations;
        while(file>>std::hex>>a) {
            require(bool(file>>b>>mode>>n>>ops>>bits>>flags>>iterations),"malformed fixture");
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
                for(unsigned k=0;k<row%5;++k) {
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
        top.final();
        require(row>0,"empty fixture");
        std::cout<<"VERILATOR MULTIPLIER PASS rows="<<row<<" completed="<<completed
            <<" reset_aborts="<<aborted<<" mismatches=0\n";
    } catch(const std::exception& e) {
        std::cerr<<e.what()<<'\n';
        return 1;
    }
}
