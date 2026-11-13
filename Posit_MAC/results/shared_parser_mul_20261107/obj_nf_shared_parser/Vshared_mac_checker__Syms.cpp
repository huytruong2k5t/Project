// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vshared_mac_checker__pch.h"
#include "Vshared_mac_checker.h"
#include "Vshared_mac_checker___024root.h"

// FUNCTIONS
Vshared_mac_checker__Syms::~Vshared_mac_checker__Syms()
{
}

Vshared_mac_checker__Syms::Vshared_mac_checker__Syms(VerilatedContext* contextp, const char* namep, Vshared_mac_checker* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
        // Check resources
        Verilated::stackCheck(991);
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-9);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    // Setup scopes
    __Vscope_shared_mac_checker__g_nf__dut__u_wrapper.configure(this, name(), "shared_mac_checker.g_nf.dut.u_wrapper", "u_wrapper", "<null>", -9, VerilatedScope::SCOPE_OTHER);
    // Setup export functions
    for (int __Vfinal = 0; __Vfinal < 2; ++__Vfinal) {
        __Vscope_shared_mac_checker__g_nf__dut__u_wrapper.varInsert(__Vfinal,"core_error", &(TOP.shared_mac_checker__DOT__g_nf__DOT__dut__DOT__u_wrapper__DOT__core_error), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RD,0);
    }
}
