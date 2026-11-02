//-----------------------------------------------------------------------------
// File          : shared_mac_checker.sv
// Project       : Posit MAC IP
// Description   : Verification-only selector; DUT formats/features stay fixed.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module shared_mac_checker #(
    parameter int unsigned FUSED = 0
) (
    input logic clk,
    input logic rst_n,
    input logic in_valid,
    output wire in_ready,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    input logic acc_mode,
    input logic acc_clr,
    input logic [3:0] cfg_n,
    input logic [1:0] cfg_ops,
    output wire out_valid,
    input logic out_ready,
    output wire [31:0] d,
    output wire [4:0] flags,
    output wire core_done,
    output wire [25:0] core_magnitude,
    output wire [3:0] core_iterations,
    output wire core_cut,
    output wire core_input_cut,
    output wire core_sign,
    output wire signed [10:0] core_scale,
    output wire core_error,
    output wire commit_valid,
    output wire commit_first,
    output wire commit_last,
    output wire [3:0] commit_iteration
);
    generate
        if (FUSED != 0) begin : g_f
            posit_mac_f dut (
                .clk(clk),
                .rst_n(rst_n),
                .in_valid(in_valid),
                .in_ready(in_ready),
                .a(a),
                .b(b),
                .c(c),
                .acc_mode(acc_mode),
                .acc_clr(acc_clr),
                .cfg_n(cfg_n),
                .cfg_ops(cfg_ops),
                .out_valid(out_valid),
                .out_ready(out_ready),
                .d(d),
                .flags(flags)
            );
            assign core_done = dut.u_wrapper.u_core.core_done;
            assign core_magnitude = dut.u_wrapper.u_core.acc;
            assign core_iterations = dut.u_wrapper.u_core.iterations_done;
            assign core_cut = dut.u_wrapper.u_core.approx_cut;
            assign core_input_cut = dut.u_wrapper.u_core.input_cut_o;
            assign core_sign = dut.u_wrapper.u_core.sign_o;
            assign core_scale = dut.u_wrapper.u_core.sf_o;
            assign core_error = dut.u_wrapper.u_core.state_error;
            assign commit_valid = dut.u_wrapper.u_core.t2_valid;
            assign commit_first = dut.u_wrapper.u_core.t2_first;
            assign commit_last = dut.u_wrapper.u_core.t2_last;
            assign commit_iteration = dut.u_wrapper.u_core.t2_iteration;
        end else begin : g_nf
            posit_mac_nf dut (
                .clk(clk),
                .rst_n(rst_n),
                .in_valid(in_valid),
                .in_ready(in_ready),
                .a(a),
                .b(b),
                .c(c),
                .acc_mode(acc_mode),
                .acc_clr(acc_clr),
                .cfg_n(cfg_n),
                .cfg_ops(cfg_ops),
                .out_valid(out_valid),
                .out_ready(out_ready),
                .d(d),
                .flags(flags)
            );
            assign core_done = dut.u_wrapper.u_core.core_done;
            assign core_magnitude = dut.u_wrapper.u_core.acc;
            assign core_iterations = dut.u_wrapper.u_core.iterations_done;
            assign core_cut = dut.u_wrapper.u_core.approx_cut;
            assign core_input_cut = dut.u_wrapper.u_core.input_cut_o;
            assign core_sign = dut.u_wrapper.u_core.sign_o;
            assign core_scale = dut.u_wrapper.u_core.sf_o;
            assign core_error = dut.u_wrapper.u_core.state_error;
            assign commit_valid = dut.u_wrapper.u_core.t2_valid;
            assign commit_first = dut.u_wrapper.u_core.t2_first;
            assign commit_last = dut.u_wrapper.u_core.t2_last;
            assign commit_iteration = dut.u_wrapper.u_core.t2_iteration;
        end
    endgenerate
endmodule
// End of shared_mac_checker.sv
