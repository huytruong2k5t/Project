//-----------------------------------------------------------------------------
// File          : dyn_right_shifter_fixed2.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP (Approximate & Iterative Posit MAC)
// Creation Date : 2026-10-02
// Description   : 59-bit Logarithmic Dynamic Right Shifter (Flattened MUX Tree).
//                 Optimized 5-stage 2:1 multiplexer cascade (b[4:0] <= 31 < 59).
//                 Naturally shifts by 0..31 with dynamic fill_val (e.g. first
//                 regime bit in Posit Packer), zero overflow comparison logic,
//                 and no 2D unpacked arrays.
//-----------------------------------------------------------------------------

module dyn_right_shifter_fixed2 (
    input  logic [58:0] in,
    input  logic [4:0]  b,
    input  logic        fill_val,
    output logic [58:0] out
);
    // Flattened 5-stage logarithmic MUX cascade (shift amount 0..31):
    wire [58:0] stage0 = b[0] ? {fill_val,       in[58:1]}      : in;
    wire [58:0] stage1 = b[1] ? {{2{fill_val}},  stage0[58:2]}  : stage0;
    wire [58:0] stage2 = b[2] ? {{4{fill_val}},  stage1[58:4]}  : stage1;
    wire [58:0] stage3 = b[3] ? {{8{fill_val}},  stage2[58:8]}  : stage2;
    wire [58:0] stage4 = b[4] ? {{16{fill_val}}, stage3[58:16]} : stage3;

    assign out = stage4;

endmodule
//-----------------------------------------------------------------------------
// End of dyn_right_shifter_fixed2.sv
//-----------------------------------------------------------------------------
