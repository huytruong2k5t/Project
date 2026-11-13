//-----------------------------------------------------------------------------
// File          : mul_prepack_norm_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Revision      : 2026-11-02 shared approximate12 FULL_TERM26/Q24
// Description   : Lossless shared prepack26/Q24 to fraction26 adapter; no RNE.
//-----------------------------------------------------------------------------

module mul_prepack_norm_comb (
    input  logic [25:0]        acc,
    input  logic signed [10:0] sf,
    input  logic signed [10:0] sf_inc,
    output wire signed [10:0]  sf_norm,
    output wire [25:0]        frac_norm
);
    // sf_inc is precomputed at context launch to avoid a carry chain here.
    assign sf_norm = acc[25] ? sf_inc : sf;
    assign frac_norm = acc[25] ? {acc[24:0], 1'b0}
                               : {acc[23:0], 2'b0};
endmodule
// End of mul_prepack_norm_comb.sv
