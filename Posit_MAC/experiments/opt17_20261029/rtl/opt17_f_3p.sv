//-----------------------------------------------------------------------------
// File          : opt17_f_3p.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP, OPT-17
// Creation Date : 2026-10-29
// Description   : Two-Parser prefetch with early core-result handoff.
// $Source: $ $Revision: 1.0 $ $Log: Separate FULL_TERM candidate. $
//-----------------------------------------------------------------------------
module opt17_f_3p (
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
    opt17_f_3p_wrapper u_wrapper (
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
// End of opt17_f_3p.sv
