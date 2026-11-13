// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vshared_mac_checker.h for the primary calling header

#include "Vshared_mac_checker__pch.h"
#include "Vshared_mac_checker__Syms.h"
#include "Vshared_mac_checker___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vshared_mac_checker___024root___dump_triggers__ico(Vshared_mac_checker___024root* vlSelf);
#endif  // VL_DEBUG

void Vshared_mac_checker___024root___eval_triggers__ico(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___eval_triggers__ico\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered.set(0U, (IData)(vlSelfRef.__VicoFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vshared_mac_checker___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vshared_mac_checker___024root___dump_triggers__act(Vshared_mac_checker___024root* vlSelf);
#endif  // VL_DEBUG

void Vshared_mac_checker___024root___eval_triggers__act(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___eval_triggers__act\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered.set(0U, ((IData)(vlSelfRef.clk) 
                                       & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__clk__0))));
    vlSelfRef.__VactTriggered.set(1U, ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2)) 
                                       & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2__0)));
    vlSelfRef.__VactTriggered.set(2U, vlSelfRef.__VdlySched.awaitingCurrentTime());
    vlSelfRef.__VactTriggered.set(3U, ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__reset_bridge_q)) 
                                       & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__reset_bridge_q__0)));
    vlSelfRef.__VactTriggered.set(4U, ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync2)) 
                                       & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync2__0)));
    vlSelfRef.__VactTriggered.set(5U, ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync2)) 
                                       & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync2__0)));
    vlSelfRef.__VactTriggered.set(6U, ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync2)) 
                                       & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync2__0)));
    vlSelfRef.__VactTriggered.set(7U, ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync2)) 
                                       & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync2__0)));
    vlSelfRef.__VactTriggered.set(8U, ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync2)) 
                                       & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync2__0)));
    vlSelfRef.__VactTriggered.set(9U, ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync2)) 
                                       & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync2__0)));
    vlSelfRef.__VactTriggered.set(0xaU, ((~ (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync2)) 
                                         & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync2__0)));
    vlSelfRef.__Vtrigprevexpr___TOP__clk__0 = vlSelfRef.clk;
    vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2__0 
        = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2;
    vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__reset_bridge_q__0 
        = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__reset_bridge_q;
    vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync2__0 
        = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_a__DOT__meta_sync2;
    vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync2__0 
        = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_b__DOT__meta_sync2;
    vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync2__0 
        = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_c__DOT__meta_sync2;
    vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync2__0 
        = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__meta_sync2;
    vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync2__0 
        = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync2;
    vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync2__0 
        = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_add__DOT__meta_sync2;
    vlSelfRef.__Vtrigprevexpr___TOP__shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync2__0 
        = vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_pack__DOT__meta_sync2;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vshared_mac_checker___024root___dump_triggers__act(vlSelf);
    }
#endif
}

VL_INLINE_OPT void Vshared_mac_checker___024root___nba_sequent__TOP__0(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___nba_sequent__TOP__0\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2) {
        if (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__meta_sync2) {
            if (vlSymsp->_vm_contextp__->assertOnGet(2, 1)) {
                if (VL_UNLIKELY(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_error)) {
                    VL_WRITEF_NX("[%0t] %%Fatal: mac_nf_wrapper.sv:383: Assertion failed in %Nshared_mac_checker.g_nf.dut.u_wrapper: NF: shared multiplier invariant\n",0,
                                 64,VL_TIME_UNITED_Q(1000),
                                 -9,vlSymsp->name());
                    VL_STOP_MT("../../../rtl/mac_nf/mac_nf_wrapper.sv", 383, "", false);
                }
            }
            if (vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__done_q) {
                if (vlSymsp->_vm_contextp__->assertOnGet(2, 1)) {
                    if (VL_UNLIKELY((1U & (~ ((IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__meta_sync2) 
                                              & (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_product_pack__DOT__p1_ready)))))) {
                        VL_WRITEF_NX("[%0t] %%Fatal: mac_nf_wrapper.sv:385: Assertion failed in %Nshared_mac_checker.g_nf.dut.u_wrapper: NF: lost prepack token\n",0,
                                     64,VL_TIME_UNITED_Q(1000),
                                     -9,vlSymsp->name());
                        VL_STOP_MT("../../../rtl/mac_nf/mac_nf_wrapper.sv", 385, "", false);
                    }
                }
                if (vlSymsp->_vm_contextp__->assertOnGet(2, 1)) {
                    if (VL_UNLIKELY((0xcU < (IData)(vlSelfRef.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__u_core__DOT__iterations_done_q)))) {
                        VL_WRITEF_NX("[%0t] %%Fatal: mac_nf_wrapper.sv:387: Assertion failed in %Nshared_mac_checker.g_nf.dut.u_wrapper: NF: iteration bound\n",0,
                                     64,VL_TIME_UNITED_Q(1000),
                                     -9,vlSymsp->name());
                        VL_STOP_MT("../../../rtl/mac_nf/mac_nf_wrapper.sv", 387, "", false);
                    }
                }
            }
        }
    }
}
