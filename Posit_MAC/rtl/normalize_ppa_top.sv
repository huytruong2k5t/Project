//-----------------------------------------------------------------------------
// File          : normalize_ppa_top.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Structural top for main posit32/3 normalize benchmark.
// $Source: $ $Revision: 1.0 $ $Log: No change to production stage boundaries. $
//-----------------------------------------------------------------------------
module normalize_ppa_top #(
    parameter int NB = 32,
    parameter int ES = 3,
    parameter int F = NB - 3 - ES,
    parameter int SF_W = $clog2(64'd4 * (longint'(NB)-64'd2) * (64'd1<<ES) + 64'd4) + 1,
    parameter int F_OUT = 2 * F + 1
)(
    input logic clk,
    input logic [F+4:0] magnitude,
    input logic sign_base,
    input logic signed [SF_W-1:0] sf_base,
    input logic alignment_tail,
    input logic is_zero_in,
    input logic is_nar_in,
    input logic [4:0] flags_in,
    output wire sign,
    output wire is_zero,
    output wire is_nar,
    output wire signed [SF_W-1:0] sf,
    output wire [F_OUT-1:0] frac,
    output wire sticky,
    output wire [4:0] flags_out
);
    normalize_ppa_boundary #(.NB(NB), .ES(ES), .F(F), .SF_W(SF_W), .F_OUT(F_OUT)) u_boundary (
        .clk(clk),
        .magnitude(magnitude),
        .sign_base(sign_base),
        .sf_base(sf_base),
        .alignment_tail(alignment_tail),
        .is_zero_in(is_zero_in),
        .is_nar_in(is_nar_in),
        .flags_in(flags_in),
        .sign(sign),
        .is_zero(is_zero),
        .is_nar(is_nar),
        .sf(sf),
        .frac(frac),
        .sticky(sticky),
        .flags_out(flags_out)
    );
endmodule
// End of normalize_ppa_top.sv
