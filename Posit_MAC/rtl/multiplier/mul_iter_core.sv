//-----------------------------------------------------------------------------
// File          : mul_iter_core.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : L0 context, L1 SAC, L2 shift, L3 accumulator.
//                 One reserved transaction; release after output retirement.
// $Source: $ $Revision: 1.0 $ $Log: SPEC 5.5-A core implementation. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module mul_iter_core #(
    parameter int FRAC_MAX=27,
    parameter int FRAC_W=12,
    parameter int N_MAX=8,
    parameter int ROUND_SCHEME=0,
    parameter bit EXACT_EN=1'b1,
    parameter int SF_W=11,
    parameter int S_W=(FRAC_MAX>1) ? $clog2(FRAC_MAX+1) : 1,
    parameter int N_W=(N_MAX>1) ? $clog2(N_MAX+1) : 1,
    parameter int I_W=$clog2(((FRAC_MAX>N_MAX) ? FRAC_MAX : N_MAX)+1),
    parameter int ACC_W=EXACT_EN ? ((2*FRAC_MAX+2>FRAC_W+4) ? 2*FRAC_MAX+2 : FRAC_W+4) : FRAC_W+4
)(
    input logic clk,
    input logic reset_n,
    input logic launch_valid,
    output wire launch_ready,
    input logic release_result,
    input logic [FRAC_MAX-1:0] x_frac,
    input logic [FRAC_MAX:0] y_mant,
    input logic cfg_mode,
    input logic [N_W-1:0] cfg_n,
    input logic sign_i,
    input logic signed [SF_W-1:0] sf_i,
    input logic input_cut_i,
    output wire run_ready,
    output wire core_done,
    output wire [ACC_W-1:0] acc,
    output wire sticky_acc,
    output wire numerical_tail,
    output wire [I_W-1:0] iterations_done,
    output wire approx_cut,
    output logic sign_o,
    output logic signed [SF_W-1:0] sf_o,
    output logic input_cut_o,
    output logic mode_o,
    output wire state_error
);
    (* ASYNC_REG="TRUE" *) logic meta_sync1,meta_sync2;
    logic busy_q;
    logic [FRAC_MAX:0] y_q;
    wire launch,ctrl_ready,acc_ready;
    wire t1_valid,t1_first,t1_last,t1_init,t1_cut;
    wire [S_W-1:0] t1_scale;
    wire [I_W-1:0] t1_iteration;
    wire ctrl_error,carry_error;
    wire [ACC_W-1:0] y_base,term;
    wire term_tail;
    logic t2_valid,t2_first,t2_last,t2_init,t2_cut,t2_tail;
    logic [I_W-1:0] t2_iteration;
    logic [ACC_W-1:0] t2_term;
    assign run_ready=meta_sync2 && ctrl_ready && acc_ready;
    assign launch_ready=run_ready && !busy_q;
    assign launch=launch_valid && launch_ready;
    assign state_error=ctrl_error || carry_error;
    iter_ctrl #(
        .FRAC_MAX(FRAC_MAX),
        .FRAC_W(FRAC_W),
        .N_MAX(N_MAX)) u_ctrl (
        .clk(clk),
        .reset_n(reset_n),
        .launch(launch),
        .cfg_mode(cfg_mode),
        .cfg_n(cfg_n),
        .x_frac(x_frac),
        .run_ready(ctrl_ready),
        .token_valid(t1_valid),
        .first(t1_first),
        .last(t1_last),
        .init_only(t1_init),
        .scale(t1_scale),
        .iteration(t1_iteration),
        .approx_cut(t1_cut),
        .state_error(ctrl_error)
    );
    sbm_shift_comb #(
        .FRAC_MAX(FRAC_MAX),
        .FRAC_W(FRAC_W),
        .ROUND_SCHEME(ROUND_SCHEME),
        .EXACT_EN(EXACT_EN)) u_shift (
        .cfg_mode(mode_o),
        .y_mant(y_q),
        .scale(t1_scale),
        .init_only(t1_init),
        .y_base(y_base),
        .term(term),
        .term_tail(term_tail)
    );
    sbm_accum #(
        .ACC_W(ACC_W),
        .I_W(I_W),
        .ROUND_SCHEME(ROUND_SCHEME)) u_acc (
        .clk(clk),
        .reset_n(reset_n),
        .commit_valid(t2_valid),
        .cfg_mode(mode_o),
        .first(t2_first),
        .last(t2_last),
        .init_only(t2_init),
        .y_base(y_base),
        .term(t2_term),
        .term_tail(t2_tail),
        .iteration(t2_iteration),
        .approx_cut(t2_cut),
        .run_ready(acc_ready),
        .acc(acc),
        .sticky_acc(sticky_acc),
        .numerical_tail(numerical_tail),
        .iterations_done(iterations_done),
        .approx_cut_o(approx_cut),
        .done(core_done),
        .carry_error(carry_error)
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
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            busy_q <= 1'b0;
            y_q <= '0;
            sign_o <= 1'b0;
            sf_o <= '0;
            input_cut_o <= 1'b0;
            mode_o <= 1'b0;
            t2_valid <= 1'b0;
            t2_first <= 1'b0;
            t2_last <= 1'b0;
            t2_init <= 1'b0;
            t2_cut <= 1'b0;
            t2_tail <= 1'b0;
            t2_iteration <= '0;
            t2_term <= '0;
        end else begin
            if (release_result) busy_q <= `CK2Q 1'b0;
            if (launch) begin
                busy_q <= `CK2Q 1'b1;
                y_q <= `CK2Q y_mant;
                sign_o <= `CK2Q sign_i;
                sf_o <= `CK2Q sf_i;
                input_cut_o <= `CK2Q input_cut_i;
                mode_o <= `CK2Q cfg_mode;
            end
            t2_valid <= `CK2Q t1_valid;
            if (t1_valid) begin
                t2_first <= `CK2Q t1_first;
                t2_last <= `CK2Q t1_last;
                t2_init <= `CK2Q t1_init;
                t2_cut <= `CK2Q t1_cut;
                t2_tail <= `CK2Q term_tail;
                t2_iteration <= `CK2Q t1_iteration;
                t2_term <= `CK2Q term;
            end
        end
    end
endmodule
// End of mul_iter_core.sv
