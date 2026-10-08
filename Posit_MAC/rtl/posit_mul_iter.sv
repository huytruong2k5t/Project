//-----------------------------------------------------------------------------
// File          : posit_mul_iter.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : Standalone multiplier top. All logic in child modules.
// $Source: $ $Revision: 1.0 $ $Log: Week9 baseline integration. $
//-----------------------------------------------------------------------------
module posit_mul_iter #(
    parameter int NB=32,
    parameter int ES=2,
    parameter int FRAC_W=(NB-3-ES<12)?NB-3-ES:12,
    parameter int N_MAX=8,
    parameter int ROUND_SCHEME=0,
    parameter ROUND_MODE="RNE",
    parameter bit EXACT_EN=1'b1,
    parameter bit OPS_EN=1'b1,
    parameter int N_W=(N_MAX>1)?$clog2(N_MAX+1):1
)(
    input logic clk,
    input logic rst_n,
    input logic in_valid,
    output wire in_ready,
    input logic [NB-1:0] a,
    input logic [NB-1:0] b,
    input logic cfg_mode,
    input logic [N_W-1:0] cfg_n,
    input logic [1:0] cfg_ops,
    output wire out_valid,
    input logic out_ready,
    output wire [NB-1:0] d,
    output wire [4:0] flags
);
    mul_iter_wrapper #(.NB(NB),.ES(ES),.FRAC_W(FRAC_W),.N_MAX(N_MAX),
        .ROUND_SCHEME(ROUND_SCHEME),.ROUND_MODE(ROUND_MODE),.EXACT_EN(EXACT_EN),.OPS_EN(OPS_EN)) u_wrapper (
        .clk(clk),.rst_n(rst_n),.in_valid(in_valid),.in_ready(in_ready),.a(a),.b(b),
        .cfg_mode(cfg_mode),.cfg_n(cfg_n),.cfg_ops(cfg_ops),.out_valid(out_valid),
        .out_ready(out_ready),.d(d),.flags(flags)
    );
endmodule
// End of posit_mul_iter.sv
