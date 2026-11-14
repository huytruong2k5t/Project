`include "posit_mac.vh"

module elastic_adder_top (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        in_valid,
    output wire         in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output wire         out_valid,
    input  logic        out_ready,
    output wire  [31:0] d,
    output wire  [4:0]  flags
);
    wire               pa_in_ready, pb_in_ready;
    wire               pa_out_valid, pb_out_valid;
    wire               pa_s, pb_s;
    wire               pa_zero, pb_zero;
    wire               pa_nar, pb_nar;
    wire signed [10:0] pa_sf, pb_sf;
    wire [11:0]        pa_frac_hi, pb_frac_hi;
    wire [13:0]        pa_frac_lo, pb_frac_lo;
    wire               pa_tail_cut, pb_tail_cut;

    wire               add_in_ready, add_out_valid;
    wire               add_sign, add_zero, add_nar, add_sticky;
    wire signed [10:0] add_sf;
    wire [52:0]        add_frac;
    wire [4:0]         add_flags;

    wire               pack_in_ready;

    assign in_ready = pa_in_ready && pb_in_ready;
    wire fire_in = in_valid && in_ready;

    wire both_parsed = pa_out_valid && pb_out_valid;
    wire parse_out_ready = add_in_ready && both_parsed;

    posit_parser_mul u_pa (
        .clk       (clk),
        .reset_n   (reset_n),
        .in_valid  (fire_in),
        .in_ready  (pa_in_ready),
        .p         (a),
        .out_valid (pa_out_valid),
        .out_ready (parse_out_ready),
        .s         (pa_s),
        .is_zero   (pa_zero),
        .is_nar    (pa_nar),
        .sf        (pa_sf),
        .frac      (pa_frac_hi),
        .frac_lo   (pa_frac_lo),
        .tail_cut  (pa_tail_cut)
    );

    posit_parser_mul u_pb (
        .clk       (clk),
        .reset_n   (reset_n),
        .in_valid  (fire_in),
        .in_ready  (pb_in_ready),
        .p         (b),
        .out_valid (pb_out_valid),
        .out_ready (parse_out_ready),
        .s         (pb_s),
        .is_zero   (pb_zero),
        .is_nar    (pb_nar),
        .sf        (pb_sf),
        .frac      (pb_frac_hi),
        .frac_lo   (pb_frac_lo),
        .tail_cut  (pb_tail_cut)
    );

    wire unused_tails = pa_tail_cut ^ pb_tail_cut;

    posit_add u_add (
        .clk       (clk),
        .reset_n   (reset_n),
        .in_valid  (both_parsed),
        .in_ready  (add_in_ready),
        .out_valid (add_out_valid),
        .out_ready (pack_in_ready),
        .a_sign    (pa_s),
        .a_is_zero (pa_zero),
        .a_is_nar  (pa_nar),
        .a_sf      (pa_sf),
        .a_frac    ({pa_frac_hi, pa_frac_lo}),
        .b_sign    (pb_s),
        .b_is_zero (pb_zero),
        .b_is_nar  (pb_nar),
        .b_sf      (pb_sf),
        .b_frac    ({pb_frac_hi, pb_frac_lo}),
        .flags_in  (5'b0),
        .sign      (add_sign),
        .is_zero   (add_zero),
        .is_nar    (add_nar),
        .sf        (add_sf),
        .frac      (add_frac),
        .sticky    (add_sticky),
        .flags_out (add_flags)
    );

    posit_pack u_pack (
        .clk       (clk),
        .reset_n   (reset_n),
        .in_valid  (add_out_valid),
        .in_ready  (pack_in_ready),
        .sign      (add_sign),
        .is_zero   (add_zero),
        .is_nar    (add_nar),
        .sf        (add_sf),
        .frac      (add_frac),
        .sticky    (add_sticky),
        .flags_in  (add_flags),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .d         (d),
        .flags     (flags)
    );
endmodule
