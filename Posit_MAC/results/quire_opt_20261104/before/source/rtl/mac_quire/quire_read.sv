//-----------------------------------------------------------------------------
// File          : quire_read.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-11-03
// Description   : Word-serial abs/scan, lossless Q snapshot to frac53 + sticky.
// $Revision: 1.0 $ $Log: Check full scale before narrowing to Packer signed11. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module quire_read (
    input  logic               clk,
    input  logic               reset_n,
    input  logic               in_valid,
    output wire                in_ready,
    input  logic [971:0]       q_value,
    input  logic               q_nar,
    input  logic               q_invalid,
    input  logic               q_loss,
    input  logic               q_cut,
    output wire                out_valid,
    input  logic               out_ready,
    output logic               sign,
    output logic               is_zero,
    output logic               is_nar,
    output logic signed [10:0] sf,
    output logic [52:0]        frac,
    output logic               sticky,
    output logic [4:0]         flags_in
);
    localparam logic [1:0] IDLE=2'd0, ABS=2'd1, SCAN=2'd2, OUTPUT=2'd3;
    (* ASYNC_REG="TRUE" *) logic meta_sync1, meta_sync2;
    logic [1:0] state_q;
    logic [971:0] work_q;
    logic [4:0] word_q;
    logic carry_q;
    wire [36:0] abs_sum;
    logic [5:0] lead_bit;
    logic [5:0] lead_shift;
    logic signed [11:0] full_sf;
    logic [88:0] aligned_head;

    assign in_ready = meta_sync2 && state_q == IDLE;
    assign out_valid = meta_sync2 && state_q == OUTPUT;
    assign abs_sum = {1'b0, (work_q[35:0] ^ {36{sign}})} + {36'b0, carry_q};

    always_comb begin
        lead_bit = 6'd0;
        for (int i=0; i<36; i=i+1) begin
            if (work_q[936+i]) lead_bit = 6'(i);
        end
        lead_shift = 6'd35 - lead_bit;
        full_sf = 12'({1'b0, word_q}) * 12'sd36 + 12'({1'b0, lead_bit}) - 12'sd480;
        // The normalized hidden bit would be bit89 and is intentionally omitted.
        aligned_head = work_q[970:882] << lead_shift;
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

    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            state_q <= IDLE;
            work_q <= '0;
            word_q <= '0;
            carry_q <= 1'b0;
            sign <= 1'b0;
            is_zero <= 1'b0;
            is_nar <= 1'b0;
            sf <= '0;
            frac <= '0;
            sticky <= 1'b0;
            flags_in <= '0;
        end else begin
            case (state_q)
                IDLE: begin
                    if (in_valid && in_ready) begin
                        sign <= `CK2Q q_value[971];
                        is_zero <= `CK2Q (q_value == '0);
                        is_nar <= `CK2Q (q_nar || q_invalid);
                        flags_in <= `CK2Q ((q_nar || q_invalid) ? 5'b10000 : {3'b0, q_loss, q_cut});
                        sf <= `CK2Q '0;
                        frac <= `CK2Q '0;
                        sticky <= `CK2Q 1'b0;
                        work_q <= `CK2Q q_value;
                        word_q <= `CK2Q 5'd0;
                        carry_q <= `CK2Q q_value[971];
                        state_q <= `CK2Q ((q_nar || q_invalid || q_value == '0) ? OUTPUT : ABS);
                    end
                end
                ABS: begin
                    work_q <= `CK2Q {abs_sum[35:0], work_q[971:36]};
                    carry_q <= `CK2Q abs_sum[36];
                    if (word_q == 5'd26) begin
                        word_q <= `CK2Q 5'd26;
                        state_q <= `CK2Q SCAN;
                    end else begin
                        word_q <= `CK2Q (word_q + 5'd1);
                    end
                end
                SCAN: begin
                    if (work_q[971:936] != 36'b0) begin
                        // Never cast a scale outside Posit range and let it wrap.
                        if (full_sf > 12'sd240) sf <= `CK2Q 11'sd241;
                        else if (full_sf < -12'sd240) sf <= `CK2Q -11'sd241;
                        else sf <= `CK2Q full_sf[10:0];
                        frac <= `CK2Q aligned_head[88:36];
                        sticky <= `CK2Q ((|aligned_head[35:0]) || (|work_q[881:0]));
                        state_q <= `CK2Q OUTPUT;
                    end else if (word_q == 5'd0) begin
                        is_zero <= `CK2Q 1'b1;
                        sign <= `CK2Q 1'b0;
                        state_q <= `CK2Q OUTPUT;
                    end else begin
                        work_q <= `CK2Q {work_q[935:0], 36'b0};
                        word_q <= `CK2Q (word_q - 5'd1);
                    end
                end
                OUTPUT: begin
                    if (out_ready) state_q <= `CK2Q IDLE;
                end
                default: state_q <= `CK2Q IDLE;
            endcase
        end
    end
endmodule
// End of quire_read.sv
