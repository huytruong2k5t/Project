//-----------------------------------------------------------------------------
// File          : posit_product_pack.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-06
// Description   : Internal magnitude packer; sign is a parallel metadata bit.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: Initial implementation of SPEC 5.9-D. $

`include "posit_mac.vh"

module posit_product_pack (
    input logic clk,
    input logic reset_n,
    input logic in_valid,
    output wire in_ready,
    input  logic sign,
    input  logic is_zero,
    input  logic is_nar,
    input  logic signed [10:0] sf,
    input  logic [52:0] frac,
    input  logic sticky,
    input  logic [4:0] flags_in,
    output wire out_valid,
    input logic out_ready,
    output wire [31:0] d,
    output wire [4:0] flags,
    output wire sign_o
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    // NB: 32 (original).
    localparam int NB = 32;
    // ES: 2 (original).
    
    // F_IN: 2 * (NB - 3 - ES) + 1 (original).
    
    // SF_W: $clog2(64'd4 * (longint'(NB) - 64'd2) * (64'd1 << ES) + 64'd4) + 1 (original).
    
    // ROUND_MODE: "RNE" (original).
    localparam [39:0] ROUND_MODE = 40'h524e45;

    wire [NB-2:0] p1_mag_trunc_d;
    wire  p1_guard_bit_d;
    wire  p1_round_bit_d;
    wire  p1_sticky_bit_d;
    wire  p1_sign_d;
    wire [2:0] p1_special_sel_d;
    wire [4:0] p1_flags_d;
    wire [NB-1:0] d_d;
    wire [4:0] flags_d;

    (* ASYNC_REG = "TRUE" *) logic meta_sync1;
    (* ASYNC_REG = "TRUE" *) logic meta_sync2;
    wire reset_b_sync_clk;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end

    assign reset_b_sync_clk = meta_sync2;
    posit_pack_prepare  u_prepare (
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

    generate
        if (ROUND_MODE == "RNE") begin : g_rne
            logic [NB-2:0] p1_mag_trunc_q;
            logic  p1_guard_bit_q;
            logic  p1_round_bit_q;
            logic  p1_sticky_bit_q;
            logic  p1_sign_q;
            logic [2:0] p1_special_sel_q;
            logic [4:0] p1_flags_q;
            logic p1_valid_q;
            logic p2_valid_q;
            logic [NB-1:0] d_q;
            logic [4:0] flags_q;
            logic sign_q;
            wire p1_ready;
            wire p2_ready;

            assign p2_ready = !p2_valid_q || out_ready;
            assign p1_ready = !p1_valid_q || p2_ready;
            assign in_ready = reset_b_sync_clk && p1_ready;
            assign out_valid = reset_b_sync_clk && p2_valid_q;
            assign d = d_q;
            assign flags = flags_q;
            assign sign_o = sign_q;

            always_ff @(posedge clk or negedge reset_b_sync_clk) begin
                if (!reset_b_sync_clk) begin
                    p1_valid_q <= 1'b0;
                    p1_mag_trunc_q <= '0;
                    p1_guard_bit_q <= '0;
                    p1_round_bit_q <= '0;
                    p1_sticky_bit_q <= '0;
                    p1_sign_q <= '0;
                    p1_special_sel_q <= '0;
                    p1_flags_q <= '0;
                end else if (p1_ready) begin
                    p1_valid_q <= `CK2Q in_valid;
                    if (in_valid) begin
                        p1_mag_trunc_q <= `CK2Q p1_mag_trunc_d;
                        p1_guard_bit_q <= `CK2Q p1_guard_bit_d;
                        p1_round_bit_q <= `CK2Q p1_round_bit_d;
                        p1_sticky_bit_q <= `CK2Q p1_sticky_bit_d;
                        p1_sign_q <= `CK2Q p1_sign_d;
                        p1_special_sel_q <= `CK2Q p1_special_sel_d;
                        p1_flags_q <= `CK2Q p1_flags_d;
                    end
                end
            end
    posit_pack_finish  u_finish (
        .mag_trunc (p1_mag_trunc_q),
        .guard_bit (p1_guard_bit_q),
        .round_bit (p1_round_bit_q),
        .sticky_bit (p1_sticky_bit_q),
        .sign (1'b0),
        .special_sel (p1_special_sel_q),
        .flags_in (p1_flags_q),
        .d (d_d),
        .flags (flags_d)
    );

            always_ff @(posedge clk or negedge reset_b_sync_clk) begin
                if (!reset_b_sync_clk) begin
                    p2_valid_q <= 1'b0;
                    d_q <= '0;
                    flags_q <= '0;
                    sign_q <= 1'b0;
                end else if (p2_ready) begin
                    p2_valid_q <= `CK2Q p1_valid_q;
                    if (p1_valid_q) begin
                        d_q <= `CK2Q d_d;
                        flags_q <= `CK2Q flags_d;
                        sign_q <= `CK2Q p1_sign_q;
                    end
                end
            end
        end else if (ROUND_MODE == "TRUNC") begin : g_trunc
            logic valid_q;
            logic [NB-1:0] d_q;
            logic [4:0] flags_q;
            logic sign_q;
            wire output_ready;

            assign output_ready = !valid_q || out_ready;
            assign in_ready = reset_b_sync_clk && output_ready;
            assign out_valid = reset_b_sync_clk && valid_q;
            assign d = d_q;
            assign flags = flags_q;
            assign sign_o = sign_q;
    posit_pack_finish  u_finish (
        .mag_trunc (p1_mag_trunc_d),
        .guard_bit (p1_guard_bit_d),
        .round_bit (p1_round_bit_d),
        .sticky_bit (p1_sticky_bit_d),
        .sign (1'b0),
        .special_sel (p1_special_sel_d),
        .flags_in (p1_flags_d),
        .d (d_d),
        .flags (flags_d)
    );

            always_ff @(posedge clk or negedge reset_b_sync_clk) begin
                if (!reset_b_sync_clk) begin
                    valid_q <= 1'b0;
                    d_q <= '0;
                    flags_q <= '0;
                    sign_q <= 1'b0;
                end else if (output_ready) begin
                    valid_q <= `CK2Q in_valid;
                    if (in_valid) begin
                        d_q <= `CK2Q d_d;
                        flags_q <= `CK2Q flags_d;
                        sign_q <= `CK2Q p1_sign_d;
                    end
                end
            end
        end else begin : g_invalid
            initial $fatal(1, "posit_pack: unsupported ROUND_MODE");
        end
    endgenerate
endmodule
//-----------------------------------------------------------------------------
// End of posit_pack.sv
//-----------------------------------------------------------------------------
