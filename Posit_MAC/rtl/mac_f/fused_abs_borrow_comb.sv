//-----------------------------------------------------------------------------
// File          : fused_abs_borrow_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : W12-F-1 fused datapath, approximate posit(32,3).
// $Source: $ $Revision: 1.0 $ $Log: Week13 RTL implementation. $
//-----------------------------------------------------------------------------
module fused_abs_borrow_comb (
    input  logic signed [31:0] retained_sum,
    input  logic base_sign,
    input  logic subtract,
    input  logic residual,
    output wire [30:0] magnitude,
    output wire sign,
    output wire borrow
);
    wire negative;
    wire [30:0] complemented;
    wire [30:0] correction;
    assign negative = retained_sum[31];
    assign borrow = residual && (subtract != negative);
    assign complemented = retained_sum[30:0] ^ {31{negative}};
    // abs(Z)-borrow = (Z xor sign_mask) + (negative-borrow).
    // Fold ABS increment and residual decrement into one adder.
    assign correction = (negative == borrow) ? 31'b0
                      : negative ? 31'd1 : 31'h7fffffff;
    assign magnitude = complemented + correction;
    assign sign = (retained_sum != 0) && (base_sign ^ negative);
endmodule
// End of fused_abs_borrow_comb.sv
