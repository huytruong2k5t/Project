// Atomic signed972 accumulator: indexed27x36 bank and shadow transaction.
// No full-width shift register. The shadow preserves Q on signed overflow.
`include "posit_mac.vh"
module quire_bank (
    input logic clk,
    input logic reset_n,
    input logic in_valid,
    output wire in_ready,
    input logic clear,
    input logic [26:0] coefficient,
    input logic [4:0] word_index,
    input logic [5:0] bit_offset,
    input logic term_zero,
    input logic term_nar,
    input logic term_invalid,
    input logic term_loss,
    input logic term_cut,
    output logic done,
    output wire [971:0] q_value,
    output logic [10:0] q_count,
    output logic q_nar,
    output logic q_invalid,
    output logic q_loss,
    output logic q_cut,
    output logic q_overflow
);
    (* ASYNC_REG="TRUE" *) logic meta_sync1,meta_sync2;
    logic busy_q;
    logic [4:0] step_q;
    logic [35:0] q_words [0:26];
    logic [35:0] pending_words [0:26];
    logic [26:0] coefficient_q;
    logic [4:0] index_q;
    logic [5:0] offset_q;
    logic carry_q, same_sign_q, old_sign_q, loss_q, cut_q;
    wire [62:0] local_term;
    logic [35:0] term_word;
    wire [36:0] word_sum;
    wire overflow_next;
    wire accept;
    assign in_ready = meta_sync2 && !busy_q && (clear || q_count < 11'd1024);
    assign accept = in_valid && in_ready;
    assign local_term = {{36{coefficient_q[26]}},coefficient_q} << offset_q;
    always_comb begin
        if (step_q < index_q) term_word = '0;
        else if (step_q == index_q) term_word = local_term[35:0];
        else if ({1'b0,step_q} == {1'b0,index_q}+6'd1)
            term_word = {{9{local_term[62]}},local_term[62:36]};
        else term_word = {36{coefficient_q[26]}};
    end
    assign word_sum = {1'b0,q_words[step_q]} + {1'b0,term_word} + {36'b0,carry_q};
    assign overflow_next = same_sign_q && (word_sum[35] != old_sign_q);
    for (genvar i=0;i<27;i++) begin : g_words
        assign q_value[i*36 +:36] = q_words[i];
        // A pending entry is read only after all27 entries have been written.
        always_ff @(posedge clk) begin
            if (busy_q && step_q==5'(i))
                pending_words[i] <= `CK2Q word_sum[35:0];
        end
        always_ff @(posedge clk or negedge meta_sync2) begin
            if (!meta_sync2) q_words[i] <= '0;
            else if (accept && clear) q_words[i] <= `CK2Q '0;
            else if (busy_q && step_q==5'd26 && !overflow_next) begin
                if (i==26) q_words[i] <= `CK2Q word_sum[35:0];
                else q_words[i] <= `CK2Q pending_words[i];
            end
        end
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin meta_sync1<=1'b0;meta_sync2<=1'b0;end
        else begin meta_sync1<=`CK2Q 1'b1;meta_sync2<=`CK2Q meta_sync1;end
    end
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            busy_q<=1'b0;step_q<='0;coefficient_q<='0;index_q<='0;offset_q<='0;
            carry_q<=1'b0;same_sign_q<=1'b0;old_sign_q<=1'b0;loss_q<=1'b0;cut_q<=1'b0;
            done<=1'b0;q_count<='0;q_nar<=1'b0;q_invalid<=1'b0;
            q_loss<=1'b0;q_cut<=1'b0;q_overflow<=1'b0;
        end else begin
            done<=`CK2Q 1'b0;
            if (accept) begin
                if (clear) begin
                    q_count<='0;q_nar<=1'b0;q_invalid<=1'b0;q_loss<=1'b0;q_cut<=1'b0;
                    q_overflow<=1'b0;done<=`CK2Q 1'b1;
                end else if (q_nar || q_invalid || term_nar || term_invalid || term_zero) begin
                    q_count<=`CK2Q (q_count+11'd1);
                    q_nar<=`CK2Q (q_nar||term_nar);q_invalid<=`CK2Q (q_invalid||term_invalid);
                    q_loss<=`CK2Q (q_loss||term_loss);q_cut<=`CK2Q (q_cut||term_cut);
                    done<=`CK2Q 1'b1;
                end else begin
                    busy_q<=`CK2Q 1'b1;step_q<='0;carry_q<=1'b0;
                    coefficient_q<=`CK2Q coefficient;index_q<=`CK2Q word_index;offset_q<=`CK2Q bit_offset;
                    old_sign_q<=`CK2Q q_words[26][35];
                    same_sign_q<=`CK2Q (q_words[26][35]==coefficient[26]);
                    loss_q<=`CK2Q term_loss;cut_q<=`CK2Q term_cut;
                end
            end else if (busy_q) begin
                carry_q<=`CK2Q word_sum[36];
                if (step_q==5'd26) begin
                    busy_q<=`CK2Q 1'b0;done<=`CK2Q 1'b1;q_count<=`CK2Q (q_count+11'd1);
                    q_loss<=`CK2Q (q_loss||loss_q);q_cut<=`CK2Q (q_cut||cut_q);
                    if (overflow_next) begin q_invalid<=`CK2Q 1'b1;q_overflow<=`CK2Q 1'b1;end
                end else step_q<=`CK2Q (step_q+5'd1);
            end
        end
    end
endmodule
