//-----------------------------------------------------------------------------
// File          : primitive_v2_top.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP
// Creation Date : 2026-10-16
// Description   : Structural OOC measurement top with a Xilinx clock buffer.
// $Source: $ $Revision: 2.0 $ $Log: Matched boundaries for all variants. $
//-----------------------------------------------------------------------------
module primitive_v2_top #(
    parameter int N = 30,
    parameter int KIND = 2,
    parameter int MODE = 0,
    parameter int ARITH = 0,
    parameter int FILL_KIND = 1,
    parameter int SHIFT_W = (N > 1) ? $clog2(N) : 1,
    parameter int RESULT_W = (KIND == 2) ? SHIFT_W+1
                          : (KIND >= 3) ? N+SHIFT_W+1 : N
)(
    input wire clk,
    input wire [N-1:0] data,
    input wire [SHIFT_W-1:0] amount,
    input wire fill_val,
    output wire [RESULT_W-1:0] result
);
    wire clk_core;
    BUFG u_clock (.I(clk), .O(clk_core));
    primitive_v2_boundary #(
        .N(N), .KIND(KIND), .MODE(MODE), .ARITH(ARITH),
        .FILL_KIND(FILL_KIND), .SHIFT_W(SHIFT_W), .RESULT_W(RESULT_W)
    ) u_boundary (
        .clk(clk_core), .data(data), .amount(amount), .fill_val(fill_val), .result(result)
    );
endmodule
// End of primitive_v2_top.sv
