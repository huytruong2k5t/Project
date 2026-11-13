// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VSHARED_MAC_CHECKER__SYMS_H_
#define VERILATED_VSHARED_MAC_CHECKER__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vshared_mac_checker.h"

// INCLUDE MODULE CLASSES
#include "Vshared_mac_checker___024root.h"

// DPI TYPES for DPI Export callbacks (Internal use)

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vshared_mac_checker__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vshared_mac_checker* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vshared_mac_checker___024root  TOP;

    // SCOPE NAMES
    VerilatedScope __Vscope_shared_mac_checker__g_f__dut__u_wrapper;

    // CONSTRUCTORS
    Vshared_mac_checker__Syms(VerilatedContext* contextp, const char* namep, Vshared_mac_checker* modelp);
    ~Vshared_mac_checker__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
