//-----------------------------------------------------------------------------
// File          : posit_pack_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-06
// Description   : Combinational packer using the shared P1/P2 logic.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: Initial implementation of SPEC 5.9-D. $

module posit_pack_comb #(
    parameter int NB = 32,
    parameter int ES = 2,
    parameter int F_IN = 2 * (NB - 3 - ES) + 1,
    parameter int SF_W = $clog2(64'd4 * (NB - 2) * (64'd1 << ES) + 64'd4) + 1,
    parameter ROUND_MODE = "RNE"
)(
    input  logic sign,
    input  logic is_zero,
    input  logic is_nar,
    input  logic signed [SF_W-1:0] sf,
    input  logic [F_IN-1:0] frac,
    input  logic sticky,
    input  logic [4:0] flags_in,
    output wire [NB-1:0] d,
    output wire [4:0] flags
);
    wire [NB-2:0] p1_mag_trunc_d;
    wire  p1_guard_bit_d;
    wire  p1_round_bit_d;
    wire  p1_sticky_bit_d;
    wire  p1_sign_d;
    wire [2:0] p1_special_sel_d;
    wire [4:0] p1_flags_d;
    wire [NB-1:0] d_d;
    wire [4:0] flags_d;
    posit_pack_prepare #(
        .NB (NB),
        .ES (ES),
        .F_IN (F_IN),
        .SF_W (SF_W)
    ) u_prepare (
        .sign (sign),
        .is_zero (is_zero),
        .is_nar (is_nar),
        .sf (sf),
        .frac (frac),
        .sticky (sticky),
        .flags_in (flags_in),
        .mag_trunc (p1_mag_trunc_d),
        .guard_bit (p1_guard_bit_d),
        .round_bit (p1_round_bit_d),
        .sticky_bit (p1_sticky_bit_d),
        .sign_o (p1_sign_d),
        .special_sel (p1_special_sel_d),
        .flags_o (p1_flags_d)
    );
    posit_pack_finish #(
        .NB (NB),
        .ROUND_MODE (ROUND_MODE)
    ) u_finish (
        .mag_trunc (p1_mag_trunc_d),
        .guard_bit (p1_guard_bit_d),
        .round_bit (p1_round_bit_d),
        .sticky_bit (p1_sticky_bit_d),
        .sign (p1_sign_d),
        .special_sel (p1_special_sel_d),
        .flags_in (p1_flags_d),
        .d (d_d),
        .flags (flags_d)
    );
    assign d = d_d;
    assign flags = flags_d;
endmodule
//-----------------------------------------------------------------------------
// End of posit_pack_comb.sv
//-----------------------------------------------------------------------------
