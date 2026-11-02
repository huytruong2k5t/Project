//-----------------------------------------------------------------------------
// File          : mul_iter_core_fixed2.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : Consolidated iterative multiplier parent module (Approximate-only).
//                 Directly encloses L0 context, L1 SAC FSM (u_sac), L2 shift (u_shift),
//                 and L3 accumulator (u_accum) with all pipeline and control registers.
// $Source: $ $Revision: 3.0 $ $Log: Consolidated hierarchy; removed sticky_acc. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module mul_iter_core_fixed2 (
    input  logic              clk,
    input  logic              reset_n,
    input  logic              launch_valid,
    output wire               launch_ready,
    input  logic              release_result,
    input  logic [11:0]       x_frac,
    input  logic [12:0]       y_mant,
    input  logic [3:0]        cfg_n,
    input  logic              sign_i,
    input  logic signed [10:0] sf_i,
    input  logic              input_cut_i,
    output wire               run_ready,
    output wire               core_done,
    output wire [15:0]        acc,
    output wire               numerical_tail,
    output wire [3:0]         iterations_done,
    output wire               approx_cut,
    output logic              sign_o,
    output logic signed [10:0] sf_o,
    output logic              input_cut_o,
    output wire               state_error
);
    // Fixed posit32/ES3 approximate-12 elaboration; no public parameters.
    localparam int FRAC_MAX = 12;
    localparam int S_W      = 4;
    localparam int I_W      = 4;
    localparam int ACC_W    = 16;

    // Reset synchronizer
    (* ASYNC_REG="TRUE" *) logic meta_sync1, meta_sync2;
    assign run_ready = meta_sync2;

    // L0 Context and Handshakes
    logic busy_q;
    logic [12:0] y_q;
    wire launch = launch_valid && launch_ready;
    assign launch_ready = run_ready && !busy_q;

    // L1 Control and SAC FSM
    logic emitting_q;
    logic [FRAC_MAX-1:0] fx_q;
    logic [S_W-1:0] scale_q;
    logic [I_W-1:0] count_q, limit_q;

    wire step_error;
    wire [FRAC_MAX-1:0] fx_next;
    wire [S_W-1:0] next_scale;
    wire exhausted;
    wire is_init   = (fx_q == '0) || (limit_q == '0);
    wire [I_W-1:0] next_count = count_q + 1'b1;
    wire is_last   = is_init || exhausted || (next_count >= limit_q);

    // L1 Combinational Datapath Instance
    sac_step_comb_fixed3 u_sac (
        .fx          (fx_q),
        .scale       (scale_q),
        .scale_next  (next_scale),
        .fx_next     (fx_next),
        .exhausted   (exhausted),
        .state_error (step_error)
    );

    // L1 -> L2 Pipeline Token Registers
    logic           t1_valid;
    logic           t1_first;
    logic           t1_last;
    logic           t1_init;
    logic [S_W-1:0] t1_scale;
    logic [I_W-1:0] t1_iteration;
    logic           t1_cut;

    // L2 Combinational Datapath Instance
    wire [ACC_W-1:0] y_base, term;
    wire             term_tail;

    sbm_shift_comb_fixed2 u_shift (
        .y_mant    (y_q),
        .scale     (t1_scale),
        .init_only (t1_init),
        .y_base    (y_base),
        .term      (term),
        .term_tail (term_tail)
    );

    // L2 -> L3 Pipeline Token Registers
    logic             t2_valid;
    logic             t2_first;
    logic             t2_last;
    logic             t2_init;
    logic             t2_cut;
    logic             t2_tail;
    logic [I_W-1:0]   t2_iteration;
    logic [ACC_W-1:0] t2_term;

    // L3 Combinational Datapath Instance
    wire [ACC_W-1:0] acc_next;
    wire             numerical_next;
    wire             carry_raw;

    logic [ACC_W-1:0] acc_q;
    logic             numerical_tail_q;
    logic [I_W-1:0]   iterations_done_q;
    logic             approx_cut_q;
    logic             done_q;

    sbm_accum_comb_fixed2 u_accum (
        .first          (t2_first),
        .init_only      (t2_init),
        .y_base         (y_base),
        .term           (t2_term),
        .term_tail      (t2_tail),
        .acc            (acc_q),
        .numerical_tail (numerical_tail_q),
        .acc_next       (acc_next),
        .numerical_next (numerical_next),
        .carry_error    (carry_raw)
    );

    // Diagnostic & Output Assignments
    assign state_error     = (emitting_q && step_error) || (t2_valid && carry_raw);
    assign core_done       = done_q;
    assign acc             = acc_q;
    assign numerical_tail  = numerical_tail_q;
    assign iterations_done = iterations_done_q;
    assign approx_cut      = approx_cut_q;

    // 2-Stage Reset Synchronizer
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end

    // Sequential Datapath & Pipeline Control
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            // L0 Reset
            busy_q            <= 1'b0;
            y_q               <= '0;
            sign_o            <= 1'b0;
            sf_o              <= '0;
            input_cut_o       <= 1'b0;

            // L1 Reset
            emitting_q        <= 1'b0;
            fx_q              <= '0;
            scale_q           <= '0;
            count_q           <= '0;
            limit_q           <= '0;
            t1_valid          <= 1'b0;
            t1_first          <= 1'b0;
            t1_last           <= 1'b0;
            t1_init           <= 1'b0;
            t1_scale          <= '0;
            t1_iteration      <= '0;
            t1_cut            <= 1'b0;

            // L2 Reset
            t2_valid          <= 1'b0;
            t2_first          <= 1'b0;
            t2_last           <= 1'b0;
            t2_init           <= 1'b0;
            t2_cut            <= 1'b0;
            t2_tail           <= 1'b0;
            t2_iteration      <= '0;
            t2_term           <= '0;

            // L3 Reset
            acc_q             <= '0;
            numerical_tail_q  <= 1'b0;
            iterations_done_q <= '0;
            approx_cut_q      <= 1'b0;
            done_q            <= 1'b0;
        end else begin
            // L0 Context update
            if (release_result) busy_q <= `CK2Q 1'b0;
            if (launch) begin
                busy_q      <= `CK2Q 1'b1;
                y_q         <= `CK2Q y_mant;
                sign_o      <= `CK2Q sign_i;
                sf_o        <= `CK2Q sf_i;
                input_cut_o <= `CK2Q input_cut_i;
            end

            // L1 FSM and token generation
            t1_valid <= `CK2Q emitting_q;
            if (launch) begin
                emitting_q <= `CK2Q 1'b1;
                fx_q       <= `CK2Q x_frac;
                scale_q    <= `CK2Q '0;
                count_q    <= `CK2Q '0;
                limit_q    <= `CK2Q cfg_n;
            end else if (emitting_q) begin
                t1_first     <= `CK2Q (count_q == '0);
                t1_last      <= `CK2Q is_last;
                t1_init      <= `CK2Q is_init;
                t1_scale     <= `CK2Q (is_init ? {S_W{1'b0}} : next_scale);
                t1_iteration <= `CK2Q (is_init ? {I_W{1'b0}} : next_count);
                t1_cut       <= `CK2Q (is_init ? (fx_q != '0) : (is_last && !exhausted));
                fx_q         <= `CK2Q fx_next;
                scale_q      <= `CK2Q next_scale;
                count_q      <= `CK2Q next_count;
                if (is_last) emitting_q <= `CK2Q 1'b0;
            end

            // L2 Pipeline Stage
            t2_valid <= `CK2Q t1_valid;
            if (t1_valid) begin
                t2_first     <= `CK2Q t1_first;
                t2_last      <= `CK2Q t1_last;
                t2_init      <= `CK2Q t1_init;
                t2_cut       <= `CK2Q t1_cut;
                t2_tail      <= `CK2Q term_tail;
                t2_iteration <= `CK2Q t1_iteration;
                t2_term      <= `CK2Q term;
            end

            // L3 Accumulator Stage
            done_q <= `CK2Q (t2_valid && t2_last);
            if (t2_valid) begin
                acc_q             <= `CK2Q acc_next;
                numerical_tail_q  <= `CK2Q numerical_next;
                iterations_done_q <= `CK2Q t2_iteration;
                approx_cut_q      <= `CK2Q t2_cut;
            end
        end
    end

endmodule
//-----------------------------------------------------------------------------
// End of mul_iter_core_fixed2.sv
//-----------------------------------------------------------------------------
