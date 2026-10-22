//-----------------------------------------------------------------------------
// File          : posit_mac_nf.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-13
// Description   : Non-fused comparison MAC top. All logic in child modules.
// $Source: $ $Revision: 1.0 $ $Log: Week9 baseline integration. $
//-----------------------------------------------------------------------------
module posit_mac_nf (
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
    // NB: 32 (original).
    
    // ES: 2 (original).
    
    // FRAC_W: (NB-3-ES<12)?NB-3-ES:12 (original).
    
    // N_MAX: 8 (original).
    
    // EXACT_EN: 1'b1 (original).
    
    // OPS_EN: 1'b1 (original).
    
    // N_W: (N_MAX>1)?$clog2(N_MAX+1):1 (original).
    

    mac_nf_wrapper  u_wrapper (
        .clk(clk),
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
// End of posit_mac_nf.sv
