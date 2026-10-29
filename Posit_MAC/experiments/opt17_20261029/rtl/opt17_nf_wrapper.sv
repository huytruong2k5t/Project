//-----------------------------------------------------------------------------
// File          : opt17_nf_wrapper.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP, OPT-17
// Creation Date : 2026-10-29
// Description   : Two-Parser prefetch with early core-result handoff.
// $Source: $ $Revision: 1.0 $ $Log: Separate FULL_TERM candidate. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module opt17_nf_wrapper (
    input logic clk,
    input logic rst_n,
    input logic in_valid,
    output wire in_ready,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    input logic acc_mode,
    input logic acc_clr,
    input logic cfg_mode,
    input logic [3:0] cfg_n,
    input logic [1:0] cfg_ops,
    output wire out_valid,
    input logic out_ready,
    output wire [31:0] d,
    output wire [4:0] flags
);
    (* ASYNC_REG = "TRUE" *) logic meta_sync1;
    (* ASYNC_REG = "TRUE" *) logic meta_sync2;
    wire exact_enabled;
    wire reset_n;
    wire core_run;
    wire core_ready;
    wire launch_valid;
    wire launch /* verilator public_flat_rd */;
    wire [25:0] launch_x;
    wire [26:0] launch_y;
    wire launch_mode;
    wire [3:0] launch_n;
    wire launch_sign;
    wire signed [10:0] launch_sf;
    wire launch_cut;
    wire launch_zero;
    wire launch_nar;
    wire launch_id;
    wire c_valid;
    wire c_id;
    wire c_sign;
    wire c_zero;
    wire c_nar;
    wire signed [10:0] c_sf;
    wire [25:0] c_frac;
    wire c_consume /* verilator public_flat_rd */;
    wire retire;
    wire core_done /* verilator public_flat_rd */;
    wire [53:0] acc /* verilator public_flat_rd */;
    wire sticky_acc;
    wire numerical_tail;
    wire [4:0] iterations_done /* verilator public_flat_rd */;
    wire approx_cut;
    wire core_sign;
    wire signed [10:0] core_sf;
    wire core_cut;
    wire core_mode;
    wire core_error;
    logic core_zero_q;
    logic core_nar_q;
    logic core_id_q;
    logic result_pending_q;
    wire result_valid;
    wire result_take /* verilator public_flat_rd */;
    wire tail_in_valid;
    wire tail_ready;
    wire tail_out_valid;
    wire [4:0] product_flags;

    assign exact_enabled = 1'b1;
    assign launch = launch_valid && core_ready;
    assign result_valid = core_run && (core_done || result_pending_q);
    assign tail_in_valid = result_valid && c_valid && c_id == core_id_q;
    assign result_take = tail_in_valid && tail_ready;
    assign out_valid = rst_n && core_run && tail_out_valid;
    assign retire = out_valid && out_ready;
    assign product_flags = (core_zero_q || core_nar_q) ? 5'b0
                         : {3'b0, (core_cut || approx_cut), approx_cut};
    opt17_front_2p u_front (
        .clk (clk),
        .rst_n (rst_n),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .a (a),
        .b (b),
        .c (c),
        .acc_mode (acc_mode),
        .acc_clr (acc_clr),
        .cfg_mode (cfg_mode),
        .cfg_n (cfg_n),
        .cfg_ops (cfg_ops),
        .exact_enabled (exact_enabled),
        .core_run (core_run),
        .core_ready (core_ready),
        .c_consume (c_consume),
        .result_visible (out_valid),
        .result_data (d),
        .retire (retire),
        .reset_n (reset_n),
        .launch_valid (launch_valid),
        .launch_x (launch_x),
        .launch_y (launch_y),
        .launch_mode (launch_mode),
        .launch_n (launch_n),
        .launch_sign (launch_sign),
        .launch_sf (launch_sf),
        .launch_cut (launch_cut),
        .launch_zero (launch_zero),
        .launch_nar (launch_nar),
        .launch_id (launch_id),
        .c_valid (c_valid),
        .c_id (c_id),
        .c_sign (c_sign),
        .c_zero (c_zero),
        .c_nar (c_nar),
        .c_sf (c_sf),
        .c_frac (c_frac)
    );
    opt17_core_nf u_core (
        .clk (clk),
        .reset_n (reset_n),
        .launch_valid (launch_valid),
        .launch_ready (core_ready),
        .release_result (result_take),
        .x_frac (launch_x),
        .y_mant (launch_y),
        .cfg_mode (launch_mode),
        .cfg_n (launch_n),
        .sign_i (launch_sign),
        .sf_i (launch_sf),
        .input_cut_i (launch_cut),
        .run_ready (core_run),
        .core_done (core_done),
        .acc (acc),
        .sticky_acc (sticky_acc),
        .numerical_tail (numerical_tail),
        .iterations_done (iterations_done),
        .approx_cut (approx_cut),
        .sign_o (core_sign),
        .sf_o (core_sf),
        .input_cut_o (core_cut),
        .mode_o (core_mode),
        .state_error (core_error)
    );
    opt17_nf_tail u_tail (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (tail_in_valid),
        .in_ready (tail_ready),
        .p_acc (acc),
        .p_mode (core_mode),
        .p_sign (core_sign),
        .p_zero (core_zero_q),
        .p_nar (core_nar_q),
        .p_sf (core_sf),
        .p_flags (product_flags),
        .c_valid (c_valid),
        .c_consume (c_consume),
        .c_sign (c_sign),
        .c_zero (c_zero),
        .c_nar (c_nar),
        .c_sf (c_sf),
        .c_frac (c_frac),
        .out_valid (tail_out_valid),
        .out_ready (out_ready),
        .d (d),
        .flags (flags)
    );
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end
    // The core owns one result until its tail handshake. A pulse is not enough.
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            core_zero_q <= 1'b0;
            core_nar_q <= 1'b0;
            core_id_q <= 1'b0;
            result_pending_q <= 1'b0;
        end else if (core_run) begin
            if (core_done) begin
                result_pending_q <= `CK2Q 1'b1;
            end
            if (result_take) begin
                result_pending_q <= `CK2Q 1'b0;
            end
            if (launch) begin
                core_zero_q <= `CK2Q launch_zero;
                core_nar_q <= `CK2Q launch_nar;
                core_id_q <= `CK2Q launch_id;
            end
        end
    end
    // synthesis translate_off
    always @(posedge clk) begin
        if (rst_n && core_run) begin
            assert (!core_error) else $fatal(1, "OPT17: core state/width error");
            if (core_done) begin
                assert (!sticky_acc && !numerical_tail)
                    else $fatal(1, "OPT17: FULL_TERM numerical tail");
                if (core_mode) begin
                    assert (acc[53:26] == 0 && iterations_done <= 12)
                        else $fatal(1, "OPT17: approximate accumulator/iteration width");
                end
            end
        end
    end
    // synthesis translate_on
endmodule
// End of opt17_nf_wrapper.sv
