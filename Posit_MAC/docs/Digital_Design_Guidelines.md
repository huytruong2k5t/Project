# Digital Design Guidelines

## 1. RTL Coding Guidelines

### Source File
*   **File Name:** Each source file must have only one module definition and must bear the name of the module.
    *   Verilog RTL code file name should be `<filename>.v`.
    *   System Verilog RTL code file name should be `<filename>.sv`.
    *   Header file should be named the same as the top-level module with `.vh` extension (i.e.: `<topmodule>.vh`).
    *   *Examples:* 
        *   Verilog source file named `rcd_digital.v` will have only one module definition named digital in it: `module rcd_digital ()`
        *   System Verilog source file name `rcd_digital.sv` will have only one module definition named digital in it: `module rcd_digital ()`

*   **Module Header and Footer:** Each source file must have a standard header and footer for modification history.
    ```verilog
    //-----------------------------------------------------------------------------
    // File          :
    // Author(s)     :
    // Email         :
    // Project       :
    // Creation Date :
    //
    // Description   :
    //-----------------------------------------------------------------------------
    // $Source: $
    // $Revision: $
    // $Log: $
    ```

### Editor Tools
One may use any editor like emacs, xemacs, gvim etc., convenient for RTL coding. **Avoid using tabs** in the source code because every editor may have a different tab setting. Add Verilog Mode (`verilog-mode.el`) to the design repository.

### Minimize Compile and Lint Warning
*   Remove dangling ports, as much as possible.
*   Remove unused logic, at least comment it out.
*   Don't mix registers that need reset with registers that do not need reset.
*   Write clear code with intention to reduce the number of warnings.

### Instances & Ports
*   **Instances:** For module instantiations, always use explicit mapping for ports and generics using named association rather than positional association. Top-level PNR block should only contain module instantiations and no logic.
*   **Port Naming:**
    *   Define one port per line for easy script processing and clear readability.
    *   Include comments for special port signals.
    *   Do not insert logic expressions as a port name (e.g., `.siga (sigb | sigc)` is bad).
    *   No port rename; the signal name should be the same through the hierarchy.
*   **Module Instantiation:**
    *   Use `generate` as a first option.
    *   Connect single port as a vector, use the same name plus index: `.siga (siga[ix])`
    *   Use `AUTO_TEMPLATE` from Verilog Mode as a second option.
    *   If port rename cannot be avoided, add a suffix to the port name, do not change the name completely (e.g., `siga_sufx`).

### Compiler Directives & Array Definition
*   **Compiler Directives:** Do not use any Compiler directives (`\`timescale`, `\`undef`) in the source code. These are added in the testbench.
*   **Array Definition:** Always start a bus or array definition with MSB on LHS and LSB on RHS (e.g., `bus [10:0]`, not `bus [0:10]`). Use little Endian vector and array definitions.

### Parameterized Code
*   One header file with top-level defines for the whole project (`\`define`). Do not use `\`define` statements outside of the project header file.
*   Individual P&R modules can use a header file with parameters.
*   Use `localparam` for leaf modules and local parameters.
*   Use `parameter` for constants that could be overwritten by a parent module.

### Clocks
*   **Clock Name:** Must be lowercase and have the keyword `clk` in it (e.g., `rdp_clk_coredn`, `clk_core`). Do not use `clock`.
*   **Clock Synchronizer:** 
    *   Needed to reduce MTBF caused by metastability when crossing clock domains.
    *   Not required for static registers.
    *   Pulse signals should be converted into level signals before crossing.
    *   Input to the synchronizer must be driven by a flip-flop of the launching domain.
    *   Buses should not go through synchronizers directly; use a qualifying signal.
    *   To increase MTBF, use metastability-hardened flip-flops (e.g., TSMC 40G `SDFSYNCNQD*` cells).
    *   First flip-flop is `meta_sync1`, second is `meta_sync2`.
*   **Clock Gating:**
    *   Reset and Enable signals to the clock gating cell must be synchronous.
    *   Test mode (scan mode) must never be gated.
    *   Each Clock gate must have a dedicated CSR to disable it.
    *   Use load enables for fine-grained clock gating (inferred automatically by synthesis):
        ```verilog
        always @(posedge clk) begin
            if(enable) dataout <= in;
            else       dataout <= dataout;
        end
        ```

