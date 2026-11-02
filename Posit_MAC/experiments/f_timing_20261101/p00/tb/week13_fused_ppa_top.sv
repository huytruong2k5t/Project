// Measurement wrapper only: explicit global clock buffer, no logic changes.
module week13_fused_ppa_top (
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
    output wire [4:0] flags

);
    wire clk_core;
    BUFG u_clk (.I(clk), .O(clk_core));
    posit_mac_f u_dut (
        .clk(clk_core),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .a(a),
        .b(b),
        .c(c),
        .acc_mode(acc_mode),
        .acc_clr(acc_clr),
        .cfg_mode(cfg_mode),
        .cfg_n(cfg_n),
        .cfg_ops(cfg_ops),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .d(d),
        .flags(flags)
    );
endmodule
