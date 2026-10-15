//-----------------------------------------------------------------------------
// File          : paper_mul_iter.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP - separate research branch
// Creation Date : 2026-10-09
// Description   : Structural top for autonomous posit32 ES3/Q12 research.
//                 n_terms counts all terms including the first, range 1..8.
//                 Not the normative multiplier or recovered author RTL.
// $Source: $ $Revision: 1.0 $ $Log: Autonomous research integration. $
//-----------------------------------------------------------------------------
module paper_mul_iter (
    input logic clk,
    input logic reset_n,
    input logic in_valid,
    output wire in_ready,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [3:0] n_terms,
    input logic force_a,
    output wire out_valid,
    input logic out_ready,
    output wire [31:0] d,
    output wire [3:0] iterations,
    output wire state_error,
    output wire trace_valid,
    output wire [3:0] trace_iteration,
    output wire [12:0] trace_mantissa,
    output wire signed [7:0] trace_exponent,
    output wire signed [7:0] trace_power,
    output wire trace_negative,
    output wire trace_anchor,
    output wire [13:0] trace_acc,
    output wire [13:0] trace_term,
    output wire trace_tail,
    output wire [12:0] trace_mantissa_next,
    output wire signed [7:0] trace_exponent_next,
    output wire trace_negative_next,
    output wire [13:0] trace_acc_next
);
    paper_mul_wrapper u_wrapper (
        .clk(clk),
        .reset_n(reset_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .a(a),
        .b(b),
        .n_terms(n_terms),
        .force_a(force_a),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .d(d),
        .iterations(iterations),
        .state_error(state_error),
        .trace_valid(trace_valid),
        .trace_iteration(trace_iteration),
        .trace_mantissa(trace_mantissa),
        .trace_exponent(trace_exponent),
        .trace_power(trace_power),
        .trace_negative(trace_negative),
        .trace_anchor(trace_anchor),
        .trace_acc(trace_acc),
        .trace_term(trace_term),
        .trace_tail(trace_tail),
        .trace_mantissa_next(trace_mantissa_next),
        .trace_exponent_next(trace_exponent_next),
        .trace_negative_next(trace_negative_next),
        .trace_acc_next(trace_acc_next)
    );
endmodule
// End of paper_mul_iter.sv
