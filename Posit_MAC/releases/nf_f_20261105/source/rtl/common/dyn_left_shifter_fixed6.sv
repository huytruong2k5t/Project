//-----------------------------------------------------------------------------
// File          : dyn_left_shifter_fixed6.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-31
// Description   : 30-bit Logarithmic Logical Left Shifter (Flattened MUX Tree).
//                 5-stage 2:1 multiplexer cascade (b[4:0] <= 31).
//                 Naturally shifts out all 30 bits for b >= 30 without any
//                 is_overflow comparator or output gating MUX.
//-----------------------------------------------------------------------------
module dyn_left_shifter_fixed6 (
    input  logic [29:0] in,
    input  logic [4:0]  b,
    output logic [29:0] out
);
    wire [29:0] stage0 = b[0] ? {in[28:0],     1'b0}  : in;
    wire [29:0] stage1 = b[1] ? {stage0[27:0], 2'b0}  : stage0;
    wire [29:0] stage2 = b[2] ? {stage1[25:0], 4'b0}  : stage1;
    wire [29:0] stage3 = b[3] ? {stage2[21:0], 8'b0}  : stage2;
    wire [29:0] stage4 = b[4] ? {stage3[13:0], 16'b0} : stage3;

    assign out = stage4;

endmodule
//-----------------------------------------------------------------------------
// End of dyn_left_shifter_fixed6.sv
//-----------------------------------------------------------------------------

