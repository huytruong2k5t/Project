#include <algorithm>
#include <array>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>
#include "verilated.h"
#if VM_COVERAGE
#include "verilated_cov.h"
#endif
#include "Vquire_checker.h"
#include "posit_quire.hpp"
#include "quire_reference.hpp"

static void require(bool ok,const std::string& message) { if(!ok)throw std::runtime_error(message); }
static uint64_t mix(uint64_t x) {
    x+=0x9e3779b97f4a7c15ull;x=(x^(x>>30))*0xbf58476d1ce4e5b9ull;
    x=(x^(x>>27))*0x94d049bb133111ebull;return x^(x>>31);
}
class Test {
public:
    VerilatedContext context;
    Vquire_checker d{&context};
    quire32::Model model;
    quire_reference::Oracle oracle;
    uint64_t cycles=0,accepted=0,retired=0,aborted=0,commits=0,core_checks=0;
    uint64_t stalls=0,invalid_checks=0,sequences=0,long_sequences=0,capacity_sequences=0;
    uint64_t latency_min=UINT64_MAX,latency_max=0;
    std::array<uint64_t,3> accepted_cmd{},retired_cmd{},aborted_cmd{};
    std::array<uint64_t,26> config_bins{};
    std::array<uint64_t,32> flag_bins{};
    uint64_t random;
    bool trace_enabled=true;
    std::ofstream traces;
    explicit Test(uint64_t seed,const std::string& path):random(seed),traces(path) {
        d.clk=0;d.rst_n=0;d.in_valid=0;d.out_ready=0;d.q_cmd=0;
        d.a=0;d.b=0;d.cfg_n=12;d.cfg_ops=1;d.eval();reset();
    }
    uint64_t next(){return random=mix(random);}
    void advance(uint64_t amount) {
        const uint64_t end=context.time()+amount;
        while(d.eventsPending()&&d.nextTimeSlot()<=end) {
            context.timeInc(d.nextTimeSlot()-context.time());d.eval();
        }
        context.timeInc(end-context.time());d.eval();
    }
    void clock(){advance(5000);d.clk=1;d.eval();advance(5000);d.clk=0;d.eval();++cycles;}
    void reset() {
        d.rst_n=0;d.in_valid=0;d.out_ready=0;d.eval();
        require(!d.in_ready&&!d.out_valid,"reset interface gates");
        for(unsigned i=0;i<5;++i)clock();
        model.clear();oracle.clear();d.rst_n=1;d.eval();
        for(unsigned i=0;i<12;++i)clock();
        d.q_cmd=0;d.eval();require(d.in_ready&&!d.out_valid,"startup ready");check_state();
    }
    void check_state() {
        const auto raw=oracle.raw();
        require(model.q==raw,"L1/oracle Q");
        for(unsigned i=0;i<31;++i)if(d.q_value[i]!=raw[i])
            throw std::runtime_error("RTL Q word="+std::to_string(i)+" at command="+std::to_string(accepted));
        require(d.q_count==model.count&&model.count==oracle.count,"count");
        require(bool(d.q_nar)==model.nar&&!d.q_invalid&&!d.q_overflow,"persistent status");
        require(bool(d.q_loss)==model.loss&&bool(d.q_cut)==model.cut,"chain loss");
    }
    void reject(unsigned cmd,unsigned n,unsigned ops) {
        d.q_cmd=cmd;d.cfg_n=n;d.cfg_ops=ops;d.in_valid=1;d.out_ready=1;
        for(unsigned i=0;i<4;++i) {
            d.eval();require(!d.in_ready&&!d.out_valid,"invalid accepted");clock();++invalid_checks;check_state();
        }
        d.in_valid=0;d.cfg_n=12;d.cfg_ops=1;d.q_cmd=0;d.eval();
    }
    // abort=1 before bank commit,2 held response,3 immediately after bank commit.
    uint32_t tx(unsigned cmd,uint32_t a=0,uint32_t b=0,unsigned n=12,unsigned ops=1,unsigned abort=0) {
        auto next_model=model;auto next_oracle=oracle;
        if(cmd==0){next_model.clear();next_oracle.clear();}
        else if(cmd==1){next_model.mac(a,b,n,ops);next_oracle.mac(a,b,n,ops);}
        const auto expected=cmd==2?model.read():next_model.ack();
        const auto ref=cmd==2?oracle.read():std::make_pair(0u,next_oracle.ack_flags());
        require(expected.bits==ref.first&&expected.flags==ref.second,"L1/oracle response");
        d.q_cmd=cmd;d.a=a;d.b=b;d.cfg_n=n;d.cfg_ops=ops;d.in_valid=1;d.out_ready=0;d.eval();
        bool active=false,committed=false,held=false;
        uint64_t began=0,payload=0,hold_payload=0;
        unsigned held_cycles=0;
        for(unsigned timeout=0;timeout<400;++timeout) {
            d.out_ready=abort?0:((next()%5)!=0);
            d.eval();
            if(held)require(d.out_valid&&((uint64_t(d.out_cmd)<<40)|(uint64_t(d.flags)<<32)|d.d)==hold_payload,"response hold");
            if(!active&&d.in_valid&&d.in_ready) {
                active=true;began=cycles;++accepted;++accepted_cmd[cmd];
                if(cmd==1)++config_bins[ops*13+n];
            }
            const bool response=d.out_valid;
            const bool retire=response&&d.out_ready;
            if(response) {
                require(active&&d.out_cmd==cmd,"response ordering");
                if(d.d!=expected.bits||d.flags!=expected.flags||d.q_overflow)
                    throw std::runtime_error("READ/ACK at command="+std::to_string(accepted)+" expected="+std::to_string(expected.bits)+" actual="+std::to_string(d.d));
                payload=(uint64_t(d.out_cmd)<<40)|(uint64_t(d.flags)<<32)|d.d;
                if(!d.out_ready){++stalls;++held_cycles;}
            }
            held=response&&!d.out_ready;hold_payload=payload;
            clock();
            if(d.bank_commit) {
                require(active&&cmd!=2&&!committed,"unexpected/double bank commit");
                committed=true;++commits;model=next_model;oracle=next_oracle;check_state();
            }
            if(d.core_done) {
                require(cmd==1&&active,"stray core done");
                const auto p=opt17_reference::product(a,b,{true,n,ops});
                require(d.core_magnitude==p.magnitude&&bool(d.core_cut)==p.iteration_cut
                     &&bool(d.core_input_cut)==p.input_cut&&bool(d.core_sign)==p.sign,"core product/context");
                const int sf=(d.core_scale&1024)?int(d.core_scale)-2048:int(d.core_scale);
                require(sf==p.scale&&d.core_iterations<=n&&!d.core_error,"core scale/iteration");++core_checks;
            }
            if(active) {
                // Live input changes must not corrupt the accepted command.
                d.in_valid=0;d.a=uint32_t(next());d.b=uint32_t(next());
                d.q_cmd=3;d.cfg_n=15;d.cfg_ops=3;d.eval();
            }
            if(active&&((abort==1&&cycles-began==3)
                      ||(abort==2&&held_cycles==4)||(abort==3&&committed))) {
                ++aborted;++aborted_cmd[cmd];reset();return 0;
            }
            if(retire) {
                require(cmd==2||committed,"ACK before commit");
                ++retired;++retired_cmd[cmd];++flag_bins[expected.flags];
                latency_min=std::min(latency_min,cycles-began);latency_max=std::max(latency_max,cycles-began);
                check_state();
                if(cmd==0){++sequences;}
                if(cmd==2&&trace_enabled) {
                    traces<<std::hex<<a<<' '<<b<<' '<<expected.bits<<' '<<expected.flags<<' ';
                    for(int i=30;i>=0;--i){traces.width(i==30?3:8);traces.fill('0');traces<<model.q[unsigned(i)];}
                    traces<<'\n';
                }
                return expected.bits;
            }
        }
        throw std::runtime_error("command timeout cmd="+std::to_string(cmd)+" accepted="+std::to_string(active));
    }
    void clear_sequence() {
        if(model.count>12)++long_sequences;
        if(model.count==1024)++capacity_sequences;
        tx(0);
    }
};
int main(int argc,char**argv) {
    try {
        require(argc==4||argc==5,"MAC_TARGET FIXED_CONFIG(0|1) REPORT [SEED] required");
        const uint64_t target=std::stoull(argv[1]);const bool fixed=std::stoi(argv[2])!=0;
        const uint64_t seed=argc==5?std::stoull(argv[4]):20261103;
        Test t(seed,std::string(argv[3])+".reads");
        const uint32_t one=0x40000000u;
        t.reject(3,12,1);
        for(unsigned n=13;n<16;++n)t.reject(1,n,1);
        for(unsigned op=2;op<4;++op)t.reject(1,12,op);
        t.tx(0,0,0,15,3);t.tx(2,0,0,15,3); // config ignored for non-MAC
        t.tx(1,one,one);for(unsigned i=0;i<3;++i)t.tx(1,0x14000000u,0x14000000u);
        require(t.tx(2)==0x40000001u,"TC-Q-NOROUND");
        t.tx(2);t.clear_sequence();
        t.tx(1,0,0x80000000u);t.tx(1,one,one);require(t.tx(2)==0x80000000u,"NaR priority/persistence");t.clear_sequence();
        t.tx(1,one,one,12,1,1);t.tx(1,one,one,12,1,3);t.tx(1,one,one,12,1,2);
        t.tx(1,one,one);t.tx(2,0,0,12,1,1);t.tx(1,one,one);t.tx(2,0,0,12,1,2);
        for(uint32_t code:{1u,0x7fffffffu,0xffffffffu,0x80000001u}) {
            t.clear_sequence();
            for(unsigned i=0;i<1024;++i)t.tx(1,code,0x7fffffffu);
            t.tx(2);t.reject(1,12,1);t.tx(2);t.clear_sequence();
        }
        // Retain a small term while an enormous opposite pair cancels exactly.
        t.tx(1,0x7fffffffu,0x7fffffffu);t.tx(1,1,1);t.tx(1,0x80000001u,0x7fffffffu);
        require(t.tx(2)==1,"large/small cancellation");t.clear_sequence();
        // Directed config sweep, separate from the default-only main criterion.
        for(unsigned op=0;op<2;++op)for(unsigned n=0;n<13;++n) {
            t.tx(1,0x43fffc00u,0x45fffc00u,n,op);t.tx(2);t.clear_sequence();
        }
        // Explicitly cover every raw regime/LOD position, both signs/polarities.
        for(unsigned i=0;i<31;++i)for(unsigned sign=0;sign<2;++sign) {
            uint32_t code=uint32_t(1)<<i;if(sign)code=0u-code;
            t.tx(1,code,one);t.tx(2);t.clear_sequence();
            code=uint32_t((uint64_t(1)<<(i+1))-1);if(sign)code=0u-code;
            t.tx(1,one,code);t.tx(2);t.clear_sequence();
        }
        t.trace_enabled=false;
        const auto before=t.retired_cmd[1];uint64_t main_mac=0;
        unsigned remaining=0;
        while(main_mac<target) {
            if(!remaining||t.model.count==1024) {
                t.tx(2);t.clear_sequence();remaining=13+unsigned(t.next()%1012);
            }
            const auto a=uint32_t(t.next()),b=uint32_t(t.next());
            const unsigned n=fixed?12:unsigned(t.next()%13),ops=fixed?1:unsigned(t.next()%2);
            t.tx(1,a,b,n,ops);--remaining;++main_mac;
            if((main_mac&127)==0)t.tx(2);
            if((main_mac%100000)==0)std::cout<<"QUIRE_PROGRESS "<<main_mac<<'\n'<<std::flush;
        }
        t.tx(2);t.clear_sequence();
        require(t.retired_cmd[1]-before==target,"MAC target accounting");
        require(t.accepted==t.retired+t.aborted,"accepted=retired+aborted");
        t.d.in_valid=0;t.d.out_ready=1;
        for(unsigned i=0;i<10;++i){t.clock();require(!t.d.out_valid,"duplicate response after drain");}
        std::ofstream out(argv[3]);
        out<<"{\"status\":\"PASS\",\"mismatches\":0,\"seed\":"<<seed<<",\"main_default_only\":"<<(fixed?"true":"false")
           <<",\"main_mac_retired\":"<<main_mac<<",\"accepted\":"<<t.accepted<<",\"retired\":"<<t.retired
           <<",\"reset_aborted\":"<<t.aborted<<",\"bank_commits_including_clear\":"<<t.commits<<",\"core_checks\":"<<t.core_checks
           <<",\"cycles\":"<<t.cycles<<",\"stalls\":"<<t.stalls<<",\"invalid_checks\":"<<t.invalid_checks
           <<",\"clear_sequences\":"<<t.sequences<<",\"long_sequences\":"<<t.long_sequences
           <<",\"capacity_sequences\":"<<t.capacity_sequences<<",\"latency_retire\":["<<t.latency_min<<','<<t.latency_max<<"],\"config_bins\":[";
        for(unsigned i=0;i<26;++i){if(i)out<<',';out<<t.config_bins[i];}out<<"],\"flag_bins\":[";
        for(unsigned i=0;i<32;++i){if(i)out<<',';out<<t.flag_bins[i];}out<<"]}\n";
        #if VM_COVERAGE
        t.context.coveragep()->write((std::string(argv[3])+".dat").c_str());
        #endif
        t.d.final();std::cout<<"QUIRE_RTL_PASS main_mac="<<main_mac<<" cycles="<<t.cycles<<" mismatches=0\n";
    }catch(const std::exception&e){std::cerr<<e.what()<<'\n';return 1;}
}
