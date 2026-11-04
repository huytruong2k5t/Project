//-----------------------------------------------------------------------------
// File: quire_units.sv | Posit MAC IP | 2026-11-03
// Verification top for alignment, atomic bank and READ normalization/packer.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module quire_units (
    input logic clk,
    input logic reset_n,
    input logic [25:0] magnitude,
    input logic sign,
    input logic signed [10:0] sf,
    output wire [971:0] term,
    output wire align_error,
    input logic bank_valid,
    output wire bank_ready,
    input logic clear,
    input logic [971:0] bank_term,
    input logic term_nar,
    input logic term_invalid,
    input logic term_loss,
    input logic term_cut,
    output wire bank_done,
    output wire [971:0] bank_q,
    output wire [10:0] q_count,
    output wire q_nar,
    output wire q_invalid,
    output wire q_loss,
    output wire q_cut,
    output wire q_overflow,
    input logic read_valid,
    output wire read_ready,
    input logic [971:0] read_q,
    input logic read_nar,
    input logic read_invalid,
    input logic read_loss,
    input logic read_cut,
    output wire norm_valid,
    output wire norm_sign,
    output wire norm_zero,
    output wire norm_nar,
    output wire signed [10:0] norm_sf,
    output wire [52:0] norm_frac,
    output wire norm_sticky,
    output wire [4:0] norm_flags,
    output wire out_valid,
    input logic out_ready,
    output wire [31:0] d,
    output wire [4:0] flags
);
    wire pack_ready;
    quire_align_comb u_align (
        .magnitude (magnitude),
        .sign (sign),
        .sf (sf),
        .term (term),
        .align_error (align_error)
    );
    quire_bank u_bank (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (bank_valid),
        .in_ready (bank_ready),
        .clear (clear),
        .term (bank_term),
        .term_nar (term_nar),
        .term_invalid (term_invalid),
        .term_loss (term_loss),
        .term_cut (term_cut),
        .done (bank_done),
        .q_value (bank_q),
        .q_count (q_count),
        .q_nar (q_nar),
        .q_invalid (q_invalid),
        .q_loss (q_loss),
        .q_cut (q_cut),
        .q_overflow (q_overflow)
    );
    quire_read u_read (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (read_valid),
        .in_ready (read_ready),
        .q_value (read_q),
        .q_nar (read_nar),
        .q_invalid (read_invalid),
        .q_loss (read_loss),
        .q_cut (read_cut),
        .out_valid (norm_valid),
        .out_ready (pack_ready),
        .sign (norm_sign),
        .is_zero (norm_zero),
        .is_nar (norm_nar),
        .sf (norm_sf),
        .frac (norm_frac),
        .sticky (norm_sticky),
        .flags_in (norm_flags)
    );
    posit_pack u_pack (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (norm_valid),
        .in_ready (pack_ready),
        .sign (norm_sign),
        .is_zero (norm_zero),
        .is_nar (norm_nar),
        .sf (norm_sf),
        .frac (norm_frac),
        .sticky (norm_sticky),
        .flags_in (norm_flags),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .d (d),
        .flags (flags)
    );
endmodule
// End of quire_units.sv
