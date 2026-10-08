//-----------------------------------------------------------------------------
// File          : packer_ppa_boundary.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-07
// Description   : Registered boundaries for standalone packer PPA comparison.
//                 Fixed posit32 ES2/F_IN55; continuous stream, no output stall.
//                 This benchmark is not the MAC top or a board pin assignment.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: Initial Quartus resource/timing benchmark. $

`include "posit_mac.vh"
module packer_ppa_boundary (
    input logic clk,
    input logic reset_n,
    input logic  sign_i,
    input logic  is_zero_i,
    input logic  is_nar_i,
    input logic signed [9:0] sf_i,
    input logic [54:0] frac_i,
    input logic  sticky_i,
    input logic [4:0] flags_in_i,
    output logic  sign_q,
    output logic  is_zero_q,
    output logic  is_nar_q,
    output logic signed [9:0] sf_q,
    output logic [54:0] frac_q,
    output logic  sticky_q,
    output logic [4:0] flags_in_q,
    input logic pack_in_ready,
    output wire pack_in_valid,
    output wire pack_out_ready,
    input logic pack_out_valid,
    input logic [31:0] pack_d,
    input logic [4:0] pack_flags,
    output logic out_valid,
    output logic [31:0] d,
    output logic [4:0] flags
);

    (* ASYNC_REG = "TRUE" *) logic meta_sync1;
    (* ASYNC_REG = "TRUE" *) logic meta_sync2;
    wire reset_b_sync_clk;
    assign reset_b_sync_clk = meta_sync2;
    assign pack_in_valid = reset_b_sync_clk;
    assign pack_out_ready = 1'b1;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end
    always_ff @(posedge clk or negedge reset_b_sync_clk) begin
        if (!reset_b_sync_clk) begin
            sign_q <= '0;
            is_zero_q <= '0;
            is_nar_q <= '0;
            sf_q <= '0;
            frac_q <= '0;
            sticky_q <= '0;
            flags_in_q <= '0;
            out_valid <= 1'b0;
            d <= '0;
            flags <= '0;
        end else begin
            if (pack_in_ready) begin
                sign_q <= `CK2Q sign_i;
                is_zero_q <= `CK2Q is_zero_i;
                is_nar_q <= `CK2Q is_nar_i;
                sf_q <= `CK2Q sf_i;
                frac_q <= `CK2Q frac_i;
                sticky_q <= `CK2Q sticky_i;
                flags_in_q <= `CK2Q flags_in_i;
            end
            out_valid <= `CK2Q pack_out_valid;
            d <= `CK2Q pack_d;
            flags <= `CK2Q pack_flags;
        end
    end
endmodule
