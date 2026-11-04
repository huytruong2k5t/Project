//-----------------------------------------------------------------------------
// File          : posit_mac_quire.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-11-03
// Description   : Structural Posit(32,3) Q12-1024 top; no C or extra cfg_mode.
// $Revision: 1.0 $ $Log: CLEAR00/MAC01/READ10, one ordered response per command. $
//-----------------------------------------------------------------------------
module posit_mac_quire (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    output wire         in_ready,
    input  logic [1:0]  q_cmd,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  cfg_n,
    input  logic [1:0]  cfg_ops,
    output wire         out_valid,
    input  logic        out_ready,
    output wire [1:0]   out_cmd,
    output wire [31:0]  d,
    output wire [4:0]   flags,
    output wire         q_overflow
);
    mac_quire_wrapper u_wrapper (
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
endmodule
// End of posit_mac_quire.sv
