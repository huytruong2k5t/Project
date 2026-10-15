//-----------------------------------------------------------------------------
// File          : primitive_ppa_top.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Structural OOC top; identical banks and BUFG for both sources.
// $Source: $ $Revision: 1.0 $ $Log: Primitive-only, no MAC integration. $
//-----------------------------------------------------------------------------
module primitive_ppa_top #(
    parameter int N = 26,
    parameter int SHIFT_W = $clog2(N),
    parameter int KIND = 0,
    parameter int RESULT_W = (KIND == 2) ? $clog2(N)+1 : N
)(
    input wire clk,
    input wire [N-1:0] data,
    input wire [SHIFT_W-1:0] amount,
    input wire fill_val,
    output wire [RESULT_W-1:0] result
);
    wire clk_core;
    BUFG u_clk_bufg (
        .I(clk),
        .O(clk_core)
    );
    primitive_ppa_boundary #(
        .N(N),
        .SHIFT_W(SHIFT_W),
        .KIND(KIND),
        .RESULT_W(RESULT_W)
    ) u_boundary (
        .clk(clk_core),
        .data(data),
        .amount(amount),
        .fill_val(fill_val),
        .result(result)
    );
endmodule
// End of primitive_ppa_top.sv
