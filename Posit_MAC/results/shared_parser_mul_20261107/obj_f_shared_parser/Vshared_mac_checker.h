// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary model header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef VERILATED_VSHARED_MAC_CHECKER_H_
#define VERILATED_VSHARED_MAC_CHECKER_H_  // guard

#include "verilated.h"
#include "svdpi.h"

class Vshared_mac_checker__Syms;
class Vshared_mac_checker___024root;

// This class is the main interface to the Verilated model
class alignas(VL_CACHE_LINE_BYTES) Vshared_mac_checker VL_NOT_FINAL : public VerilatedModel {
  private:
    // Symbol table holding complete model state (owned by this class)
    Vshared_mac_checker__Syms* const vlSymsp;

  public:

    // CONSTEXPR CAPABILITIES
    // Verilated with --trace?
    static constexpr bool traceCapable = false;

    // PORTS
    // The application code writes and reads these signals to
    // propagate new values into/out from the Verilated model.
    VL_IN8(&clk,0,0);
    VL_IN8(&rst_n,0,0);
    VL_IN8(&in_valid,0,0);
    VL_OUT8(&in_ready,0,0);
    VL_IN8(&cfg_n,3,0);
    VL_IN8(&cfg_ops,1,0);
    VL_OUT8(&out_valid,0,0);
    VL_IN8(&out_ready,0,0);
    VL_OUT8(&flags,4,0);
    VL_OUT8(&core_done,0,0);
    VL_OUT8(&core_iterations,3,0);
    VL_OUT8(&core_cut,0,0);
    VL_OUT8(&core_input_cut,0,0);
    VL_OUT8(&core_sign,0,0);
    VL_OUT8(&core_error,0,0);
    VL_OUT8(&commit_valid,0,0);
    VL_OUT8(&commit_first,0,0);
    VL_OUT8(&commit_last,0,0);
    VL_OUT8(&commit_iteration,3,0);
    VL_OUT8(&pack_sample,0,0);
    VL_OUT8(&pack_special,2,0);
    VL_OUT8(&pack_rounding,3,0);
    VL_OUT8(&add_sample,0,0);
    VL_OUT8(&add_shift,4,0);
    VL_OUT8(&add_clamped,0,0);
    VL_OUT8(&add_sub,0,0);
    VL_OUT8(&add_lzc,4,0);
    VL_OUT8(&add_lzc_sample,0,0);
    VL_OUT16(&core_scale,10,0);
    VL_IN(&a,31,0);
    VL_IN(&b,31,0);
    VL_IN(&c,31,0);
    VL_OUT(&d,31,0);
    VL_OUT(&core_magnitude,25,0);

    // CELLS
    // Public to allow access to /* verilator public */ items.
    // Otherwise the application code can consider these internals.

    // Root instance pointer to allow access to model internals,
    // including inlined /* verilator public_flat_* */ items.
    Vshared_mac_checker___024root* const rootp;

    // CONSTRUCTORS
    /// Construct the model; called by application code
    /// If contextp is null, then the model will use the default global context
    /// If name is "", then makes a wrapper with a
    /// single model invisible with respect to DPI scope names.
    explicit Vshared_mac_checker(VerilatedContext* contextp, const char* name = "TOP");
    explicit Vshared_mac_checker(const char* name = "TOP");
    /// Destroy the model; called (often implicitly) by application code
    virtual ~Vshared_mac_checker();
  private:
    VL_UNCOPYABLE(Vshared_mac_checker);  ///< Copying not allowed

  public:
    // API METHODS
    /// Evaluate the model.  Application must call when inputs change.
    void eval() { eval_step(); }
    /// Evaluate when calling multiple units/models per time step.
    void eval_step();
    /// Evaluate at end of a timestep for tracing, when using eval_step().
    /// Application must call after all eval() and before time changes.
    void eval_end_step() {}
    /// Simulation complete, run final blocks.  Application must call on completion.
    void final();
    /// Are there scheduled events to handle?
    bool eventsPending();
    /// Returns time at next time slot. Aborts if !eventsPending()
    uint64_t nextTimeSlot();
    /// Trace signals in the model; called by application code
    void trace(VerilatedTraceBaseC* tfp, int levels, int options = 0) { contextp()->trace(tfp, levels, options); }
    /// Retrieve name of this model instance (as passed to constructor).
    const char* name() const;

    // Abstract methods from VerilatedModel
    const char* hierName() const override final;
    const char* modelName() const override final;
    unsigned threads() const override final;
    /// Prepare for cloning the model at the process level (e.g. fork in Linux)
    /// Release necessary resources. Called before cloning.
    void prepareClone() const;
    /// Re-init after cloning the model at the process level (e.g. fork in Linux)
    /// Re-allocate necessary resources. Called after cloning.
    void atClone() const;
  private:
    // Internal functions - trace registration
    void traceBaseModel(VerilatedTraceBaseC* tfp, int levels, int options);
};

#endif  // guard
