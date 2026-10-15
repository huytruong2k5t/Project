//-----------------------------------------------------------------------------
// File          : fused_norm_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : W12-F-1 fused datapath, approximate posit(32,3).
// $Source: $ $Revision: 1.0 $ $Log: Week13 RTL implementation. $
//-----------------------------------------------------------------------------
module fused_norm_comb #(
    parameter int SF_W = 11
)(
    input  logic [30:0] magnitude,
    input  logic signed [SF_W-1:0] anchor,
    output wire is_zero,
    output wire signed [SF_W-1:0] sf,
    output wire [52:0] frac
);
    typedef logic signed [SF_W-1:0] sf_t;
    wire [4:0] leading_count;
    wire nonzero;
    wire [29:0] fraction_shifted;
    wire signed [5:0] scale_adjust;
    lod_lzd_core #(
        .N (31),
        .MODE (0)
    ) u_lod (
        .in (magnitude),
        .K (leading_count),
        .vld (nonzero)
    );
    assign fraction_shifted = magnitude[29:0] << leading_count;
    // h=30-count, Q=29: sf=anchor+1-count. Small subtract runs beside shift.
    assign scale_adjust = 6'sd1 - $signed({1'b0, leading_count});
    assign sf = nonzero ? anchor + sf_t'(scale_adjust) : '0;
    assign frac = {fraction_shifted, 23'b0};
    assign is_zero = !nonzero;
endmodule
// End of fused_norm_comb.sv
