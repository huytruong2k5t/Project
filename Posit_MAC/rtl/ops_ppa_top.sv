//-----------------------------------------------------------------------------
// File          : ops_ppa_top.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-14
// Description   : Structural top of identical-boundary OPS timing benchmark.
// $Source: $ $Revision: 1.0 $ $Log: Main32/3 F26,FW12,SW11 profile. $
//-----------------------------------------------------------------------------
module ops_ppa_top #(
    parameter int FRAC_MAX = 26,
    parameter int FRAC_W = 12,
    parameter int SF_W = 11,
    parameter int WIDTH_W = (FRAC_MAX > 1) ? $clog2(FRAC_MAX + 1) : 1
)(
    input logic clk,
    input logic [FRAC_MAX-1:0] frac_a,
    input logic [FRAC_MAX-1:0] frac_b,
    input logic s_a,
    input logic s_b,
    input logic signed [SF_W-1:0] sf_a,
    input logic signed [SF_W-1:0] sf_b,
    input logic cfg_mode,
    input logic [1:0] cfg_ops,
    output wire [FRAC_MAX-1:0] x_frac,
    output wire [FRAC_MAX:0] y_mant,
    output wire [WIDTH_W-1:0] active_width,
    output wire sign_o,
    output wire signed [SF_W-1:0] sf_o,
    output wire swapped,
    output wire input_cut,
    output wire cfg_error
);
    ops_ppa_boundary #(
        .FRAC_MAX(FRAC_MAX),
        .FRAC_W(FRAC_W),
        .SF_W(SF_W),
        .WIDTH_W(WIDTH_W)
    ) u_boundary (
        .clk(clk),
        .frac_a(frac_a),
        .frac_b(frac_b),
        .s_a(s_a),
        .s_b(s_b),
        .sf_a(sf_a),
        .sf_b(sf_b),
        .cfg_mode(cfg_mode),
        .cfg_ops(cfg_ops),
        .x_frac(x_frac),
        .y_mant(y_mant),
        .active_width(active_width),
        .sign_o(sign_o),
        .sf_o(sf_o),
        .swapped(swapped),
        .input_cut(input_cut),
        .cfg_error(cfg_error)
    );
endmodule
// End of ops_ppa_top.sv
