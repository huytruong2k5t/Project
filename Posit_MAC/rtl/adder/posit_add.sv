//-----------------------------------------------------------------------------
// File          : posit_add.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-12
// Description   : Three-stage elastic NF adder, shared combinational leaves.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: SPEC 5.8-A..D, async assert / two-FF synchronous reset release. $

`include "posit_mac.vh"

module posit_add (
    input logic clk,
    input logic reset_n,
    input logic in_valid,
    output wire in_ready,
    output wire out_valid,
    input logic out_ready,
    input logic a_sign,
    input logic a_is_zero,
    input logic a_is_nar,
    input logic signed [10:0] a_sf,
    input logic [25:0] a_frac,
    input logic b_sign,
    input logic b_is_zero,
    input logic b_is_nar,
    input logic signed [10:0] b_sf,
    input logic [25:0] b_frac,
    input logic [4:0] flags_in,
    output logic sign,
    output logic is_zero,
    output logic is_nar,
    output logic signed [10:0] sf,
    output logic [52:0] frac,
    output logic sticky,
    output logic [4:0] flags_out
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    
    
    localparam int F = 26;
    localparam int SF_W = 11;
    localparam int F_OUT = 53;


    typedef struct packed {
        logic [F+4:0] x;
        logic [F+4:0] y;
        logic subtract;
        logic sign_base;
        logic signed [SF_W-1:0] sf_base;
        logic alignment_tail;
        logic is_zero;
        logic is_nar;
        logic [4:0] flags;
    } align_context_t;
    typedef struct packed {
        logic [F+4:0] magnitude;
        logic sign_base;
        logic signed [SF_W-1:0] sf_base;
        logic alignment_tail;
        logic is_zero;
        logic is_nar;
        logic [4:0] flags;
    } arith_context_t;
    align_context_t a1_d;
    align_context_t a1_q;
    arith_context_t a2_q;
    wire [F+4:0] magnitude_d;
    wire sign_d;
    wire zero_d;
    wire nar_d;
    wire signed [SF_W-1:0] sf_d;
    wire [F_OUT-1:0] frac_d;
    wire sticky_d;
    wire [4:0] flags_d;
    logic valid1_q;
    logic valid2_q;
    logic valid3_q;
    (* ASYNC_REG = "TRUE" *) logic meta_sync1;
    (* ASYNC_REG = "TRUE" *) logic meta_sync2;
    wire reset_b_sync_clk;
    wire ready3;
    wire ready2;
    wire ready1;

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
    assign ready3 = !valid3_q || out_ready;
    assign ready2 = !valid2_q || ready3;
    assign ready1 = !valid1_q || ready2;
    assign in_ready = reset_b_sync_clk && ready1;
    assign out_valid = reset_b_sync_clk && valid3_q;

    posit_add_align  u_align (
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
        .x(a1_d.x),
        .y(a1_d.y),
        .subtract(a1_d.subtract),
        .sign_base(a1_d.sign_base),
        .sf_base(a1_d.sf_base),
        .alignment_tail(a1_d.alignment_tail),
        .is_zero(a1_d.is_zero),
        .is_nar(a1_d.is_nar),
        .flags_o(a1_d.flags)
    );
    posit_add_arith  u_arith (
        .x(a1_q.x),
        .y(a1_q.y),
        .subtract(a1_q.subtract),
        .magnitude(magnitude_d)
    );
    posit_add_normalize  u_normalize (
        .magnitude(a2_q.magnitude),
        .sign_base(a2_q.sign_base),
        .sf_base(a2_q.sf_base),
        .alignment_tail(a2_q.alignment_tail),
        .is_zero_in(a2_q.is_zero),
        .is_nar_in(a2_q.is_nar),
        .flags_in(a2_q.flags),
        .sign(sign_d),
        .is_zero(zero_d),
        .is_nar(nar_d),
        .sf(sf_d),
        .frac(frac_d),
        .sticky(sticky_d),
        .flags_out(flags_d)
    );

    always_ff @(posedge clk or negedge reset_b_sync_clk) begin
        if (!reset_b_sync_clk) begin
            valid1_q <= 1'b0;
            a1_q <= '0;
        end else if (ready1) begin
            valid1_q <= `CK2Q in_valid;
            if (in_valid) begin
                a1_q <= `CK2Q a1_d;
            end
        end
    end
    always_ff @(posedge clk or negedge reset_b_sync_clk) begin
        if (!reset_b_sync_clk) begin
            valid2_q <= 1'b0;
            a2_q <= '0;
        end else if (ready2) begin
            valid2_q <= `CK2Q valid1_q;
            if (valid1_q) begin
                a2_q.magnitude <= `CK2Q magnitude_d;
                a2_q.sign_base <= `CK2Q a1_q.sign_base;
                a2_q.sf_base <= `CK2Q a1_q.sf_base;
                a2_q.alignment_tail <= `CK2Q a1_q.alignment_tail;
                a2_q.is_zero <= `CK2Q a1_q.is_zero;
                a2_q.is_nar <= `CK2Q a1_q.is_nar;
                a2_q.flags <= `CK2Q a1_q.flags;
            end
        end
    end
    always_ff @(posedge clk or negedge reset_b_sync_clk) begin
        if (!reset_b_sync_clk) begin
            valid3_q <= 1'b0;
            sign <= 1'b0;
            is_zero <= 1'b0;
            is_nar <= 1'b0;
            sf <= '0;
            frac <= '0;
            sticky <= 1'b0;
            flags_out <= '0;
        end else if (ready3) begin
            valid3_q <= `CK2Q valid2_q;
            if (valid2_q) begin
                sign <= `CK2Q sign_d;
                is_zero <= `CK2Q zero_d;
                is_nar <= `CK2Q nar_d;
                sf <= `CK2Q sf_d;
                frac <= `CK2Q frac_d;
                sticky <= `CK2Q sticky_d;
                flags_out <= `CK2Q flags_d;
            end
        end
    end
endmodule
