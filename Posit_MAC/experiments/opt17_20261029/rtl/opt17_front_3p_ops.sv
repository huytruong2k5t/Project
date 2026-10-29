//-----------------------------------------------------------------------------
// File          : opt17_front_3p_ops.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP, OPT-17 study
// Creation Date : 2026-10-29
// Description   : Three Parser lanes A-B-C, one OPS slot, one C bank, two credits.
//                 Accumulation is serialized; independent transactions prefetch.
// $Source: $ $Revision: 1.0 $ $Log: E0-E4 schedule with elastic role/id. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module opt17_front_3p_ops (
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
    input logic exact_enabled,
    input logic core_run,
    input logic core_ready,
    input logic c_consume,
    input logic result_visible,
    input logic [31:0] result_data,
    input logic retire,
    output wire reset_n,
    output wire launch_valid,
    output wire [25:0] launch_x,
    output wire [26:0] launch_y,
    output wire launch_mode,
    output wire [3:0] launch_n,
    output wire launch_sign,
    output wire signed [10:0] launch_sf,
    output wire launch_cut,
    output wire launch_zero,
    output wire launch_nar,
    output wire launch_id,
    output wire c_valid,
    output wire c_id,
    output wire c_sign,
    output wire c_zero,
    output wire c_nar,
    output wire signed [10:0] c_sf,
    output wire [25:0] c_frac
);
    typedef struct packed {
        logic mode;
        logic [3:0] n;
        logic [1:0] ops;
        logic accumulate;
    } context_t;
    context_t context_q [1:0];
    typedef struct packed {
        logic [25:0] x;
        logic [26:0] y;
        logic mode;
        logic [3:0] n;
        logic sign;
        logic signed [10:0] sf;
        logic cut;
        logic zero;
        logic nar;
        logic id;
    } ops_t;
    ops_t ops_q;
    typedef struct packed {
        logic sign;
        logic zero;
        logic nar;
        logic signed [10:0] sf;
        logic [25:0] frac;
        logic id;
    } c_t;
    c_t c_q;

    logic reset_bridge_q;
    (* ASYNC_REG = "TRUE" *) logic meta_sync1;
    (* ASYNC_REG = "TRUE" *) logic meta_sync2;
    logic [1:0] credit_q /* verilator public_flat_rd */;
    logic allocate_id_q;
    logic retire_id_q;
    logic [1:0] committed_q;
    logic acc_barrier_q;
    logic [31:0] accumulator_q /* verilator public_flat_rd */;
    wire raw_pending_q /* verilator public_flat_rd */;
    logic ops_valid_q /* verilator public_flat_rd */;
    logic c_valid_q /* verilator public_flat_rd */;

    wire lane_c_ready;
    wire cp_valid /* verilator public_flat_rd */;
    wire cp_id;
    wire cp_ready;
    wire cp_sign;
    wire cp_zero;
    wire cp_nar;
    wire signed [10:0] cp_sf;
    wire [25:0] cp_frac;
    wire role_c;
    wire unused_cp_role;
    assign role_c = 1'b1;
    assign cp_ready = !c_valid_q || c_consume;

    wire cfg_valid;
    wire pair_accept /* verilator public_flat_rd */;
    wire [31:0] c_effective;
    wire lane_ac_in_valid;
    wire lane_ac_ready;
    wire lane_b_ready;
    wire [31:0] lane_ac_bits;
    wire lane_ac_in_id;
    wire ac_valid /* verilator public_flat_rd */;
    wire ac_role /* verilator public_flat_rd */;
    wire ac_id;
    wire ac_ready;
    wire ac_sign;
    wire ac_zero;
    wire ac_nar;
    wire signed [10:0] ac_sf;
    wire [25:0] ac_frac;
    wire b_valid;
    wire b_id;
    wire unused_b_role;
    wire b_ready;
    wire b_sign;
    wire b_zero;
    wire b_nar;
    wire signed [10:0] b_sf;
    wire [25:0] b_frac;
    wire ops_ready;
    wire ops_capture /* verilator public_flat_rd */;
    wire c_capture /* verilator public_flat_rd */;
    wire launch /* verilator public_flat_rd */;
    wire c_bank_matches;
    wire c_parser_matches;
    wire c_launch_nar;
    wire [25:0] selected_x;
    wire [26:0] selected_y;
    wire selected_sign;
    wire signed [10:0] selected_sf;
    wire selected_cut;
    wire [4:0] unused_active_width;
    wire unused_swapped;
    wire unused_ops_error;
    wire selected_mode;
    wire [1:0] selected_ops;
    wire role_a;
    wire credits_available;
    wire dependency_ready;

    always_ff @(posedge clk) begin
        reset_bridge_q <= `CK2Q rst_n;
    end
    assign reset_n = reset_bridge_q;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end

    assign cfg_valid = (cfg_ops <= 2'd1)
                     && (cfg_mode || exact_enabled)
                     && (!cfg_mode || cfg_n <= 4'd12)
                     && (!acc_clr || acc_mode);
    assign credits_available = (credit_q < 2'd2) || retire;
    assign dependency_ready = !acc_barrier_q && (!acc_mode || credit_q == 0);
    assign in_ready = rst_n && meta_sync2 && core_run && cfg_valid
                    && credits_available && dependency_ready
                    && lane_ac_ready && lane_b_ready && lane_c_ready;
    assign pair_accept = in_valid && in_ready;
    assign c_effective = acc_mode ? (acc_clr ? 32'b0 : accumulator_q) : c;
    // The saved C has priority over another A, irrespective of core-busy.
    assign raw_pending_q = 1'b0;
    assign lane_ac_in_valid = pair_accept;
    assign lane_ac_bits = a;
    assign lane_ac_in_id = allocate_id_q;
    assign role_a = 1'b0;

    opt17_parser u_ac (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (lane_ac_in_valid),
        .in_ready (lane_ac_ready),
        .p (lane_ac_bits),
        .in_role (role_a),
        .in_id (lane_ac_in_id),
        .out_role (ac_role),
        .out_id (ac_id),
        .out_valid (ac_valid),
        .out_ready (ac_ready),
        .s (ac_sign),
        .is_zero (ac_zero),
        .is_nar (ac_nar),
        .sf (ac_sf),
        .frac (ac_frac)
    );
    opt17_parser u_b (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (pair_accept),
        .in_ready (lane_b_ready),
        .p (b),
        .in_role (role_a),
        .in_id (allocate_id_q),
        .out_role (unused_b_role),
        .out_id (b_id),
        .out_valid (b_valid),
        .out_ready (b_ready),
        .s (b_sign),
        .is_zero (b_zero),
        .is_nar (b_nar),
        .sf (b_sf),
        .frac (b_frac)
    );

    opt17_parser u_c (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (pair_accept),
        .in_ready (lane_c_ready),
        .p (c_effective),
        .in_role (role_c),
        .in_id (allocate_id_q),
        .out_role (unused_cp_role),
        .out_id (cp_id),
        .out_valid (cp_valid),
        .out_ready (cp_ready),
        .s (cp_sign),
        .is_zero (cp_zero),
        .is_nar (cp_nar),
        .sf (cp_sf),
        .frac (cp_frac)
    );

    assign selected_mode = context_q[ac_id].mode;
    assign selected_ops = context_q[ac_id].ops;
    ops_sel_comb u_ops (
        .frac_a (ac_frac),
        .frac_b (b_frac),
        .s_a (ac_sign),
        .s_b (b_sign),
        .sf_a (ac_sf),
        .sf_b (b_sf),
        .cfg_mode (selected_mode),
        .cfg_ops (selected_ops),
        .x_frac (selected_x),
        .y_mant (selected_y),
        .active_width (unused_active_width),
        .sign_o (selected_sign),
        .sf_o (selected_sf),
        .swapped (unused_swapped),
        .input_cut (selected_cut),
        .cfg_error (unused_ops_error)
    );

    assign ops_ready = !ops_valid_q || launch;
    assign ac_ready = b_valid && ac_id == b_id && ops_ready;
    assign b_ready = ac_valid && !ac_role && ac_id == b_id && ops_ready;
    assign ops_capture = ac_valid && !ac_role && ac_ready;
    assign c_capture = cp_valid && cp_ready;
    // C may be captured on the same edge as core launch (E3).
    assign c_bank_matches = c_valid_q && c_q.id == ops_q.id;
    assign c_parser_matches = c_capture && cp_id == ops_q.id;
    assign c_launch_nar = c_bank_matches ? c_q.nar : cp_nar;
    assign launch_valid = meta_sync2 && ops_valid_q && (c_bank_matches || c_parser_matches);
    assign launch = launch_valid && core_ready;
    assign launch_zero = ops_q.zero;
    assign launch_nar = ops_q.nar || c_launch_nar;
    assign launch_x = (launch_zero || launch_nar) ? 26'b0 : ops_q.x;
    assign launch_y = (launch_zero || launch_nar) ? 27'b0 : ops_q.y;
    assign launch_mode = ops_q.mode;
    assign launch_n = ops_q.n;
    assign launch_sign = ops_q.sign;
    assign launch_sf = ops_q.sf;
    assign launch_cut = ops_q.cut;
    assign launch_id = ops_q.id;
    assign c_valid = c_valid_q;
    assign c_id = c_q.id;
    assign c_sign = c_q.sign;
    assign c_zero = c_q.zero;
    assign c_nar = c_q.nar;
    assign c_sf = c_q.sf;
    assign c_frac = c_q.frac;

    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            credit_q <= '0;
            allocate_id_q <= 1'b0;
            retire_id_q <= 1'b0;
            committed_q <= '0;
            acc_barrier_q <= 1'b0;
            accumulator_q <= '0;
            context_q[0] <= '0;
            context_q[1] <= '0;
            ops_valid_q <= 1'b0;
            ops_q <= '0;
            c_valid_q <= 1'b0;
            c_q <= '0;
        end else begin
            unique case ({pair_accept, retire})
                2'b10: credit_q <= `CK2Q credit_q + 1'b1;
                2'b01: credit_q <= `CK2Q credit_q - 1'b1;
                default: credit_q <= `CK2Q credit_q;
            endcase
            if (result_visible && !committed_q[retire_id_q]) begin
                committed_q[retire_id_q] <= `CK2Q 1'b1;
                if (context_q[retire_id_q].accumulate) begin
                    accumulator_q <= `CK2Q result_data;
                end
            end
            if (retire) begin
                retire_id_q <= `CK2Q !retire_id_q;
                if (acc_barrier_q) begin
                    acc_barrier_q <= `CK2Q 1'b0;
                end
            end
            if (pair_accept) begin
                allocate_id_q <= `CK2Q !allocate_id_q;
                committed_q[allocate_id_q] <= `CK2Q 1'b0;
                context_q[allocate_id_q].mode <= `CK2Q cfg_mode;
                context_q[allocate_id_q].n <= `CK2Q cfg_n;
                context_q[allocate_id_q].ops <= `CK2Q cfg_ops;
                context_q[allocate_id_q].accumulate <= `CK2Q acc_mode;
                acc_barrier_q <= `CK2Q acc_mode;
                if (acc_mode && acc_clr) begin
                    accumulator_q <= `CK2Q 32'b0;
                end
            end
            if (ops_ready) begin
                ops_valid_q <= `CK2Q ops_capture;
                if (ops_capture) begin
                    ops_q.x <= `CK2Q selected_x;
                    ops_q.y <= `CK2Q selected_y;
                    ops_q.mode <= `CK2Q selected_mode;
                    ops_q.n <= `CK2Q context_q[ac_id].n;
                    ops_q.sign <= `CK2Q selected_sign;
                    ops_q.sf <= `CK2Q selected_sf;
                    ops_q.cut <= `CK2Q selected_cut;
                    ops_q.zero <= `CK2Q (ac_zero || b_zero);
                    ops_q.nar <= `CK2Q (ac_nar || b_nar);
                    ops_q.id <= `CK2Q ac_id;
                end
            end
            if (c_consume) begin
                c_valid_q <= `CK2Q 1'b0;
            end
            if (c_capture) begin
                c_valid_q <= `CK2Q 1'b1;
                c_q.sign <= `CK2Q cp_sign;
                c_q.zero <= `CK2Q cp_zero;
                c_q.nar <= `CK2Q cp_nar;
                c_q.sf <= `CK2Q cp_sf;
                c_q.frac <= `CK2Q cp_frac;
                c_q.id <= `CK2Q cp_id;
            end
        end
    end

    // synthesis translate_off
    always @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
        end else if (rst_n) begin
            assert (credit_q <= 2) else $fatal(1, "OPT17: credit overflow");
            assert (!retire || credit_q != 0) else $fatal(1, "OPT17: credit underflow");
            assert (!c_consume || c_valid_q) else $fatal(1, "OPT17: missing C bank");
            assert (!(pair_accept && raw_pending_q)) else $fatal(1, "OPT17: lost raw C");
            if (acc_barrier_q) begin
                assert (credit_q == 1 && !pair_accept) else $fatal(1, "OPT17: accumulation overlap");
            end
        end
    end
    // synthesis translate_on
endmodule
// End of opt17_front_3p_ops.sv
