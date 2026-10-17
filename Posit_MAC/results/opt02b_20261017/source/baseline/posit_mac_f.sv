//-----------------------------------------------------------------------------
// File          : posit_mac_f.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Fused W12-F-1 comparison MAC top. All logic in child modules.
// $Source: $ $Revision: 1.0 $ $Log: W13 W12-F-1 fused integration. $
//-----------------------------------------------------------------------------
module posit_mac_f #(
    parameter int NB=32,
    parameter int ES=3,
    parameter int FRAC_W=(NB-3-ES<12)?NB-3-ES:12,
    parameter int N_MAX=8,
    parameter bit EXACT_EN=1'b0,
    parameter bit OPS_EN=1'b1,
    parameter int ACC_WIN=32,
    parameter int N_W=(N_MAX>1)?$clog2(N_MAX+1):1
)(
    input logic clk,
    input logic rst_n,
    input logic in_valid,
    output wire in_ready,
    input logic [NB-1:0] a,
    input logic [NB-1:0] b,
    input logic [NB-1:0] c,
    input logic acc_mode,
    input logic acc_clr,
    input logic cfg_mode,
    input logic [N_W-1:0] cfg_n,
    input logic [1:0] cfg_ops,
    output wire out_valid,
    input logic out_ready,
    output wire [NB-1:0] d,
    output wire [4:0] flags
);
    mac_f_wrapper #(
        .NB (NB),
        .ES (ES),
        .FRAC_W (FRAC_W),
        .N_MAX (N_MAX),
        .EXACT_EN (EXACT_EN),
        .OPS_EN (OPS_EN),
        .ACC_WIN (ACC_WIN),
        .N_W (N_W)) u_wrapper (
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
endmodule
// End of posit_mac_f.sv
