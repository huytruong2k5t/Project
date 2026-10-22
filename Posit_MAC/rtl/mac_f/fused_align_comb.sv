//-----------------------------------------------------------------------------
// File          : fused_align_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : W12-F-1 fused datapath, approximate posit(32,3).
// $Source: $ $Revision: 1.0 $ $Log: Week13 RTL implementation. $
//-----------------------------------------------------------------------------
module fused_align_comb (
    input  logic [30:0] small_seed,
    input  logic [4:0] shift_amount,
    input  logic shift_all,
    output wire [30:0] aligned_small,
    output wire residual
);
    // Fixed posit32/ES3 elaboration; no public parameters.

    wire [30:0] shifted;
    wire [30:0] lost_mask;
    // Mask and data shifts are parallel. Large delta never wraps modulo 32.
    assign shifted = small_seed >> shift_amount;
    assign lost_mask = ~(31'h7fffffff << shift_amount);
    assign aligned_small = shift_all ? 31'b0 : shifted;
    assign residual = shift_all ? (|small_seed) : (|(small_seed & lost_mask));
endmodule
// End of fused_align_comb.sv
