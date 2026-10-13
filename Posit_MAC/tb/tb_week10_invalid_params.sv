`timescale 1ns/1ps
module tb_week10_invalid_params #(
    parameter int CASE = 0
);
    localparam int F = CASE == 1 ? 6 : 5;
    localparam int SF_W = CASE == 0 ? 5 : 6;
    localparam int F_OUT = CASE == 2 ? 12 : 2 * F + 1;
    wire sign, is_zero, is_nar, sticky;
    wire signed [SF_W-1:0] sf;
    wire [F_OUT-1:0] frac;
    wire [4:0] flags_out;
    posit_add_comb #(
        .NB(8), .ES(0), .F(F), .SF_W(SF_W), .F_OUT(F_OUT)
    ) dut (
        .a_sign(1'b0), .a_is_zero(1'b1), .a_is_nar(1'b0), .a_sf('0), .a_frac('0),
        .b_sign(1'b0), .b_is_zero(1'b1), .b_is_nar(1'b0), .b_sf('0), .b_frac('0),
        .flags_in(5'b0), .sign(sign), .is_zero(is_zero), .is_nar(is_nar),
        .sf(sf), .frac(frac), .sticky(sticky), .flags_out(flags_out)
    );
    initial begin
        #10;
        $fatal(1,"INVALID CONFIG WAS NOT REJECTED");
    end
endmodule
