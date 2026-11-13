// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vshared_mac_checker.h for the primary calling header

#include "Vshared_mac_checker__pch.h"
#include "Vshared_mac_checker__Syms.h"
#include "Vshared_mac_checker___024root.h"

void Vshared_mac_checker___024root___ctor_var_reset(Vshared_mac_checker___024root* vlSelf);

Vshared_mac_checker___024root::Vshared_mac_checker___024root(Vshared_mac_checker__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , __VdlySched{*symsp->_vm_contextp__}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vshared_mac_checker___024root___ctor_var_reset(this);
}

void Vshared_mac_checker___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vshared_mac_checker___024root::~Vshared_mac_checker___024root() {
}
