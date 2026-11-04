//-----------------------------------------------------------------------------
// File: quire_checker.sv | Posit MAC IP | 2026-11-03
// Verification top: external protocol and internal commit/checkpoint probes.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module quire_checker (
    input logic clk,
    input logic rst_n,
    input logic in_valid,
    output wire in_ready,
    input logic [1:0] q_cmd,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [3:0] cfg_n,
    input logic [1:0] cfg_ops,
    output wire out_valid,
    input logic out_ready,
    output wire [1:0] out_cmd,
    output wire [31:0] d,
    output wire [4:0] flags,
    output wire q_overflow,
    output wire bank_commit,
    output wire [971:0] q_value,
    output wire [10:0] q_count,
    output wire q_nar,
    output wire q_invalid,
    output wire q_loss,
    output wire q_cut,
    output wire core_done,
    output wire [25:0] core_magnitude,
    output wire [3:0] core_iterations,
    output wire core_cut,
    output wire core_input_cut,
    output wire core_sign,
    output wire signed [10:0] core_scale,
    output wire core_error
);
    posit_mac_quire dut (
        .clk (clk),
        .rst_n (rst_n),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .q_cmd (q_cmd),
        .a (a),
        .b (b),
        .cfg_n (cfg_n),
        .cfg_ops (cfg_ops),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .out_cmd (out_cmd),
        .d (d),
        .flags (flags),
        .q_overflow (q_overflow)
    );
    assign bank_commit = dut.u_wrapper.bank_done;
    assign q_value = dut.u_wrapper.q_value;
    assign q_count = dut.u_wrapper.q_count;
    assign q_nar = dut.u_wrapper.q_nar;
    assign q_invalid = dut.u_wrapper.q_invalid;
    assign q_loss = dut.u_wrapper.q_loss;
    assign q_cut = dut.u_wrapper.q_cut;
    assign core_done = dut.u_wrapper.core_done;
    assign core_magnitude = dut.u_wrapper.acc;
    assign core_iterations = dut.u_wrapper.iterations_done;
    assign core_cut = dut.u_wrapper.approx_cut;
    assign core_input_cut = dut.u_wrapper.core_cut;
    assign core_sign = dut.u_wrapper.core_sign;
    assign core_scale = dut.u_wrapper.core_sf;
    assign core_error = dut.u_wrapper.core_error;
endmodule
// End of quire_checker.sv
