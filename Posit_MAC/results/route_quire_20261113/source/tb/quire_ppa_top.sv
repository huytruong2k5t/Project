//-----------------------------------------------------------------------------
// File: quire_ppa_top.sv | Posit MAC IP | 2026-11-03
// OOC clock-buffer adapter; no arithmetic or numerical changes.
//-----------------------------------------------------------------------------
module quire_ppa_top (
    input wire clk,
    input wire rst_n,
    input wire in_valid,
    output wire in_ready,
    input wire [1:0] q_cmd,
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] cfg_n,
    input wire [1:0] cfg_ops,
    output wire out_valid,
    input wire out_ready,
    output wire [1:0] out_cmd,
    output wire [31:0] d,
    output wire [4:0] flags,
    output wire q_overflow
);
    wire clk_buf;
    BUFG u_clk (
        .I (clk),
        .O (clk_buf)
    );
    posit_mac_quire u_dut (
        .clk (clk_buf),
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
// End of quire_ppa_top.sv
