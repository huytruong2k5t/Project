//-----------------------------------------------------------------------------
// File          : mul_prepack_norm_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-13
// Description   : Preserve raw prepack value when normalizing a carry.
//-----------------------------------------------------------------------------
// $Source: $ $Revision: 1.0 $ $Log: W11-01 independent dyadic oracle verified. $
module mul_prepack_norm_comb (
    input logic cfg_mode,
    input logic [53:0] acc,
    input logic signed [10:0] sf,
    output logic signed [10:0] sf_norm,
    output logic [52:0] frac_norm
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    
    localparam int SF_W = 11;
    typedef logic signed [SF_W-1:0] sf_t;

    always_comb begin
        // Preserve every prepack bit; a carry changes only the hidden position.
        if (cfg_mode) begin
            sf_norm = sf + sf_t'(acc[15]);
            frac_norm = acc[15] ? {acc[14:2], 40'b0}
                                : {acc[13:2], 41'b0};
        end else begin
            sf_norm = sf + sf_t'(acc[53]);
            frac_norm = acc[53] ? acc[52:0] : {acc[51:0], 1'b0};
        end
    end
endmodule
// End of mul_prepack_norm_comb.sv
