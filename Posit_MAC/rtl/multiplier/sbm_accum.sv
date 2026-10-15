//-----------------------------------------------------------------------------
// File          : sbm_accum.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : Accumulator L3; done only after last token commits.
// $Source: $ $Revision: 1.0 $ $Log: Week9 sequential accumulator. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module sbm_accum #(
    parameter int ACC_W=56,
    parameter int I_W=5,
    parameter int ROUND_SCHEME=0
)(
    input logic clk,
    input logic reset_n,
    input logic commit_valid,
    input logic cfg_mode,
    input logic first,
    input logic last,
    input logic init_only,
    input logic [ACC_W-1:0] y_base,
    input logic [ACC_W-1:0] term,
    input logic term_tail,
    input logic [I_W-1:0] iteration,
    input logic approx_cut,
    output wire run_ready,
    output logic [ACC_W-1:0] acc,
    output logic sticky_acc,
    output logic numerical_tail,
    output logic [I_W-1:0] iterations_done,
    output logic approx_cut_o,
    output logic done,
    output wire carry_error
);
    (* ASYNC_REG="TRUE" *) logic meta_sync1,meta_sync2;
    wire [ACC_W-1:0] acc_next;
    wire sticky_next,numerical_next;
    wire carry_raw;
    assign run_ready=meta_sync2;
    assign carry_error=commit_valid && carry_raw;
    sbm_accum_comb #(
        .ACC_W(ACC_W),
        .ROUND_SCHEME(ROUND_SCHEME)) u_add (
        .cfg_mode(cfg_mode),
        .first(first),
        .init_only(init_only),
        .y_base(y_base),
        .term(term),
        .term_tail(term_tail),
        .acc(acc),
        .sticky_acc(sticky_acc),
        .numerical_tail(numerical_tail),
        .acc_next(acc_next),
        .sticky_next(sticky_next),
        .numerical_next(numerical_next),
        .carry_error(carry_raw)
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
            acc <= '0;
            sticky_acc <= 1'b0;
            numerical_tail <= 1'b0;
            iterations_done <= '0;
            approx_cut_o <= 1'b0;
            done <= 1'b0;
        end else begin
            done <= `CK2Q (commit_valid && last);
            if (commit_valid) begin
                acc <= `CK2Q acc_next;
                sticky_acc <= `CK2Q sticky_next;
                numerical_tail <= `CK2Q numerical_next;
                iterations_done <= `CK2Q iteration;
                approx_cut_o <= `CK2Q approx_cut;
            end
        end
    end
endmodule
// End of sbm_accum.sv
