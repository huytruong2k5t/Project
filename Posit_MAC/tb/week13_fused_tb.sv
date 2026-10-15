// Verification only; stage observers do not exist on the production top.
module week13_fused_tb (
    input logic clk,
    input logic rst_n,
    input logic in_valid,
    output wire in_ready,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    input logic acc_mode,
    input logic acc_clr,
    input logic cfg_mode,
    input logic [3:0] cfg_n,
    input logic [1:0] cfg_ops,
    output wire out_valid,
    input logic out_ready,
    output wire [31:0] d,
    output wire [4:0] flags,
    output wire  dbg_v1,
    output wire  dbg_v2,
    output wire  dbg_v3,
    output wire  dbg_v4,
    output wire  dbg_v5,
    output wire  dbg_core_done,
    output wire [13:0] dbg_raw_magnitude,
    output wire [10:0] dbg_raw_scale,
    output wire [1:0] dbg_raw_loss,
    output wire [10:0] dbg_anchor,
    output wire [30:0] dbg_large_seed,
    output wire [30:0] dbg_small_seed,
    output wire [4:0] dbg_shift_amount,
    output wire  dbg_shift_all,
    output wire [30:0] dbg_large_value,
    output wire [30:0] dbg_small_value,
    output wire  dbg_tail,
    output wire [31:0] dbg_retained_sum,
    output wire [30:0] dbg_magnitude,
    output wire  dbg_sum_sign,
    output wire [10:0] dbg_sf_final,
    output wire [52:0] dbg_fraction,
    output wire  dbg_zero,
    output wire  dbg_sticky,
    output wire [31:0] dbg_accumulator
);
    posit_mac_f u_dut (
        .clk (clk),
        .rst_n (rst_n),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .a (a),
        .b (b),
        .c (c),
        .acc_mode (acc_mode),
        .acc_clr (acc_clr),
        .cfg_mode (cfg_mode),
        .cfg_n (cfg_n),
        .cfg_ops (cfg_ops),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .d (d),
        .flags (flags)
    );
    assign dbg_v1 = u_dut.u_wrapper.u_fused.valid_q[0];
    assign dbg_v2 = u_dut.u_wrapper.u_fused.valid_q[1];
    assign dbg_v3 = u_dut.u_wrapper.u_fused.valid_q[2];
    assign dbg_v4 = u_dut.u_wrapper.u_fused.valid_q[3];
    assign dbg_v5 = u_dut.u_wrapper.u_fused.valid_q[4];
    assign dbg_core_done = u_dut.u_wrapper.core_done;
    assign dbg_raw_magnitude = u_dut.u_wrapper.p_magnitude;
    assign dbg_raw_scale = u_dut.u_wrapper.core_sf;
    assign dbg_raw_loss = u_dut.u_wrapper.loss_in;
    assign dbg_anchor = u_dut.u_wrapper.u_fused.f1_q.anchor;
    assign dbg_large_seed = u_dut.u_wrapper.u_fused.f1_q.large_value;
    assign dbg_small_seed = u_dut.u_wrapper.u_fused.f1_q.small_value;
    assign dbg_shift_amount = u_dut.u_wrapper.u_fused.f1_q.shift_amount;
    assign dbg_shift_all = u_dut.u_wrapper.u_fused.f1_q.shift_all;
    assign dbg_large_value = u_dut.u_wrapper.u_fused.f2_q.large_value;
    assign dbg_small_value = u_dut.u_wrapper.u_fused.f2_q.small_value;
    assign dbg_tail = u_dut.u_wrapper.u_fused.f2_q.residual;
    assign dbg_retained_sum = u_dut.u_wrapper.u_fused.f3_q.retained_sum;
    assign dbg_magnitude = u_dut.u_wrapper.u_fused.f4_q.magnitude;
    assign dbg_sum_sign = u_dut.u_wrapper.u_fused.f4_q.sign;
    assign dbg_sf_final = u_dut.u_wrapper.u_fused.f5_q.sf;
    assign dbg_fraction = u_dut.u_wrapper.u_fused.f5_q.frac;
    assign dbg_zero = u_dut.u_wrapper.u_fused.f5_q.zero;
    assign dbg_sticky = u_dut.u_wrapper.u_fused.f5_q.sticky;
    assign dbg_accumulator = u_dut.u_wrapper.accumulator_q;
endmodule
