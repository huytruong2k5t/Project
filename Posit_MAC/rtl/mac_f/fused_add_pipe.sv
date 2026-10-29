//-----------------------------------------------------------------------------
// File          : fused_add_pipe.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : W12-F-1 fused datapath, approximate posit(32,3).
// $Source: $ $Revision: 1.0 $ $Log: Week13 RTL implementation. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module fused_add_pipe (
    input  logic clk,
    input  logic reset_n,
    input  logic in_valid,
    output wire in_ready,
    output wire out_valid,
    input  logic out_ready,
    input  logic [13:0] p_magnitude,
    input  logic signed [10:0] p_scale,
    input  logic p_sign,
    input  logic p_zero,
    input  logic is_nar_in,
    input  logic [1:0] loss_in,
    input  logic signed [10:0] c_sf,
    input  logic [25:0] c_frac,
    input  logic c_sign,
    input  logic c_zero,
    output wire sign,
    output wire is_zero,
    output wire is_nar,
    output wire signed [10:0] sf,
    output wire [52:0] frac,
    output wire sticky,
    output wire [4:0] flags_out
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    localparam int SF_W = 11;

    typedef struct packed {
        logic [30:0] large_value;
        logic [30:0] small_value;
        logic [4:0] shift_amount;
        logic shift_all;
        logic base_sign;
        logic subtract;
        logic signed [SF_W-1:0] anchor;
        logic nar;
        logic [1:0] loss;
    } f1_t;
    f1_t f1_d;
    f1_t f1_q;
    typedef struct packed {
        logic [30:0] large_value;
        logic [30:0] small_value;
        logic base_sign;
        logic subtract;
        logic signed [SF_W-1:0] anchor;
        logic residual;
        logic nar;
        logic [1:0] loss;
    } f2_t;
    f2_t f2_d;
    f2_t f2_q;
    typedef struct packed {
        logic signed [31:0] retained_sum;
        logic base_sign;
        logic subtract;
        logic signed [SF_W-1:0] anchor;
        logic residual;
        logic nar;
        logic [1:0] loss;
    } f3_t;
    f3_t f3_d;
    f3_t f3_q;
    typedef struct packed {
        logic [30:0] magnitude;
        logic sign;
        logic signed [SF_W-1:0] anchor;
        logic residual;
        logic nar;
        logic [1:0] loss;
    } f4_t;
    f4_t f4_d;
    f4_t f4_q;
    typedef struct packed {
        logic sign;
        logic zero;
        logic nar;
        logic signed [SF_W-1:0] sf;
        logic [52:0] frac;
        logic sticky;
        logic [1:0] loss;
    } f5_t;
    f5_t f5_d;
    f5_t f5_q;
    logic [4:0] valid_q;
    wire [4:0] ready /* verilator split_var */;
    (* ASYNC_REG = "TRUE" *) logic meta_sync1;
    (* ASYNC_REG = "TRUE" *) logic meta_sync2;
    wire borrow;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end
    assign ready[4] = !valid_q[4] || out_ready;
    for (genvar g = 0; g < 4; g++) begin : g_ready
        assign ready[g] = !valid_q[g] || ready[g+1];
    end
    assign in_ready = meta_sync2 && ready[0];
    assign out_valid = meta_sync2 && valid_q[4];
    fused_prepare_comb  u_prepare (
        .p_magnitude (p_magnitude),
        .p_scale (p_scale),
        .p_sign (p_sign),
        .p_zero (p_zero),
        .c_sf (c_sf),
        .c_frac (c_frac),
        .c_sign (c_sign),
        .c_zero (c_zero),
        .large_seed (f1_d.large_value),
        .small_seed (f1_d.small_value),
        .anchor (f1_d.anchor),
        .shift_amount (f1_d.shift_amount),
        .shift_all (f1_d.shift_all),
        .base_sign (f1_d.base_sign),
        .subtract (f1_d.subtract)
    );
    assign f1_d.nar = is_nar_in;
    assign f1_d.loss = loss_in;
    fused_align_comb u_align (
        .small_seed (f1_q.small_value),
        .shift_amount (f1_q.shift_amount),
        .shift_all (f1_q.shift_all),
        .aligned_small (f2_d.small_value),
        .residual (f2_d.residual)
    );
    fused_arith_comb u_arith (
        .large_value (f2_q.large_value),
        .small_value (f2_q.small_value),
        .subtract (f2_q.subtract),
        .retained_sum (f3_d.retained_sum)
    );
    fused_abs_borrow_comb u_abs (
        .retained_sum (f3_q.retained_sum),
        .base_sign (f3_q.base_sign),
        .subtract (f3_q.subtract),
        .residual (f3_q.residual),
        .magnitude (f4_d.magnitude),
        .sign (f4_d.sign),
        .borrow (borrow)
    );
    fused_norm_comb  u_norm (
        .magnitude (f4_q.magnitude),
        .anchor (f4_q.anchor),
        .is_zero (f5_d.zero),
        .sf (f5_d.sf),
        .frac (f5_d.frac)
    );
    assign f2_d.large_value = f1_q.large_value;
    assign f2_d.base_sign = f1_q.base_sign;
    assign f2_d.subtract = f1_q.subtract;
    assign f2_d.anchor = f1_q.anchor;
    assign f2_d.nar = f1_q.nar;
    assign f2_d.loss = f1_q.loss;
    assign f3_d.base_sign = f2_q.base_sign;
    assign f3_d.subtract = f2_q.subtract;
    assign f3_d.anchor = f2_q.anchor;
    assign f3_d.residual = f2_q.residual;
    assign f3_d.nar = f2_q.nar;
    assign f3_d.loss = f2_q.loss;
    assign f4_d.anchor = f3_q.anchor;
    assign f4_d.residual = f3_q.residual;
    assign f4_d.nar = f3_q.nar;
    assign f4_d.loss = f3_q.loss;
    assign f5_d.sign = f4_q.sign;
    assign f5_d.nar = f4_q.nar;
    assign f5_d.sticky = f4_q.residual;
    assign f5_d.loss = f4_q.loss;
    // NaR has priority over the arithmetic zero and residual metadata.
    assign sign = f5_q.nar || f5_q.sign;
    assign is_zero = !f5_q.nar && f5_q.zero;
    assign is_nar = f5_q.nar;
    assign sf = f5_q.nar ? '0 : f5_q.sf;
    assign frac = f5_q.nar ? '0 : f5_q.frac;
    assign sticky = !f5_q.nar && f5_q.sticky;
    assign flags_out = f5_q.nar ? 5'b10000 : {3'b000, f5_q.loss};
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            valid_q[0] <= 1'b0;
            f1_q <= '0;
        end else if (ready[0]) begin
            valid_q[0] <= `CK2Q in_valid;
            if (in_valid) begin
                f1_q <= `CK2Q f1_d;
            end
        end
    end
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            valid_q[1] <= 1'b0;
            f2_q <= '0;
        end else if (ready[1]) begin
            valid_q[1] <= `CK2Q valid_q[0];
            if (valid_q[0]) begin
                f2_q <= `CK2Q f2_d;
            end
        end
    end
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            valid_q[2] <= 1'b0;
            f3_q <= '0;
        end else if (ready[2]) begin
            valid_q[2] <= `CK2Q valid_q[1];
            if (valid_q[1]) begin
                f3_q <= `CK2Q f3_d;
            end
        end
    end
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            valid_q[3] <= 1'b0;
            f4_q <= '0;
        end else if (ready[3]) begin
            valid_q[3] <= `CK2Q valid_q[2];
            if (valid_q[2]) begin
                f4_q <= `CK2Q f4_d;
            end
        end
    end
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            valid_q[4] <= 1'b0;
            f5_q <= '0;
        end else if (ready[4]) begin
            valid_q[4] <= `CK2Q valid_q[3];
            if (valid_q[3]) begin
                f5_q <= `CK2Q f5_d;
            end
        end
    end
    // Verification consumes borrow; no debug-only register or top port.
    // synthesis translate_off
    always @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
        end else if (meta_sync2) begin
            if (valid_q[2] && !f3_q.nar) begin
                assert (!(f3_q.retained_sum == 0 && f3_q.residual))
                    else $fatal(1, "F: zero retained sum with nonzero residual");
                assert (!(borrow && f4_d.magnitude == 0))
                    else $fatal(1, "F: residual borrow exhausted magnitude");
            end
            if (valid_q[3] && !f4_q.nar && f4_q.residual) begin
                assert (|f4_q.magnitude[30:28])
                    else $fatal(1, "F: residual with deep normalization");
            end
        end
    end
    // synthesis translate_on
endmodule
// End of fused_add_pipe.sv
