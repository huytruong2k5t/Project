// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vshared_mac_checker__pch.h"

//============================================================
// Constructors

Vshared_mac_checker::Vshared_mac_checker(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vshared_mac_checker__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst_n{vlSymsp->TOP.rst_n}
    , in_valid{vlSymsp->TOP.in_valid}
    , in_ready{vlSymsp->TOP.in_ready}
    , cfg_n{vlSymsp->TOP.cfg_n}
    , cfg_ops{vlSymsp->TOP.cfg_ops}
    , out_valid{vlSymsp->TOP.out_valid}
    , out_ready{vlSymsp->TOP.out_ready}
    , flags{vlSymsp->TOP.flags}
    , core_done{vlSymsp->TOP.core_done}
    , core_iterations{vlSymsp->TOP.core_iterations}
    , core_cut{vlSymsp->TOP.core_cut}
    , core_input_cut{vlSymsp->TOP.core_input_cut}
    , core_sign{vlSymsp->TOP.core_sign}
    , core_error{vlSymsp->TOP.core_error}
    , commit_valid{vlSymsp->TOP.commit_valid}
    , commit_first{vlSymsp->TOP.commit_first}
    , commit_last{vlSymsp->TOP.commit_last}
    , commit_iteration{vlSymsp->TOP.commit_iteration}
    , pack_sample{vlSymsp->TOP.pack_sample}
    , pack_special{vlSymsp->TOP.pack_special}
    , pack_rounding{vlSymsp->TOP.pack_rounding}
    , add_sample{vlSymsp->TOP.add_sample}
    , add_shift{vlSymsp->TOP.add_shift}
    , add_clamped{vlSymsp->TOP.add_clamped}
    , add_sub{vlSymsp->TOP.add_sub}
    , add_lzc{vlSymsp->TOP.add_lzc}
    , add_lzc_sample{vlSymsp->TOP.add_lzc_sample}
    , core_scale{vlSymsp->TOP.core_scale}
    , a{vlSymsp->TOP.a}
    , b{vlSymsp->TOP.b}
    , c{vlSymsp->TOP.c}
    , d{vlSymsp->TOP.d}
    , core_magnitude{vlSymsp->TOP.core_magnitude}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vshared_mac_checker::Vshared_mac_checker(const char* _vcname__)
    : Vshared_mac_checker(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vshared_mac_checker::~Vshared_mac_checker() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vshared_mac_checker___024root___eval_debug_assertions(Vshared_mac_checker___024root* vlSelf);
#endif  // VL_DEBUG
void Vshared_mac_checker___024root___eval_static(Vshared_mac_checker___024root* vlSelf);
void Vshared_mac_checker___024root___eval_initial(Vshared_mac_checker___024root* vlSelf);
void Vshared_mac_checker___024root___eval_settle(Vshared_mac_checker___024root* vlSelf);
void Vshared_mac_checker___024root___eval(Vshared_mac_checker___024root* vlSelf);

void Vshared_mac_checker::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vshared_mac_checker::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vshared_mac_checker___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vshared_mac_checker___024root___eval_static(&(vlSymsp->TOP));
        Vshared_mac_checker___024root___eval_initial(&(vlSymsp->TOP));
        Vshared_mac_checker___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vshared_mac_checker___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vshared_mac_checker::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty(); }

uint64_t Vshared_mac_checker::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vshared_mac_checker::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vshared_mac_checker___024root___eval_final(Vshared_mac_checker___024root* vlSelf);

VL_ATTR_COLD void Vshared_mac_checker::final() {
    Vshared_mac_checker___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vshared_mac_checker::hierName() const { return vlSymsp->name(); }
const char* Vshared_mac_checker::modelName() const { return "Vshared_mac_checker"; }
unsigned Vshared_mac_checker::threads() const { return 1; }
void Vshared_mac_checker::prepareClone() const { contextp()->prepareClone(); }
void Vshared_mac_checker::atClone() const {
    contextp()->threadPoolpOnClone();
}
