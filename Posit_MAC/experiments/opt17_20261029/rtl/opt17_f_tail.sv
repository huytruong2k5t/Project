//-----------------------------------------------------------------------------
// File          : opt17_f_tail.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP, OPT-17 study
// Creation Date : 2026-10-29
// Description   : Q24 prepack26 to W32/Q29 fused adder and final Posit RNE.
// $Source: $ $Revision: 1.0 $ $Log: C consumed atomically at fused F1. $
//-----------------------------------------------------------------------------
module opt17_f_tail (
    input logic clk,
    input logic reset_n,
    input logic in_valid,
    output wire in_ready,
    input logic [25:0] p_acc,
    input logic p_sign,
    input logic p_zero,
    input logic p_nar,
    input logic signed [10:0] p_sf,
    input logic [4:0] p_flags,
    input logic c_valid,
    output wire c_consume,
    input logic c_sign,
    input logic c_zero,
    input logic signed [10:0] c_sf,
    input logic [25:0] c_frac,
    output wire out_valid,
    input logic out_ready,
    output wire [31:0] d,
    output wire [4:0] flags
);
    wire fused_in_valid;
    wire fused_valid;
    wire fused_ready;
    wire pack_ready;
    wire sum_sign;
    wire sum_zero;
    wire sum_nar;
    wire signed [10:0] sum_sf;
    wire [52:0] sum_frac;
    wire sum_sticky;
    wire [4:0] sum_flags;
    wire [1:0] loss;
    wire [2:0] unused_high_flags;
    assign unused_high_flags = p_flags[4:2];
    assign loss = p_flags[1:0];
    assign fused_in_valid = in_valid && c_valid;
    assign in_ready = fused_ready && c_valid;
    assign c_consume = fused_in_valid && fused_ready;
    opt17_fused_pipe u_fused (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (fused_in_valid),
        .in_ready (fused_ready),
        .out_valid (fused_valid),
        .out_ready (pack_ready),
        .p_magnitude (p_acc),
        .p_scale (p_sf),
        .p_sign (p_sign),
        .p_zero (p_zero),
        .is_nar_in (p_nar),
        .loss_in (loss),
        .c_sf (c_sf),
        .c_frac (c_frac),
        .c_sign (c_sign),
        .c_zero (c_zero),
        .sign (sum_sign),
        .is_zero (sum_zero),
        .is_nar (sum_nar),
        .sf (sum_sf),
        .frac (sum_frac),
        .sticky (sum_sticky),
        .flags_out (sum_flags)
    );
    posit_pack u_pack (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (fused_valid),
        .in_ready (pack_ready),
        .sign (sum_sign),
        .is_zero (sum_zero),
        .is_nar (sum_nar),
        .sf (sum_sf),
        .frac (sum_frac),
        .sticky (sum_sticky),
        .flags_in (sum_flags),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .d (d),
        .flags (flags)
    );
endmodule
// End of opt17_f_tail.sv
