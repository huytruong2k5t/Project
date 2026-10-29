//-----------------------------------------------------------------------------
// File          : opt17_nf_tail.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP, OPT-17 study
// Creation Date : 2026-10-29
// Description   : FULL_TERM NF product RNE/parse, add C, final RNE.
//                 C is consumed by the adder, not by product pack P1.
// $Source: $ $Revision: 1.0 $ $Log: Preserve OPT-03 tail boundaries. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module opt17_nf_tail (
    input logic clk,
    input logic reset_n,
    input logic in_valid,
    output wire in_ready,
    input logic [53:0] p_acc,
    input logic p_mode,
    input logic p_sign,
    input logic p_zero,
    input logic p_nar,
    input logic signed [10:0] p_sf,
    input logic [4:0] p_flags,
    input logic c_valid,
    output wire c_consume,
    input logic c_sign,
    input logic c_zero,
    input logic c_nar,
    input logic signed [10:0] c_sf,
    input logic [25:0] c_frac,
    output wire out_valid,
    input logic out_ready,
    output wire [31:0] d,
    output wire [4:0] flags
);
    (* ASYNC_REG = "TRUE" *) logic meta_sync1;
    (* ASYNC_REG = "TRUE" *) logic meta_sync2;
    wire signed [10:0] normalized_sf;
    wire [52:0] normalized_frac;
    wire numerical_zero;
    wire product_valid;
    wire product_ready;
    wire product_capture;
    wire [31:0] product_magnitude;
    wire product_sign_encoded;
    wire [4:0] product_flags;
    wire product_sign;
    wire product_zero;
    wire product_nar;
    wire signed [10:0] product_sf;
    wire [25:0] product_frac;
    logic norm_valid_q;
    logic norm_sign_q;
    logic norm_zero_q;
    logic norm_nar_q;
    logic signed [10:0] norm_sf_q;
    logic [25:0] norm_frac_q;
    logic [4:0] norm_flags_q;
    wire add_in_valid;
    wire add_ready;
    wire add_valid;
    wire sum_sign;
    wire sum_zero;
    wire sum_nar;
    wire signed [10:0] sum_sf;
    wire [52:0] sum_frac;
    wire sum_sticky;
    wire [4:0] sum_flags;
    wire pack_ready;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end
    assign numerical_zero = 1'b0;
    opt17_norm_nf u_norm (
        .cfg_mode (p_mode),
        .acc (p_acc),
        .sf (p_sf),
        .sf_norm (normalized_sf),
        .frac_norm (normalized_frac)
    );
    assign add_in_valid = norm_valid_q && c_valid;
    assign c_consume = add_in_valid && add_ready;
    assign product_ready = !norm_valid_q || c_consume;
    assign product_capture = product_valid && product_ready;
    posit_product_pack u_product_pack (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .sign (p_sign),
        .is_zero (p_zero),
        .is_nar (p_nar),
        .sf (normalized_sf),
        .frac (normalized_frac),
        .sticky (numerical_zero),
        .flags_in (p_flags),
        .out_valid (product_valid),
        .out_ready (product_ready),
        .d (product_magnitude),
        .sign_o (product_sign_encoded),
        .flags (product_flags)
    );
    posit_magnitude_parse u_product_parse (
        .p (product_magnitude),
        .sign_i (product_sign_encoded),
        .s (product_sign),
        .is_zero (product_zero),
        .is_nar (product_nar),
        .sf (product_sf),
        .frac (product_frac)
    );
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            norm_valid_q <= 1'b0;
            norm_sign_q <= 1'b0;
            norm_zero_q <= 1'b0;
            norm_nar_q <= 1'b0;
            norm_sf_q <= '0;
            norm_frac_q <= '0;
            norm_flags_q <= '0;
        end else if (product_ready) begin
            norm_valid_q <= `CK2Q product_valid;
            if (product_capture) begin
                norm_sign_q <= `CK2Q product_sign;
                norm_zero_q <= `CK2Q product_zero;
                norm_nar_q <= `CK2Q product_nar;
                norm_sf_q <= `CK2Q product_sf;
                norm_frac_q <= `CK2Q product_frac;
                norm_flags_q <= `CK2Q product_flags;
            end
        end
    end
    posit_add u_add (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (add_in_valid),
        .in_ready (add_ready),
        .out_valid (add_valid),
        .out_ready (pack_ready),
        .a_sign (norm_sign_q),
        .a_is_zero (norm_zero_q),
        .a_is_nar (norm_nar_q),
        .a_sf (norm_sf_q),
        .a_frac (norm_frac_q),
        .b_sign (c_sign),
        .b_is_zero (c_zero),
        .b_is_nar (c_nar),
        .b_sf (c_sf),
        .b_frac (c_frac),
        .flags_in (norm_flags_q),
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
        .in_valid (add_valid),
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
// End of opt17_nf_tail.sv
