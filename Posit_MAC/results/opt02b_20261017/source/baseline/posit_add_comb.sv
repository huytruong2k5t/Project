//-----------------------------------------------------------------------------
// File          : posit_add_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-12
// Description   : Combinational NF adder; shared A1/A2/A3 arithmetic leaves.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: W10 implementation, SPEC 5.8-A..D. $

module posit_add_comb #(
    parameter int NB = 32,
    parameter int ES = 2,
    parameter int F = NB - 3 - ES,
    parameter int SF_W = $clog2(64'd4 * (longint'(NB) - 64'd2) * (64'd1 << ES) + 64'd4) + 1,
    parameter int F_OUT = 2 * F + 1
)(
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
    output wire sign,
    output wire is_zero,
    output wire is_nar,
    output wire signed [SF_W-1:0] sf,
    output wire [F_OUT-1:0] frac,
    output wire sticky,
    output wire [4:0] flags_out
);
    wire [F+4:0] x;
    wire [F+4:0] y;
    wire subtract;
    wire sign_base;
    wire signed [SF_W-1:0] sf_base;
    wire alignment_tail;
    wire zero_base;
    wire nar_base;
    wire [4:0] flags_base;
    wire [F+4:0] magnitude;
    posit_add_align #(.NB(NB),
        .ES(ES),
        .F(F),
        .SF_W(SF_W)) u_align (
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
        .is_zero(zero_base),
        .is_nar(nar_base),
        .flags_o(flags_base)
    );
    posit_add_arith #(.F(F)) u_arith (
        .x(x),
        .y(y),
        .subtract(subtract),
        .magnitude(magnitude)
    );
    posit_add_normalize #(.NB(NB),
        .ES(ES),
        .F(F),
        .SF_W(SF_W),
        .F_OUT(F_OUT)) u_normalize (
        .magnitude(magnitude),
        .sign_base(sign_base),
        .sf_base(sf_base),
        .alignment_tail(alignment_tail),
        .is_zero_in(zero_base),
        .is_nar_in(nar_base),
        .flags_in(flags_base),
        .sign(sign),
        .is_zero(is_zero),
        .is_nar(is_nar),
        .sf(sf),
        .frac(frac),
        .sticky(sticky),
        .flags_out(flags_out)
    );
endmodule

//-----------------------------------------------------------------------------
// End of posit_add_comb.sv
//-----------------------------------------------------------------------------
