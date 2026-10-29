//-----------------------------------------------------------------------------
// File          : mac_f_wrapper.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Atomic A/B/C, W12-F-1 fused MAC, one transaction.
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
    // Fixed posit32/ES3 elaboration; no public parameters.
    localparam int NB = 32;
    localparam int ES = 3;
    localparam int FRAC_W = 12;
    localparam int N_MAX = 12;
    localparam int ACC_WIN = 32;
    localparam int N_W = 4;

    localparam int F = 26; // NB - 3 - ES
    localparam int SF_W = 11; // $clog2(64'd4 * (longint'(NB)-64'd2)                                  * (64'd1 << ES) + 64'd4) + 1
    localparam int I_W = 4; // $clog2(FRAC_W+1)
    localparam int FIN = 53; // 2*F+1
    localparam int ACC_W = 16; // FRAC_W+4
    localparam logic MODE_APPROX = 1'b1;
    generate
        if (NB != 32 || ES != 3 || FRAC_W != 12 || ACC_WIN != 32
            || N_MAX != 12 || N_W != 4) begin : g_invalid
            initial $fatal(1, "posit_mac_f: only W12-F-1 32/3 FW12 N12 W32 is admitted");
        end
    endgenerate
    logic reset_bridge_q;
    (* ASYNC_REG="TRUE" *) logic meta_sync1,meta_sync2;
    logic busy_q;
    logic acc_mode_q;
    logic committed_q;
    logic [NB-1:0] accumulator_q;
    wire [NB-1:0] c_eff;
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
    logic [1:0] ops_q;
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
    wire [FRAC_W-1:0] ops_x;
    wire [FRAC_W-1:0] x;
    wire [FRAC_W:0] ops_y;
    wire [FRAC_W:0] y;
    wire ops_sign;
    wire ops_cut;
    wire signed [SF_W-1:0] ops_sf;
    wire cfg_valid;
    wire core_ready;
    wire core_run;
    wire core_done;
    wire retire;
    wire core_error /* verilator public_flat_rd */;
    wire bypass;
    wire [ACC_W-1:0] acc;
    wire sticky_acc;
    wire numerical_tail;
    wire approx_cut;
    wire core_sign;
    wire core_cut;
    wire core_mode;
    wire [I_W-1:0] iterations_done;
    wire signed [SF_W-1:0] core_sf;

    logic zero_q;
    logic nar_q;
    wire pack_ready;
    wire pack_out_valid;
    wire [13:0] p_magnitude;
    wire [1:0] loss_in;
    assign p_magnitude = acc[15:2];
    assign loss_in = (zero_q || nar_q) ? 2'b0
                   : {(core_cut || approx_cut || numerical_tail), approx_cut};
    assign reset_n = reset_bridge_q;
    assign c_eff = acc_mode ? (acc_clr ? {NB{1'b0}} : accumulator_q) : c;
    assign cfg_valid = (cfg_ops <= 1) && cfg_mode
                    && (int'(cfg_n) <= N_MAX) && (!acc_clr || acc_mode);
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
    posit_parser  u_a (
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
    posit_parser  u_b (
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
    posit_parser  u_c (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (pair_accept),
        .in_ready (ready_c),
        .p (c_eff),
        .out_valid (valid_c),
        .out_ready (pair_retire),
        .s (s_c),
        .is_zero (z_c),
        .is_nar (nar_c),
        .sf (sf_c),
        .frac (frac_c)
    );
    ops_sel_comb_fixed2  u_ops (
        .frac_a (frac_a),
        .frac_b (frac_b),
        .s_a (s_a),
        .s_b (s_b),
        .sf_a (sf_a),
        .sf_b (sf_b),
        .cfg_ops (ops_q),
        .x_frac (ops_x),
        .y_mant (ops_y),
        .sign_o (ops_sign),
        .sf_o (ops_sf),
        .input_cut (ops_cut)
    );
    mul_iter_core_fixed2  u_core (
        .clk (clk),
        .reset_n (reset_n),
        .launch_valid (pair_retire),
        .launch_ready (core_ready),
        .release_result (retire),
        .x_frac (x),
        .y_mant (y),
        .cfg_mode (MODE_APPROX),
        .cfg_n (n_q),
        .sign_i (ops_sign),
        .sf_i (ops_sf),
        .input_cut_i (ops_cut),
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
    fused_add_pipe  u_fused (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (core_done),
        .in_ready (add_ready),
        .out_valid (add_valid),
        .out_ready (pack_ready),
        .p_magnitude (p_magnitude),
        .p_scale (core_sf),
        .p_sign (core_sign),
        .p_zero (zero_q),
        .is_nar_in (nar_q),
        .loss_in (loss_in),
        .c_sf (c_sf_q),
        .c_frac (c_frac_q),
        .c_sign (c_sign_q),
        .c_zero (c_zero_q),
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
            acc_mode_q <= 1'b0;
            committed_q <= 1'b0;
            accumulator_q <= '0;
            c_sign_q <= 1'b0;
            c_zero_q <= 1'b0;
            c_sf_q <= '0;
            c_frac_q <= '0;
            n_q <= '0;
            ops_q <= '0;
            zero_q <= 1'b0;
            nar_q <= 1'b0;
        end else begin
            if (pack_out_valid && !committed_q) begin
                committed_q <= `CK2Q 1'b1;
                if (acc_mode_q) accumulator_q <= `CK2Q d;
            end
            if (retire) busy_q <= `CK2Q 1'b0;
            if (pair_accept) begin
                busy_q <= `CK2Q 1'b1;
                acc_mode_q <= `CK2Q acc_mode;
                committed_q <= `CK2Q 1'b0;
                if (acc_mode && acc_clr) accumulator_q <= `CK2Q '0;
                n_q <= `CK2Q cfg_n;
                ops_q <= `CK2Q cfg_ops;
            end
            if (pair_retire) begin
                zero_q <= `CK2Q (z_a || z_b);
                nar_q <= `CK2Q (nar_a || nar_b || nar_c);
                c_sign_q <= `CK2Q s_c;
                c_zero_q <= `CK2Q z_c;
                c_sf_q <= `CK2Q sf_c;
                c_frac_q <= `CK2Q frac_c;
            end
        end
    end
    // Shared core diagnostic outputs are checked, never registered again here.
    // synthesis translate_off
    always @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
        end else if (meta_sync2) begin
            assert (!core_error) else $fatal(1, "F: multiplier state/carry error");
            if (core_done) begin
                assert (add_ready) else $fatal(1, "F: prepack lost to backpressure");
                assert (core_mode && !sticky_acc && acc[1:0] == 0)
                    else $fatal(1, "F: invalid FLOOR prepack grid");
                assert (iterations_done <= I_W'(N_MAX))
                    else $fatal(1, "F: iteration bound");
            end
        end
    end
    // synthesis translate_on
endmodule
// End of mac_f_wrapper.sv
