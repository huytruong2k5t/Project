module adder_verification_top #(
    parameter int NB = 32,
    parameter int ES = 2
)(
    input logic clk,
    input logic reset_n,
    input logic in_valid,
    output wire in_ready,
    input logic out_ready,
    output wire out_valid,
    input logic [NB-1:0] a,
    input logic [NB-1:0] b,
    input logic [4:0] flags_in,
    output wire sign,
    output wire is_zero,
    output wire is_nar,
    output wire signed [$clog2(4 * (NB - 2) * (1 << ES) + 4):0] sf,
    output wire [2*(NB-3-ES):0] frac,
    output wire sticky,
    output wire [4:0] flags_out,
    output wire [NB-1:0] d_rne,
    output wire [NB-1:0] d_trunc,
    output wire [4:0] flags_rne,
    output wire [4:0] flags_trunc
);
    localparam int F = NB - 3 - ES;
    localparam int SF_W = $clog2(4 * (NB - 2) * (1 << ES) + 4) + 1;
    wire a_sign, a_is_zero, a_is_nar;
    wire b_sign, b_is_zero, b_is_nar;
    wire signed [SF_W-1:0] a_sf, b_sf;
    wire [F-1:0] a_frac, b_frac;

    posit_parser_comb #(.NB(NB), .ES(ES)) u_parser_a (
        .p(a), .s(a_sign), .is_zero(a_is_zero), .is_nar(a_is_nar),
        .sf(a_sf), .frac(a_frac)
    );
    posit_parser_comb #(.NB(NB), .ES(ES)) u_parser_b (
        .p(b), .s(b_sign), .is_zero(b_is_zero), .is_nar(b_is_nar),
        .sf(b_sf), .frac(b_frac)
    );
    posit_add #(.NB(NB), .ES(ES)) dut (
        .clk(clk), .reset_n(reset_n), .in_valid(in_valid), .in_ready(in_ready),
        .out_valid(out_valid), .out_ready(out_ready),
        .a_sign(a_sign), .a_is_zero(a_is_zero), .a_is_nar(a_is_nar),
        .a_sf(a_sf), .a_frac(a_frac),
        .b_sign(b_sign), .b_is_zero(b_is_zero), .b_is_nar(b_is_nar),
        .b_sf(b_sf), .b_frac(b_frac), .flags_in(flags_in),
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar),
        .sf(sf), .frac(frac), .sticky(sticky), .flags_out(flags_out)
    );
    posit_pack_comb #(.NB(NB), .ES(ES), .ROUND_MODE("RNE")) u_pack_rne (
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar), .sf(sf),
        .frac(frac), .sticky(sticky), .flags_in(flags_out), .d(d_rne), .flags(flags_rne)
    );
    posit_pack_comb #(.NB(NB), .ES(ES), .ROUND_MODE("TRUNC")) u_pack_trunc (
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar), .sf(sf),
        .frac(frac), .sticky(sticky), .flags_in(flags_out), .d(d_trunc), .flags(flags_trunc)
    );

endmodule
