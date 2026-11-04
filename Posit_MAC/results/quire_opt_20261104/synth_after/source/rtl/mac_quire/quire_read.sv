// READ uses a stable committed bank, indexed words, a two-word window and tail OR.
// The top's one-command ownership keeps q_value stable until READ retires.
// FETCH cuts the36-bit abs adder from priority/normalization in REDUCE.
`include "posit_mac.vh"
module quire_read (
    input logic clk,
    input logic reset_n,
    input logic in_valid,
    output wire in_ready,
    input logic [971:0] q_value,
    input logic q_nar,
    input logic q_invalid,
    input logic q_loss,
    input logic q_cut,
    output wire out_valid,
    input logic out_ready,
    output logic sign,
    output logic is_zero,
    output logic is_nar,
    output logic signed [10:0] sf,
    output logic [52:0] frac,
    output logic sticky,
    output logic [4:0] flags_in
);
    localparam logic [1:0] IDLE=0,FETCH=1,REDUCE=2,OUTPUT=3;
    (* ASYNC_REG="TRUE" *) logic meta_sync1,meta_sync2;
    logic [1:0] state_q;
    logic [4:0] step_q;
    logic carry_q;
    logic [35:0] abs_word_q,previous_q,previous2_q;
    logic lower_tail_q;
    wire [35:0] selected_word = q_value[step_q*36 +:36];
    wire [36:0] abs_sum = {1'b0,(selected_word ^ {36{sign}})} + {36'b0,carry_q};
    logic [5:0] lead_bit;
    logic signed [11:0] full_sf;
    logic [106:0] normalized;
    assign in_ready = meta_sync2 && state_q==IDLE;
    assign out_valid = meta_sync2 && state_q==OUTPUT;
    always_comb begin
        lead_bit='0;
        for (int i=0;i<36;i++) if (abs_word_q[i]) lead_bit=6'(i);
        full_sf=12'({1'b0,step_q})*12'sd36 + 12'({1'b0,lead_bit})-12'sd480;
        normalized=107'({abs_word_q,previous_q,previous2_q} << (6'd35-lead_bit));
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin meta_sync1<=1'b0;meta_sync2<=1'b0;end
        else begin meta_sync1<=`CK2Q 1'b1;meta_sync2<=`CK2Q meta_sync1;end
    end
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            state_q<=IDLE;step_q<='0;carry_q<=1'b0;abs_word_q<='0;
            previous_q<='0;previous2_q<='0;lower_tail_q<=1'b0;
            sign<=1'b0;is_zero<=1'b1;is_nar<=1'b0;sf<='0;frac<='0;sticky<=1'b0;flags_in<='0;
        end else begin
            case (state_q)
                IDLE: if (in_valid && in_ready) begin
                    sign<=`CK2Q q_value[971];is_zero<=`CK2Q 1'b1;
                    is_nar<=`CK2Q (q_nar||q_invalid);
                    flags_in<=`CK2Q ((q_nar||q_invalid)?5'b10000:{3'b0,q_loss,q_cut});
                    sf<='0;frac<='0;sticky<=1'b0;step_q<='0;carry_q<=`CK2Q q_value[971];
                    previous_q<='0;previous2_q<='0;lower_tail_q<=1'b0;state_q<=`CK2Q FETCH;
                end
                FETCH: begin
                    abs_word_q<=`CK2Q abs_sum[35:0];carry_q<=`CK2Q abs_sum[36];state_q<=`CK2Q REDUCE;
                end
                REDUCE: begin
                    previous_q<=`CK2Q abs_word_q;previous2_q<=`CK2Q previous_q;
                    lower_tail_q<=`CK2Q (lower_tail_q || |previous2_q);
                    if (abs_word_q!=0) begin
                        is_zero<=`CK2Q 1'b0;
                        if (full_sf>12'sd240) sf<=`CK2Q 11'sd241;
                        else if (full_sf< -12'sd240) sf<=`CK2Q -11'sd241;
                        else sf<=`CK2Q full_sf[10:0];
                        frac<=`CK2Q normalized[106:54];
                        sticky<=`CK2Q ((|normalized[53:0]) || lower_tail_q);
                    end
                    if (step_q==5'd26) state_q<=`CK2Q OUTPUT;
                    else begin step_q<=`CK2Q (step_q+5'd1);state_q<=`CK2Q FETCH;end
                end
                OUTPUT: if (out_ready) state_q<=`CK2Q IDLE;
                default: state_q<=IDLE;
            endcase
        end
    end
endmodule