### Reset
*   **Reset Name:** Active low reset signals must be lowercase and have the keyword `reset_n` or `reset_b` (e.g., `reset_b_sync_<clkname_aftersync>`).
*   **Reset Synchronizer:**
    *   Reset must be asserted asynchronously and de-asserted synchronously.
    *   Every module/block on a particular clock domain must have its own double flop synchronizer for the reset signal.

### Delay
*   **Sequential Logic:** Use clock-to-Q delays in flops with a `\`CK2Q` define statement (e.g., `\`define CK2Q #1`).
*   **Combinational Logic:** Delays for combinational logic must NOT be used.

### IO Signals & Register Naming Convention
*   All IO signals must have lowercase letters and/or an underscore.
*   Top-level IO names must have the source and destination module as part of their name.
*   **CSR format:** `csr_<registername>_<range>` or `csr_<registername>_<fieldname>_<range>`
*   **CSR port name:** `Input: <blkname>_csri_...`, `Output: <blkname>_csro_...`
*   **CSR properties:** RO, COR, WO, W1C, W1S, SOR, RW.

### Finite State Machine (FSM)
*   Each FSM must have a reset signal that puts it in a known IDLE state.
*   Use `localparam` to define the state variables.
*   Each FSM must have a `default` state.
*   Signals monitoring/enabling the FSM must be synchronous to the FSM.

### Verilog Constructs for Combinational Logic
*   **case / casex / casez:**
    *   A `case` statement infers a single-level multiplexer.
    *   Every `case` must have a `default` statement.
    *   Use `casez` to encode don't care terms.
    *   For System Verilog, use `unique` or `priority` qualifiers.
*   **Priority encoding:** Use `if-then-else` or ternary operator `sig = (a) ? (b) : (c);` to avoid latch inference.
*   **Assignments:** Use blocking (`=`) for combinational and non-blocking (`<=`) for sequential logic.
*   **Generate:** Use `generate` loops instead of repeating code.

### Flops & Latches
*   **D flop with asynchronous reset:**
    ```verilog
    always @(posedge clk or negedge reset_b) begin
        if(~reset_b) dout <= 1'b0;
        else         dout <= `CK2Q din;
    end
    ```
    *(System Verilog: use `always_ff`)*
*   **Latches:** Avoid latches. If needed, use `always_latch` in System Verilog.

---

## 2. Design Quality and Reliable Guidelines

### Clock Domain Crossing (CDC)
*   Static Timing Analysis (STA) cannot ensure timing closure across asynchronous clock domains.
*   **Basic CDC Synchronization:** Use multi-stage synchronizers for single-bit transfers.
*   **Incorrect Usage:** No combinatorial logic before synchronizer, no multi-bit synchronization without proper encoding, do not tap signals within synchronizers.
*   **Multi-bit Data:** Use GRAY encoding for streaming data or handshake/feedback signals for multi-bit data transfers.
*   Must use "Marvell Hardened Synchronizer" as a multi-stage synchronizer.

### Reset Domain Crossing (RDC)
*   Crossing between different reset domains (even on the same clock) cannot be analyzed by STA.
*   **Solutions:** Control reset assertion sequence, control D/CLK input of the destination reset domain FF, or use a Multi-Stage Synchronizer. SRAM memory applications need specific RDC handling.

### Multi Cycle Path (MCP) & False Path (FP)
*   **False Path (FP):** Disables timing checks. Use only when absolutely necessary as it creates divergence between Synthesis and RTL simulation.
*   Do NOT use 'False Path' constraints between asynchronous clock domains. Instead, make use of `set_max_delay` of 1 clock period of the destination clock.

### Design Checks (CDC/RDC/MCP/FP)
*   CDC/RDC designs must adhere to structural rules to function reliably.
*   Tools like **Spyglass, VC Spyglass, Real Intent, Mentor Questa** are used to detect violations.
*   Analyze and address every violation reported by static tools before RTL freeze. Minimize the use of waivers.
