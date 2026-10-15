//-----------------------------------------------------------------------------
// File          : normalize_ppa_boundary.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Identical input/output register banks for normalize leaf STA.
// $Source: $ $Revision: 1.0 $ $Log: Measurement only, no production pipeline. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module normalize_ppa_boundary #(
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
    output logic sign,
    output logic is_zero,
    output logic is_nar,
    output logic signed [SF_W-1:0] sf,
    output logic [F_OUT-1:0] frac,
    output logic sticky,
    output logic [4:0] flags_out
);
    logic [F+4:0] magnitude_q;
    logic sign_base_q;
    logic signed [SF_W-1:0] sf_base_q;
    logic alignment_tail_q;
    logic is_zero_in_q;
    logic is_nar_in_q;
    logic [4:0] flags_in_q;
    wire sign_d;
    wire is_zero_d;
    wire is_nar_d;
    wire signed [SF_W-1:0] sf_d;
    wire [F_OUT-1:0] frac_d;
    wire sticky_d;
    wire [4:0] flags_out_d;

    posit_add_normalize #(.NB(NB), .ES(ES), .F(F), .SF_W(SF_W), .F_OUT(F_OUT)) u_normalize (
        .magnitude(magnitude_q),
        .sign_base(sign_base_q),
        .sf_base(sf_base_q),
        .alignment_tail(alignment_tail_q),
        .is_zero_in(is_zero_in_q),
        .is_nar_in(is_nar_in_q),
        .flags_in(flags_in_q),
        .sign(sign_d),
        .is_zero(is_zero_d),
        .is_nar(is_nar_d),
        .sf(sf_d),
        .frac(frac_d),
        .sticky(sticky_d),
        .flags_out(flags_out_d)
    );
    // Measurement banks overwrite every cycle; they do not own reset/valid state.
    always_ff @(posedge clk) begin
        magnitude_q <= `CK2Q magnitude;
        sign_base_q <= `CK2Q sign_base;
        sf_base_q <= `CK2Q sf_base;
        alignment_tail_q <= `CK2Q alignment_tail;
        is_zero_in_q <= `CK2Q is_zero_in;
        is_nar_in_q <= `CK2Q is_nar_in;
        flags_in_q <= `CK2Q flags_in;
        sign <= `CK2Q sign_d;
        is_zero <= `CK2Q is_zero_d;
        is_nar <= `CK2Q is_nar_d;
        sf <= `CK2Q sf_d;
        frac <= `CK2Q frac_d;
        sticky <= `CK2Q sticky_d;
        flags_out <= `CK2Q flags_out_d;
    end
endmodule
// End of normalize_ppa_boundary.sv
