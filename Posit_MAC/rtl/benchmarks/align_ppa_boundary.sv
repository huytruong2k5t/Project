//-----------------------------------------------------------------------------
// File          : align_ppa_boundary.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Registered full-I/O benchmark for the alignment leaf.
// $Source: $ $Revision: 1.0 $ $Log: Measurement only; identical input/output banks. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module align_ppa_boundary #(
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
    output logic [F+4:0] x,
    output logic [F+4:0] y,
    output logic subtract,
    output logic sign_base,
    output logic signed [SF_W-1:0] sf_base,
    output logic alignment_tail,
    output logic is_zero,
    output logic is_nar,
    output logic [4:0] flags_o
);
    logic a_sign_q;
    logic a_is_zero_q;
    logic a_is_nar_q;
    logic signed [SF_W-1:0] a_sf_q;
    logic [F-1:0] a_frac_q;
    logic b_sign_q;
    logic b_is_zero_q;
    logic b_is_nar_q;
    logic signed [SF_W-1:0] b_sf_q;
    logic [F-1:0] b_frac_q;
    logic [4:0] flags_in_q;
    logic [F+4:0] x_d;
    logic [F+4:0] y_d;
    logic subtract_d;
    logic sign_base_d;
    logic signed [SF_W-1:0] sf_base_d;
    logic alignment_tail_d;
    logic is_zero_d;
    logic is_nar_d;
    logic [4:0] flags_o_d;

    posit_add_align #(.NB(NB), .ES(ES), .F(F), .SF_W(SF_W)) u_align (
        .a_sign(a_sign_q),
        .a_is_zero(a_is_zero_q),
        .a_is_nar(a_is_nar_q),
        .a_sf(a_sf_q),
        .a_frac(a_frac_q),
        .b_sign(b_sign_q),
        .b_is_zero(b_is_zero_q),
        .b_is_nar(b_is_nar_q),
        .b_sf(b_sf_q),
        .b_frac(b_frac_q),
        .flags_in(flags_in_q),
        .x(x_d),
        .y(y_d),
        .subtract(subtract_d),
        .sign_base(sign_base_d),
        .sf_base(sf_base_d),
        .alignment_tail(alignment_tail_d),
        .is_zero(is_zero_d),
        .is_nar(is_nar_d),
        .flags_o(flags_o_d)
    );
    // No valid/state is owned by these overwritten-every-cycle measurement banks.
    always_ff @(posedge clk) begin
        a_sign_q <= `CK2Q a_sign;
        a_is_zero_q <= `CK2Q a_is_zero;
        a_is_nar_q <= `CK2Q a_is_nar;
        a_sf_q <= `CK2Q a_sf;
        a_frac_q <= `CK2Q a_frac;
        b_sign_q <= `CK2Q b_sign;
        b_is_zero_q <= `CK2Q b_is_zero;
        b_is_nar_q <= `CK2Q b_is_nar;
        b_sf_q <= `CK2Q b_sf;
        b_frac_q <= `CK2Q b_frac;
        flags_in_q <= `CK2Q flags_in;
        x <= `CK2Q x_d;
        y <= `CK2Q y_d;
        subtract <= `CK2Q subtract_d;
        sign_base <= `CK2Q sign_base_d;
        sf_base <= `CK2Q sf_base_d;
        alignment_tail <= `CK2Q alignment_tail_d;
        is_zero <= `CK2Q is_zero_d;
        is_nar <= `CK2Q is_nar_d;
        flags_o <= `CK2Q flags_o_d;
    end
endmodule
// End of align_ppa_boundary.sv
