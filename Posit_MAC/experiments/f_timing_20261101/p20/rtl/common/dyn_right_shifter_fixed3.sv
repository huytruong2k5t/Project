//-----------------------------------------------------------------------------
// File          : dyn_right_shifter_fixed3.sv
// Author(s)     : Dan Huy
// Email         : 
// Project       : Posit MAC IP (Approximate & Iterative Posit MAC)
// Creation Date : 2026-10-30
//
// Description   : 16-bit Logarithmic Dynamic Right Shifter (Flattened MUX Tree).
//                 Optimized 4-stage 2:1 multiplexer cascade (S = $clog2(16) = 4).
//                 Logic depth is exactly 4 MUX levels (O(log2 N)), mapped cleanly
//                 to FPGA LUTs. Shifting by 2^i is pure wiring concatenation.
//                 Since N=16 and SHIFT_W=4, shift amount b[3:0] is strictly <= 15 < N,
//                 eliminating static overflow checking logic and extra MUX levels.
//                 Flattened wire structure avoids 2D unpacked array lint warnings.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: $

module dyn_right_shifter_fixed3 (
    input  logic [15:0] in,
    input  logic [3:0]  b,
    input  logic        fill_val, // Tie to 1'b0 for logical zero fill
    output logic [15:0] out
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    localparam int N       = 16;
    localparam int SHIFT_W = 4;
    localparam bit ARITH   = 1'b0;

    // Determine the effective fill bit: in[15] if ARITH = 1, else fill_val
    logic fill;
    assign fill = ARITH ? in[15] : fill_val;

    // Flattened 4-stage logarithmic MUX cascade:
    // Stage 0: Shift by 1 bit  (controlled by b[0])
    // Stage 1: Shift by 2 bits (controlled by b[1])
    // Stage 2: Shift by 4 bits (controlled by b[2])
    // Stage 3: Shift by 8 bits (controlled by b[3])
    wire [15:0] stage0 = b[0] ? {fill,        in[15:1]}     : in;
    wire [15:0] stage1 = b[1] ? {{2{fill}},  stage0[15:2]} : stage0;
    wire [15:0] stage2 = b[2] ? {{4{fill}},  stage1[15:4]} : stage1;
    wire [15:0] stage3 = b[3] ? {{8{fill}},  stage2[15:8]} : stage2;

    assign out = stage3;

endmodule
//-----------------------------------------------------------------------------
// End of dyn_right_shifter_fixed3
//-----------------------------------------------------------------------------

