#define L1_BUILD_DLL
#include "l1_api.h"
#include "posit_mac.hpp"
#include <memory>
using namespace l1;
namespace {
MacConfig convert(const l1_mac_config* p) {
    MacConfig c;if(!p) return c;
    if(p->version>1 || p->exact>1 || p->ops>1 || p->scheme>1 || p->rounding>1)
        throw std::invalid_argument("invalid C configuration");
    c.version=p->version?MacVersion::V1:MacVersion::V0;c.exact=p->exact;c.n=p->n;c.ops=p->ops;
    c.scheme=p->scheme?ShiftRound::STICKY_ACC:ShiftRound::FLOOR;
    c.rounding=p->rounding?RoundMode::TRUNC:RoundMode::RNE;return c;
}
template<int NB,int ES> l1_mac_result export_result(const MacResult<NB,ES>& r) {
    return {uint32_t(r.bits),r.flags.bits(),r.iterations,uint32_t(r.bypass)};
}
bool format(uint32_t nb,uint32_t es) {return (nb==8 && es==0)||(nb==16 && es==1)||(nb==32 && (es==2||es==3));}
bool range(uint32_t nb,uint32_t a,uint32_t b,uint32_t c) {return nb==32 || ((a|b|c)>>nb)==0;}
struct State {
    virtual ~State()=default;
    virtual void reset()=0;
    virtual l1_mac_result step(uint32_t,uint32_t,uint32_t,bool,bool,MacConfig)=0;
};
template<int NB,int ES> struct TypedState:State {
    MacAccumulator<NB,ES> acc;
    void reset() override {acc.reset();}
    l1_mac_result step(uint32_t a,uint32_t b,uint32_t c,bool mode,bool clr,MacConfig cfg) override {
        return export_result(acc.step(a,b,c,mode,clr,cfg));
    }
};
}
struct l1_accumulator {uint32_t nb;std::unique_ptr<State> state;};
extern "C" {
uint32_t l1_p32_mul(uint32_t a,uint32_t b) {return l1_mul<32,2>(a,b);}
uint32_t l1_p32_mac(uint32_t a,uint32_t b,uint32_t c) {return l1_mac<32,2>(a,b,c);}
int l1_mac_eval(uint32_t nb,uint32_t es,uint32_t a,uint32_t b,uint32_t c,const l1_mac_config* cfg,l1_mac_result* out) {
    if(!out || !format(nb,es) || !range(nb,a,b,c)) return 1;
    try {auto config=convert(cfg);l1_mac_result r;
        if(nb==8) r=export_result(PositMac<8,0>::mac(a,b,c,config));
        else if(nb==16) r=export_result(PositMac<16,1>::mac(a,b,c,config));
        else if(es==2) r=export_result(PositMac<32,2>::mac(a,b,c,config));
        else r=export_result(PositMac<32,3>::mac(a,b,c,config));
        *out=r;return 0;
    } catch(const std::invalid_argument&) {return 1;} catch(...) {return 2;}
}
l1_accumulator* l1_acc_create(uint32_t nb,uint32_t es) {
    if(!format(nb,es)) return nullptr;
    try {auto h=std::make_unique<l1_accumulator>();h->nb=nb;
        if(nb==8) h->state=std::make_unique<TypedState<8,0>>();
        else if(nb==16) h->state=std::make_unique<TypedState<16,1>>();
        else if(es==2) h->state=std::make_unique<TypedState<32,2>>();
        else h->state=std::make_unique<TypedState<32,3>>();
        return h.release();
    } catch(...) {return nullptr;}
}
int l1_acc_reset(l1_accumulator* h) {if(!h) return 1;h->state->reset();return 0;}
int l1_acc_step(l1_accumulator* h,uint32_t a,uint32_t b,uint32_t c,uint32_t mode,uint32_t clr,
                const l1_mac_config* cfg,l1_mac_result* out) {
    if(!h || !out || mode>1 || clr>1 || !range(h->nb,a,b,c)) return 1;
    try {auto r=h->state->step(a,b,c,mode,clr,convert(cfg));*out=r;return 0;}
    catch(const std::invalid_argument&) {return 1;} catch(...) {return 2;}
}
void l1_acc_destroy(l1_accumulator* h) {delete h;}
}
