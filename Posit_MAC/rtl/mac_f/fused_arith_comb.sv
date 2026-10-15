//-----------------------------------------------------------------------------
// File          : fused_arith_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : W12-F-1 fused datapath, approximate posit(32,3).
// $Source: $ $Revision: 1.0 $ $Log: Week13 RTL implementation. $
//-----------------------------------------------------------------------------
module fused_arith_comb (
    input  logic [30:0] large_value,
    input  logic [30:0] small_value,
    input  logic subtract,
    output wire signed [31:0] retained_sum
);
    wire [31:0] addend;
    assign addend = {1'b0, small_value} ^ {32{subtract}};
    // One carry chain with subtraction carry-in; signs are handled outside it.
    assign retained_sum = {1'b0, large_value} + addend + {31'b0, subtract};
endmodule
// End of fused_arith_comb.sv
