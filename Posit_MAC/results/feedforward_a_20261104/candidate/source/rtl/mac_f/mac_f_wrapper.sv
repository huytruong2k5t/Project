//-----------------------------------------------------------------------------
// File          : mac_f_wrapper.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Atomic A/B/C, FULL_TERM26/Q24 fused MAC, one transaction.
//                 Synchronous top reset bridge and leaf startup barrier.
// $Source: $ $Revision: 1.0 $ $Log: W13 W12-F-1 fused integration. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module mac_f_wrapper (
    input logic clk,
    input logic rst_n,
    input logic in_valid,
    output wire in_ready,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    input logic [3:0] cfg_n,
    input logic [1:0] cfg_ops,
    output wire out_valid,
    input logic out_ready,
    output wire [31:0] d,
    output wire [4:0] flags
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    localparam int N_W = 4;

    localparam int F = 26; // NB - 3 - ES
    localparam int SF_W = 11; // $clog2(64'd4 * (longint'(NB)-64'd2)                                  * (64'd1 << ES) + 64'd4) + 1
    localparam int FIN = 53; // 2*F+1
    localparam int ACC_W = 26; // Two integer positions plus Q24 fraction.
    logic reset_bridge_q;
    (* ASYNC_REG="TRUE" *) logic meta_sync1,meta_sync2;
    logic busy_q;
    wire ready_c;
    wire valid_c;
    wire s_c;
    wire z_c;
    wire nar_c;
    wire signed [SF_W-1:0] sf_c;
    wire [F-1:0] frac_c;
    logic c_sign_q;
    logic c_zero_q;
    logic signed [SF_W-1:0] c_sf_q;
    logic [F-1:0] c_frac_q;
    wire add_ready;
    wire add_valid;
    wire sum_sign;
    wire sum_zero;
    wire sum_nar;
    wire sum_sticky;
    wire signed [SF_W-1:0] sum_sf;
    wire [FIN-1:0] sum_frac;
    wire [4:0] sum_flags;
    logic [N_W-1:0] n_q;
    logic ops_q;
    wire reset_n;
    wire ready_a;
    wire ready_b;
    wire valid_a;
    wire valid_b;
    wire pair_accept;
    wire pair_retire;
    wire s_a;
    wire s_b;
    wire z_a;
    wire z_b;
    wire nar_a;
    wire nar_b;
    wire signed [SF_W-1:0] sf_a;
    wire signed [SF_W-1:0] sf_b;
    wire [F-1:0] frac_a;
    wire [F-1:0] frac_b;
    wire [11:0] ops_x;
    wire [11:0] x;
    wire [12:0] ops_y;
    wire [12:0] y;
    wire ops_sign;
    wire ops_cut;
    wire signed [SF_W-1:0] ops_sf;
    assign ops_cut = |(frac_a[13:0] | frac_b[13:0]);
    wire cfg_valid;
    wire core_ready;
    wire core_run;
    wire core_done;
    wire retire;
    wire core_error /* verilator public_flat_rd */;
    wire bypass;
    wire [ACC_W-1:0] acc;
    wire approx_cut;
    wire core_sign;
    wire core_cut;
    wire [3:0] iterations_done;
    wire signed [SF_W-1:0] core_sf;

    logic zero_q;
    logic nar_q;
    logic c_nar_q;
    logic signed [SF_W-1:0] core_sf_inc_q;
    wire pack_ready;
    wire pack_out_valid;
    wire signed [10:0] product_sf;
    wire [25:0] product_frac;
    wire [4:0] product_flags;

    mul_prepack_norm_comb u_norm (
        .acc (acc),
        .sf (core_sf),
        .sf_inc (core_sf_inc_q),
        .sf_norm (product_sf),
        .frac_norm (product_frac)
    );
    assign product_flags = (zero_q || nar_q) ? 5'b0
                         : {3'b0, (core_cut || approx_cut), approx_cut};
    assign reset_n = reset_bridge_q;
    assign cfg_valid = (cfg_ops <= 2'd1) && (cfg_n <= 4'd12);
    assign in_ready = rst_n && meta_sync2 && core_run && pack_ready
                    && ready_a && ready_b && ready_c && add_ready
                    && !busy_q && cfg_valid;
    assign pair_accept = in_valid && in_ready;
    assign pair_retire = valid_a && valid_b && valid_c && core_ready;
    assign bypass = nar_a || nar_b || nar_c || z_a || z_b;
    assign x = bypass ? '0 : ops_x;
    assign y = bypass ? '0 : ops_y;
    assign retire = out_valid && out_ready;
    assign out_valid = rst_n && meta_sync2 && pack_out_valid;
    always_ff @(posedge clk) begin
        reset_bridge_q <= `CK2Q rst_n;
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end
    posit_parser_f u_a (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (pair_accept),
        .in_ready (ready_a),
        .p (a),
        .out_valid (valid_a),
        .out_ready (pair_retire),
        .s (s_a),
        .is_zero (z_a),
        .is_nar (nar_a),
        .sf (sf_a),
        .frac (frac_a)
    );
    posit_parser_f u_b (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (pair_accept),
        .in_ready (ready_b),
        .p (b),
        .out_valid (valid_b),
        .out_ready (pair_retire),
        .s (s_b),
        .is_zero (z_b),
        .is_nar (nar_b),
        .sf (sf_b),
        .frac (frac_b)
    );
    posit_parser_f u_c (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (pair_accept),
        .in_ready (ready_c),
        .p (c),
        .out_valid (valid_c),
        .out_ready (pair_retire),
        .s (s_c),
        .is_zero (z_c),
        .is_nar (nar_c),
        .sf (sf_c),
        .frac (frac_c)
    );
    ops_sel_comb u_ops (
        .frac_a (frac_a[25:14]),
        .frac_b (frac_b[25:14]),
        .s_a (s_a),
        .s_b (s_b),
        .sf_a (sf_a),
        .sf_b (sf_b),
        .cfg_ops (ops_q),
        .x_frac (ops_x),
        .y_mant (ops_y),
        .sign_o (ops_sign),
        .sf_o (ops_sf)
    );
    mul_iter_core u_core (
        .clk (clk),
        .reset_n (reset_n),
        .launch_valid (pair_retire),
        .launch_ready (core_ready),
        .release_result (retire),
        .x_frac (x),
        .y_mant (y),
        .cfg_n (n_q),
        .sign_i (ops_sign),
        .sf_i (ops_sf),
        .input_cut_i (ops_cut),
        .run_ready (core_run),
        .core_done (core_done),
        .acc (acc),
        .iterations_done (iterations_done),
        .approx_cut (approx_cut),
        .sign_o (core_sign),
        .sf_o (core_sf),
        .input_cut_o (core_cut),
        .state_error (core_error)
    );
    posit_add  u_add (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (core_done),
        .in_ready (add_ready),
        .out_valid (add_valid),
        .out_ready (pack_ready),
        .a_sign (core_sign),
        .a_is_zero (zero_q),
        .a_is_nar (nar_q),
        .a_sf (product_sf),
        .a_frac (product_frac),
        .b_sign (c_sign_q),
        .b_is_zero (c_zero_q),
        .b_is_nar (c_nar_q),
        .b_sf (c_sf_q),
        .b_frac (c_frac_q),
        .flags_in (product_flags),
        .sign (sum_sign),
        .is_zero (sum_zero),
        .is_nar (sum_nar),
        .sf (sum_sf),
        .frac (sum_frac),
        .sticky (sum_sticky),
        .flags_out (sum_flags)
    );
    posit_pack  u_pack (
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
        .out_valid (pack_out_valid),
        .out_ready (out_ready),
        .d (d),
        .flags (flags)
    );
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            busy_q <= 1'b0;
            c_sign_q <= 1'b0;
            c_zero_q <= 1'b0;
            c_sf_q <= '0;
            c_frac_q <= '0;
            n_q <= 4'd12;
            ops_q <= 1'b1;
            zero_q <= 1'b0;
            nar_q <= 1'b0;
            c_nar_q <= 1'b0;
            core_sf_inc_q <= '0;
        end else begin
            if (retire) busy_q <= `CK2Q 1'b0;
            if (pair_accept) begin
                busy_q <= `CK2Q 1'b1;
                n_q <= `CK2Q cfg_n;
                ops_q <= `CK2Q cfg_ops[0];
            end
            if (pair_retire) begin
                zero_q <= `CK2Q (z_a || z_b);
                nar_q <= `CK2Q (nar_a || nar_b || nar_c);
                c_nar_q <= `CK2Q nar_c;
                core_sf_inc_q <= `CK2Q (ops_sf + 11'sd1);
                c_sign_q <= `CK2Q s_c;
                c_zero_q <= `CK2Q z_c;
                c_sf_q <= `CK2Q sf_c;
                c_frac_q <= `CK2Q frac_c;
            end
        end
    end
    // synthesis translate_off
    always @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
        end else if (meta_sync2) begin
            assert (!core_error) else $fatal(1, "F: shared multiplier invariant");
            if (core_done) begin
                assert (add_ready) else $fatal(1, "F: lost prepack token");
                assert (iterations_done <= 4'd12)
                    else $fatal(1, "F: iteration bound");
            end
        end
    end
    // synthesis translate_on
endmodule
// End of mac_f_wrapper.sv
