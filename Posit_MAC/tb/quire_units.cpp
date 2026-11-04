#include <array>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include "verilated.h"
#if VM_COVERAGE
#include "verilated_cov.h"
#endif
#include "Vquire_units.h"
#include "posit_quire.hpp"
#include "quire_reference.hpp"

static void require(bool x,const std::string& m){if(!x)throw std::runtime_error(m);}
static uint64_t mix(uint64_t x){x+=0x9e3779b97f4a7c15ull;x=(x^(x>>30))*0xbf58476d1ce4e5b9ull;x=(x^(x>>27))*0x94d049bb133111ebull;return x^(x>>31);}
int main(int argc,char**argv) {
    try {
        require(argc==2,"report required");
        VerilatedContext context;Vquire_units d(&context);
        auto advance=[&](uint64_t amount) {
            const auto end=context.time()+amount;
            while(d.eventsPending()&&d.nextTimeSlot()<=end){context.timeInc(d.nextTimeSlot()-context.time());d.eval();}
            context.timeInc(end-context.time());d.eval();
        };
        auto clock=[&](){advance(5000);d.clk=1;d.eval();advance(5000);d.clk=0;d.eval();};
        d.clk=0;d.reset_n=0;d.bank_valid=0;d.read_valid=0;d.out_ready=1;d.clear=0;
        d.term_nar=0;d.term_invalid=0;d.term_loss=0;d.term_cut=0;d.magnitude=0;d.sign=0;d.sf=0;
        d.read_nar=0;d.read_invalid=0;d.read_loss=0;d.read_cut=0;
        d.bank_coefficient=0;d.bank_index=0;d.bank_offset=0;d.bank_zero=1;
        for(unsigned i=0;i<31;++i)d.read_q[i]=0;
        d.eval();for(unsigned i=0;i<5;++i)clock();d.reset_n=1;for(unsigned i=0;i<10;++i)clock();
        uint64_t align_checks=0,read_checks=0,norm_checks=0,bank_checks=0;
        // Full signed sf bus and both signs with independent bit construction.
        for(int sf=-1024;sf<1024;++sf)for(unsigned sign=0;sign<2;++sign)for(unsigned pattern=0;pattern<8;++pattern) {
            const uint32_t m=pattern==0?0u:pattern==1?1u:pattern==2?0x1000000u:pattern==3?0x3ffffffu:uint32_t(mix(20261103+pattern+sf*9))&0x3ffffffu;
            d.sf=unsigned(sf)&2047;d.sign=sign;d.magnitude=m;d.eval();
            const int shift=sf+456;
            bool error=false;quire32::Words expected{};
            if(m) {
                if(shift<0)error=(-shift>=26)||((m&((uint64_t(1)<<unsigned(-shift))-1))!=0);
                else if(shift>945)error=true;
                if(!error)for(unsigned bit=0;bit<26;++bit)if((m>>bit)&1) {
                    const int position=int(bit)+shift;
                    if(position>=0)expected[unsigned(position)/32]|=uint32_t(1)<<(unsigned(position)%32);
                }
            }
            require(bool(d.align_error)==error,"align error classification");
            if(!error) {
                if(sign)expected=quire32::Model::negate(expected);
                for(unsigned i=0;i<31;++i)require(d.term[i]==expected[i],"align data");
            }
            ++align_checks;
        }
        auto read=[&](quire32::Words raw,bool nar=false,bool invalid=false,bool loss=false,bool cut=false) {
            require(d.read_ready&&!d.out_valid,"unit READ idle");
            quire32::Model model;model.q=raw;model.nar=nar;model.invalid=invalid;model.loss=loss;model.cut=cut;
            const auto expected=model.read();
            const bool negative=quire32::Model::bit(raw,971);
            const auto magnitude=negative?quire32::Model::negate(raw):raw;
            int h=971;while(h>=0&&!quire32::Model::bit(magnitude,h))--h;
            uint64_t fraction=0;bool sticky=false;
            for(int i=1;i<=53;++i)if(quire32::Model::bit(magnitude,h-i))fraction|=uint64_t(1)<<(53-i);
            for(int i=0;i<h-53;++i)sticky|=quire32::Model::bit(magnitude,i);
            const int sf=std::max(-241,std::min(241,h-480));
            for(unsigned i=0;i<31;++i)d.read_q[i]=raw[i];
            d.read_nar=nar;d.read_invalid=invalid;d.read_loss=loss;d.read_cut=cut;d.read_valid=1;d.out_ready=0;
            clock();d.read_valid=0;d.eval();
            bool normalized=false,responded=false;
            for(unsigned timeout=0;timeout<100;++timeout) {
                if(d.norm_valid) {
                    require(bool(d.norm_nar)==(nar||invalid)&&bool(d.norm_zero)==(h<0)&&bool(d.norm_sign)==negative,"normalizer status");
                    require(d.norm_flags==((nar||invalid)?16u:((loss?2u:0u)|(cut?1u:0u))),"normalizer incoming flags");
                    if(h>=0&&!nar&&!invalid) {
                        const int actual=(d.norm_sf&1024)?int(d.norm_sf)-2048:int(d.norm_sf);
                        require(actual==sf&&d.norm_frac==fraction&&bool(d.norm_sticky)==sticky,"normalized fraction/scale/sticky");
                    }
                    normalized=true;++norm_checks;
                }
                if(d.out_valid) {
                    require(d.d==expected.bits&&d.flags==expected.flags,"unit READ RNE bits/flags");
                    const uint64_t held=(uint64_t(d.flags)<<32)|d.d;
                    for(unsigned k=0;k<3;++k){clock();require(d.out_valid&&held==((uint64_t(d.flags)<<32)|d.d),"unit READ stall");}
                    d.out_ready=1;clock();responded=true;break;
                }
                clock();
            }
            require(normalized&&responded,"unit READ timeout");++read_checks;
        };
        read({});
        for(unsigned h=0;h<972;++h)for(unsigned sign=0;sign<2;++sign) {
            quire32::Words raw{};raw[h/32]|=uint32_t(1)<<(h%32);
            if(h<971&&sign)raw=quire32::Model::negate(raw);
            read(raw);
        }
        for(unsigned i=0;i<20000;++i) {
            const unsigned h=unsigned(mix(i+20261103)%971);quire32::Words raw{};
            for(unsigned k=0;k<=h/32;++k)raw[k]=uint32_t(mix(i*31+k));
            raw[h/32]&=(h%32==31)?UINT32_MAX:((uint32_t(1)<<(h%32+1))-1);
            raw[h/32]|=uint32_t(1)<<(h%32);
            if(i&1)raw=quire32::Model::negate(raw);
            read(raw,false,false,(i%3)==0,(i%5)==0);
        }
        read({},true);read({},false,true);read({},false,false,true,true);
        auto bank=[&](const quire32::Words& term,bool clear=false,bool nar=false,bool invalid=false,bool loss=false,bool cut=false) {
            const auto old_count=d.q_count;
            quire32::Words old_q{};for(unsigned i=0;i<31;++i)old_q[i]=d.bank_q[i];
            d.clear=clear;d.eval();require(d.bank_ready,"bank ready");
            const bool negative=quire32::Model::bit(term,971);
            const auto mag=negative?quire32::Model::negate(term):term;
            unsigned low=0;while(low<972&&!quire32::Model::bit(mag,int(low)))++low;
            uint32_t coeff=0;
            if(low<972) {
                for(unsigned bit=0;bit<26;++bit)if(quire32::Model::bit(mag,int(low+bit)))coeff|=1u<<bit;
                for(unsigned bit=low+26;bit<972;++bit)require(!quire32::Model::bit(mag,int(bit)),"test compact coefficient bound");
            }
            d.bank_zero=(low==972);d.bank_coefficient=negative?((0u-coeff)&0x7ffffffu):coeff;
            d.bank_index=low==972?0:low/36;d.bank_offset=low==972?0:low%36;
            d.term_nar=nar;d.term_invalid=invalid;d.term_loss=loss;d.term_cut=cut;d.bank_valid=1;
            clock();d.bank_valid=0;d.clear=0;d.eval();
            unsigned timeout=0;
            while(!d.bank_done&&timeout++<40) {
                for(unsigned i=0;i<31;++i)require(d.bank_q[i]==old_q[i],"partial Q visible before atomic commit");
                require(d.q_count==old_count,"partial count before commit");clock();
            }
            require(d.bank_done,"bank timeout");++bank_checks;
            // Any held bank result must not commit again in absence of a request.
            const auto count=d.q_count;clock();clock();require(!d.bank_done&&d.q_count==count,"bank commit once");
        };
        quire32::Words big{};big[30]=1u<<10;
        bank({},true);bank(big);require(!d.q_overflow&&d.q_count==1,"bank first");
        bank(big);require(d.q_overflow&&d.q_invalid&&d.q_count==2,"positive overflow detected");
        for(unsigned i=0;i<31;++i)require(d.bank_q[i]==big[i],"overflow preserves Q");
        bank(quire32::Model::negate(big));require(d.q_overflow&&d.q_invalid,"overflow sticky");
        bank({},true);require(!d.q_overflow&&!d.q_invalid&&!d.q_nar&&d.q_count==0,"CLEAR status");
        bank(quire32::Model::negate(big));bank(quire32::Model::negate(big));require(!d.q_overflow,"min signed representable");
        bank(quire32::Model::negate(big));require(d.q_overflow&&d.q_invalid,"negative overflow detected");
        bank({},true);bank({},false,false,true);require(d.q_invalid&&!d.q_overflow,"invalid without arithmetic overflow");
        bank({},true);bank({},false,true);bank(big);require(d.q_nar&&d.q_count==2,"bank NaR sticky");
        bank({},true);bank({},false,false,false,true,true);require(d.q_loss&&d.q_cut,"loss with zero term");
        bank({},true);for(unsigned i=0;i<1024;++i)bank({});
        require(!d.bank_ready&&d.q_count==1024,"bank capacity");bank({},true);
        // Independent full972-bit limb sum versus compact word generation.
        quire32::Words expected_q{};
        for(unsigned trial=0;trial<10000;++trial) {
            if(trial%512==0){bank({},true);expected_q={};}
            const unsigned shift=unsigned(mix(20261104+trial)%901);
            const uint32_t coefficient=uint32_t(mix(trial+73))&0x3ffffffu;
            quire32::Words term{};
            for(unsigned bit=0;bit<26;++bit)if((coefficient>>bit)&1)
                term[(shift+bit)/32]|=uint32_t(1)<<((shift+bit)%32);
            if(trial&1)term=quire32::Model::negate(term);
            uint64_t carry=0;
            for(unsigned i=0;i<31;++i){const uint64_t sum=uint64_t(expected_q[i])+term[i]+carry;expected_q[i]=uint32_t(sum);carry=sum>>32;}
            expected_q[30]&=4095;
            bank(term);
            for(unsigned i=0;i<31;++i)require(d.bank_q[i]==expected_q[i],"compact bank full-grid sum");
            require(!d.q_invalid&&!d.q_overflow,"bounded random bank status");
        }
        std::ofstream(argv[1])<<"{\"status\":\"PASS\",\"mismatches\":0,\"align_checks\":"<<align_checks
            <<",\"read_checks\":"<<read_checks<<",\"normalizer_checks\":"<<norm_checks<<",\"bank_checks\":"<<bank_checks<<"}\n";
        #if VM_COVERAGE
        context.coveragep()->write((std::string(argv[1])+".dat").c_str());
        #endif
        d.final();std::cout<<"QUIRE_UNITS_PASS align="<<align_checks<<" read="<<read_checks<<" bank="<<bank_checks<<'\n';
    }catch(const std::exception&e){std::cerr<<e.what()<<'\n';return 1;}
}
