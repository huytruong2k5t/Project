//-----------------------------------------------------------------------------
// File          : ops_ppa_boundary.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-14
// Description   : Registered input/output benchmark for complete OPS I/O.
//                 Measurement only; data banks are overwritten every cycle.
// $Source: $ $Revision: 1.0 $ $Log: Identical before/after register boundary. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module ops_ppa_boundary #(
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
    output logic [FRAC_MAX-1:0] x_frac,
    output logic [FRAC_MAX:0] y_mant,
    output logic [WIDTH_W-1:0] active_width,
    output logic sign_o,
    output logic signed [SF_W-1:0] sf_o,
    output logic swapped,
    output logic input_cut,
    output logic cfg_error
);
    logic [FRAC_MAX-1:0] frac_a_q;
    logic [FRAC_MAX-1:0] frac_b_q;
    logic s_a_q;
    logic s_b_q;
    logic signed [SF_W-1:0] sf_a_q;
    logic signed [SF_W-1:0] sf_b_q;
    logic cfg_mode_q;
    logic [1:0] cfg_ops_q;
    wire [FRAC_MAX-1:0] x_frac_d;
    wire [FRAC_MAX:0] y_mant_d;
    wire [WIDTH_W-1:0] active_width_d;
    wire sign_d;
    wire signed [SF_W-1:0] sf_d;
    wire swapped_d;
    wire input_cut_d;
    wire cfg_error_d;

    ops_sel_comb #(
        .FRAC_MAX(FRAC_MAX),
        .FRAC_W(FRAC_W),
        .SF_W(SF_W),
        .WIDTH_W(WIDTH_W)
    ) u_ops (
        .frac_a(frac_a_q),
        .frac_b(frac_b_q),
        .s_a(s_a_q),
        .s_b(s_b_q),
        .sf_a(sf_a_q),
        .sf_b(sf_b_q),
        .cfg_mode(cfg_mode_q),
        .cfg_ops(cfg_ops_q),
        .x_frac(x_frac_d),
        .y_mant(y_mant_d),
        .active_width(active_width_d),
        .sign_o(sign_d),
        .sf_o(sf_d),
        .swapped(swapped_d),
        .input_cut(input_cut_d),
        .cfg_error(cfg_error_d)
    );
    // These benchmark data banks require no reset; they do not own valid/state.
    // Functional M0/reset/launch behavior remains in the multiplier core.
    always_ff @(posedge clk) begin
        frac_a_q <= `CK2Q frac_a;
        frac_b_q <= `CK2Q frac_b;
        s_a_q <= `CK2Q s_a;
        s_b_q <= `CK2Q s_b;
        sf_a_q <= `CK2Q sf_a;
        sf_b_q <= `CK2Q sf_b;
        cfg_mode_q <= `CK2Q cfg_mode;
        cfg_ops_q <= `CK2Q cfg_ops;
        x_frac <= `CK2Q x_frac_d;
        y_mant <= `CK2Q y_mant_d;
        active_width <= `CK2Q active_width_d;
        sign_o <= `CK2Q sign_d;
        sf_o <= `CK2Q sf_d;
        swapped <= `CK2Q swapped_d;
        input_cut <= `CK2Q input_cut_d;
        cfg_error <= `CK2Q cfg_error_d;
    end
endmodule
// End of ops_ppa_boundary.sv
