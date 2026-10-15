//-----------------------------------------------------------------------------
// File          : align_ppa_top.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Structural top; main32/3 fixed alignment benchmark.
// $Source: $ $Revision: 1.0 $ $Log: Measurement only; identical input/output banks. $
//-----------------------------------------------------------------------------
module align_ppa_top #(
    parameter int NB = 32,
    parameter int ES = 3,
    parameter int F = NB - 3 - ES,
    parameter int SF_W = $clog2(64'd4 * (longint'(NB) - 64'd2) * (64'd1 << ES) + 64'd4) + 1
)(
    input logic clk,
    input logic a_sign,
    input logic a_is_zero,
    input logic a_is_nar,
    input logic signed [SF_W-1:0] a_sf,
    input logic [F-1:0] a_frac,
    input logic b_sign,
    input logic b_is_zero,
    input logic b_is_nar,
    input logic signed [SF_W-1:0] b_sf,
    input logic [F-1:0] b_frac,
    input logic [4:0] flags_in,
    output wire [F+4:0] x,
    output wire [F+4:0] y,
    output wire subtract,
    output wire sign_base,
    output wire signed [SF_W-1:0] sf_base,
    output wire alignment_tail,
    output wire is_zero,
    output wire is_nar,
    output wire [4:0] flags_o
);
    align_ppa_boundary #(.NB(NB), .ES(ES), .F(F), .SF_W(SF_W)) u_boundary (
        .clk(clk),
        .a_sign(a_sign),
        .a_is_zero(a_is_zero),
        .a_is_nar(a_is_nar),
        .a_sf(a_sf),
        .a_frac(a_frac),
        .b_sign(b_sign),
        .b_is_zero(b_is_zero),
        .b_is_nar(b_is_nar),
        .b_sf(b_sf),
        .b_frac(b_frac),
        .flags_in(flags_in),
        .x(x),
        .y(y),
        .subtract(subtract),
        .sign_base(sign_base),
        .sf_base(sf_base),
        .alignment_tail(alignment_tail),
        .is_zero(is_zero),
        .is_nar(is_nar),
        .flags_o(flags_o)
    );
endmodule
// End of align_ppa_top.sv
