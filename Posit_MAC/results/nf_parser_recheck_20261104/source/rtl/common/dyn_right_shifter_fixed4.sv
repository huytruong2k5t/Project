//-----------------------------------------------------------------------------
// File          : dyn_right_shifter_fixed4.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-31
// Description   : 31-bit Logarithmic Logical Right Shifter (Flattened MUX Tree).
//                 5-stage 2:1 multiplexer cascade (b[4:0] <= 31).
//                 Naturally shifts out all 31 bits at b=31 with zero overflow
//                 comparison logic and no 2D unpacked arrays.
//-----------------------------------------------------------------------------
module dyn_right_shifter_fixed4 (
    input  logic [30:0] in,
    input  logic [4:0]  b,
    output logic [30:0] out
);
    wire [30:0] stage0 = b[0] ? {1'b0,  in[30:1]}      : in;
    wire [30:0] stage1 = b[1] ? {2'b0,  stage0[30:2]}  : stage0;
    wire [30:0] stage2 = b[2] ? {4'b0,  stage1[30:4]}  : stage1;
    wire [30:0] stage3 = b[3] ? {8'b0,  stage2[30:8]}  : stage2;
    wire [30:0] stage4 = b[4] ? {16'b0, stage3[30:16]} : stage3;

    assign out = stage4;

endmodule
//-----------------------------------------------------------------------------
// End of dyn_right_shifter_fixed4.sv
//-----------------------------------------------------------------------------

