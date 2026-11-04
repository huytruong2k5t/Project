//-----------------------------------------------------------------------------
// File          : dyn_left_shifter.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP (Approximate & Iterative Posit MAC)
// Creation Date : 2026-10-02
// Description   : Flattened 29-bit Dynamic Left Shifter for Posit(32,3) Parser.
//                 5-stage binary MUX cascade (b[4:0]: shift by 1, 2, 4, 8, 16).
//                 Note: For N=29, any shift b >= 29 naturally shifts out all 29
//                 bits (16 + 8 + 4 + >=1 >= 29), producing 29'd0 without needing
//                 an extra overflow comparator or clamp MUX stage.
//-----------------------------------------------------------------------------

module dyn_left_shifter (
    input  logic [28:0] in,
    input  logic [4:0]  b,
    output logic [28:0] out
);
    wire [28:0] stage0 = in;
    wire [28:0] stage1 = b[0] ? {stage0[27:0], 1'b0}  : stage0;
    wire [28:0] stage2 = b[1] ? {stage1[26:0], 2'b0}  : stage1;
    wire [28:0] stage3 = b[2] ? {stage2[24:0], 4'b0}  : stage2;
    wire [28:0] stage4 = b[3] ? {stage3[20:0], 8'b0}  : stage3;
    wire [28:0] stage5 = b[4] ? {stage4[12:0], 16'b0} : stage4;

    assign out = stage5;

endmodule
//-----------------------------------------------------------------------------
// End of dyn_left_shifter.sv
//-----------------------------------------------------------------------------
