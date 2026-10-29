//-----------------------------------------------------------------------------
// File          : posit_mac_f.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Fused W12-F-1 comparison MAC top. All logic in child modules.
// $Source: $ $Revision: 1.0 $ $Log: W13 W12-F-1 fused integration. $
//-----------------------------------------------------------------------------
module posit_mac_f (
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
    // Fixed posit32/ES3 elaboration; no public parameters.
    
    
    
    
    
    
    
    

    mac_f_wrapper  u_wrapper (
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
