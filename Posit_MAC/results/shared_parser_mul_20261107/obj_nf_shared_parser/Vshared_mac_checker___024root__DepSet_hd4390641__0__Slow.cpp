// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vshared_mac_checker.h for the primary calling header

#include "Vshared_mac_checker__pch.h"
#include "Vshared_mac_checker__Syms.h"
#include "Vshared_mac_checker___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vshared_mac_checker___024root___dump_triggers__stl(Vshared_mac_checker___024root* vlSelf);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vshared_mac_checker___024root___eval_triggers__stl(Vshared_mac_checker___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vshared_mac_checker__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vshared_mac_checker___024root___eval_triggers__stl\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered.set(0U, (IData)(vlSelfRef.__VstlFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vshared_mac_checker___024root___dump_triggers__stl(vlSelf);
    }
#endif
}
