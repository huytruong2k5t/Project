//-----------------------------------------------------------------------------
// File          : quire_bank.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-11-03
// Description   : Atomic signed972 bank, 27 word36 additions, capacity1024.
// $Revision: 1.0 $ $Log: Commit once; sticky status; preserve Q on overflow. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module quire_bank (
    input  logic         clk,
    input  logic         reset_n,
    input  logic         in_valid,
    output wire          in_ready,
    input  logic         clear,
    input  logic [971:0] term,
    input  logic         term_nar,
    input  logic         term_invalid,
    input  logic         term_loss,
    input  logic         term_cut,
    output logic         done,
    output logic [971:0] q_value,
    output logic [10:0]  q_count,
    output logic         q_nar,
    output logic         q_invalid,
    output logic         q_loss,
    output logic         q_cut,
    output logic         q_overflow
);
    (* ASYNC_REG="TRUE" *) logic meta_sync1, meta_sync2;
    logic busy_q;
    logic [4:0] word_q;
    logic [971:0] sum_work_q;
    logic [971:0] term_work_q;
    logic carry_q;
    logic same_sign_q;
    logic old_sign_q;
    logic loss_q, cut_q;
    wire [36:0] word_sum;
    wire [971:0] sum_next;
    wire overflow_next;
    wire accept;

    assign in_ready = meta_sync2 && !busy_q && (clear || q_count < 11'd1024);
    assign accept = in_valid && in_ready;
    assign word_sum = {1'b0, sum_work_q[35:0]}
                    + {1'b0, term_work_q[35:0]} + {36'b0, carry_q};
    assign sum_next = {word_sum[35:0], sum_work_q[971:36]};
    assign overflow_next = same_sign_q && (word_sum[35] != old_sign_q);

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
            word_q <= '0;
            sum_work_q <= '0;
            term_work_q <= '0;
            carry_q <= 1'b0;
            same_sign_q <= 1'b0;
            old_sign_q <= 1'b0;
            loss_q <= 1'b0;
            cut_q <= 1'b0;
            done <= 1'b0;
            q_value <= '0;
            q_count <= '0;
            q_nar <= 1'b0;
            q_invalid <= 1'b0;
            q_loss <= 1'b0;
            q_cut <= 1'b0;
            q_overflow <= 1'b0;
        end else begin
            done <= `CK2Q 1'b0;
            if (accept) begin
                if (clear) begin
                    q_value <= `CK2Q '0;
                    q_count <= `CK2Q '0;
                    q_nar <= `CK2Q 1'b0;
                    q_invalid <= `CK2Q 1'b0;
                    q_loss <= `CK2Q 1'b0;
                    q_cut <= `CK2Q 1'b0;
                    q_overflow <= `CK2Q 1'b0;
                    done <= `CK2Q 1'b1;
                end else if (q_nar || q_invalid || term_nar || term_invalid || term == '0) begin
                    q_count <= `CK2Q (q_count + 11'd1);
                    q_nar <= `CK2Q (q_nar || term_nar);
                    q_invalid <= `CK2Q (q_invalid || term_invalid);
                    q_loss <= `CK2Q (q_loss || term_loss);
                    q_cut <= `CK2Q (q_cut || term_cut);
                    done <= `CK2Q 1'b1;
                end else begin
                    busy_q <= `CK2Q 1'b1;
                    word_q <= `CK2Q 5'd0;
                    sum_work_q <= `CK2Q q_value;
                    term_work_q <= `CK2Q term;
                    carry_q <= `CK2Q 1'b0;
                    old_sign_q <= `CK2Q q_value[971];
                    same_sign_q <= `CK2Q (q_value[971] == term[971]);
                    loss_q <= `CK2Q term_loss;
                    cut_q <= `CK2Q term_cut;
                end
            end else if (busy_q) begin
                sum_work_q <= `CK2Q sum_next;
                term_work_q <= `CK2Q {36'b0, term_work_q[971:36]};
                carry_q <= `CK2Q word_sum[36];
                if (word_q == 5'd26) begin
                    busy_q <= `CK2Q 1'b0;
                    done <= `CK2Q 1'b1;
                    q_count <= `CK2Q (q_count + 11'd1);
                    q_loss <= `CK2Q (q_loss || loss_q);
                    q_cut <= `CK2Q (q_cut || cut_q);
                    if (overflow_next) begin
                        q_invalid <= `CK2Q 1'b1;
                        q_overflow <= `CK2Q 1'b1;
                    end else begin
                        q_value <= `CK2Q sum_next;
                    end
                end else begin
                    word_q <= `CK2Q (word_q + 5'd1);
                end
            end
        end
    end
endmodule
// End of quire_bank.sv
