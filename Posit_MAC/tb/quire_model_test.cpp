#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include "posit_quire.hpp"
#include "quire_reference.hpp"

static uint64_t mix(uint64_t x) {
    x+=0x9e3779b97f4a7c15ull;x=(x^(x>>30))*0xbf58476d1ce4e5b9ull;
    x=(x^(x>>27))*0x94d049bb133111ebull;return x^(x>>31);
}
int main(int argc,char**argv) {
    try {
        if(argc<2||argc>3)throw std::runtime_error("report path [Python fixture] required");
        quire32::Model model;quire_reference::Oracle oracle;
        uint64_t checks=0,reads=0;
        auto step=[&](uint32_t a,uint32_t b,unsigned n=12,unsigned ops=1) {
            model.mac(a,b,n,ops);oracle.mac(a,b,n,ops);++checks;
            if(model.q!=oracle.raw()||model.count!=oracle.count||model.ack().flags!=oracle.ack_flags())
                throw std::runtime_error("model checkpoint "+std::to_string(checks));
            const auto x=model.read();const auto y=oracle.read();++reads;
            if(x.bits!=y.first||x.flags!=y.second||x.overflow)
                throw std::runtime_error("model READ "+std::to_string(checks));
        };
        auto clear=[&](){model.clear();oracle.clear();};
        const uint32_t one=0x40000000u;
        auto power=[](int sf) {
            l1::posit_unpacked<32,3> u{};u.sf=sf;u.frac=uint64_t(1)<<63;u.exact=true;
            return l1::pack<32,3>(u);
        };
        step(one,one);for(unsigned i=0;i<3;++i)step(power(-14),power(-14));
        if(model.read().bits!=0x40000001u)throw std::runtime_error("NOROUND");
        for(uint32_t code:{1u,0x7fffffffu,0xffffffffu,0x80000001u}) {
            clear();for(unsigned i=0;i<1024;++i)step(code,code==0x80000001u?0x7fffffffu:code);
            bool rejected=false;try{model.mac(one,one);}catch(const std::invalid_argument&){rejected=true;}
            if(!rejected)throw std::runtime_error("capacity");
        }
        clear();step(0,0x80000000u);step(one,one);clear();step(one,one);
        for(unsigned op=0;op<2;++op)for(unsigned n=0;n<13;++n) {
            clear();for(unsigned i=0;i<1024;++i) {
                auto a=uint32_t(mix(20261103ull+i+10000ull*n+1000000ull*op));
                auto b=uint32_t(mix(20261104ull+i*7+10000ull*n+1000000ull*op));
                step(a,b,n,op);
            }
        }
        for(unsigned sequence=0;sequence<1000;++sequence) {
            clear();for(unsigned i=0;i<64;++i)step(uint32_t(mix(13ull+sequence*64+i)),uint32_t(mix(17ull+sequence*64+i)));
        }
        uint64_t fixture_rows=0;
        if(argc==3) {
            clear();std::ifstream file(argv[2]);if(!file)throw std::runtime_error("Python fixture missing");
            unsigned cmd,n,ops,abort,flags,count,nar,loss,cut;uint32_t a,b,bits;std::string raw;
            while(file>>std::dec>>cmd>>std::hex>>a>>b>>std::dec>>n>>ops>>abort>>std::hex>>bits>>flags>>raw>>std::dec>>count>>nar>>loss>>cut) {
                if(cmd==0)clear();else if(cmd==1){model.mac(a,b,n,ops);oracle.mac(a,b,n,ops);}
                const auto r=cmd==2?model.read():model.ack();
                const auto g=cmd==2?oracle.read():std::make_pair(0u,oracle.ack_flags());
                if(r.bits!=bits||r.flags!=flags||g.first!=bits||g.second!=flags||model.q!=oracle.raw()
                    ||model.count!=count||model.nar!=bool(nar)||model.loss!=bool(loss)||model.cut!=bool(cut))
                    throw std::runtime_error("Python/model/oracle row "+std::to_string(fixture_rows));
                raw=std::string(248-raw.size(),'0')+raw;
                for(unsigned i=0;i<31;++i)if(uint32_t(std::stoul(raw.substr(240-8*i,8),nullptr,16))!=model.q[i])
                    throw std::runtime_error("Python Q checkpoint");
                ++fixture_rows;if(abort)clear();
            }
        }
        std::ofstream(argv[1])<<"{\"status\":\"PASS\",\"mismatches\":0,\"seed\":20261103,\"mac_checks\":"<<checks
            <<",\"read_checks\":"<<reads<<",\"python_fixture_rows\":"<<fixture_rows<<",\"grid\":-480,\"width\":972,\"L_max\":1024}\n";
        std::cout<<"QUIRE_MODEL_PASS checks="<<checks<<" reads="<<reads<<'\n';
    }catch(const std::exception&e){std::cerr<<e.what()<<'\n';return 1;}
}
