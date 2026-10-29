//-----------------------------------------------------------------------------
// File          : opt17_norm_nf.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-13
// OPT-17       : FULL_TERM study, 2026-10-29; frozen parent unchanged.
// Description   : Preserve raw prepack value when normalizing a carry.
//-----------------------------------------------------------------------------
// $Source: $ $Revision: 1.0 $ $Log: W11-01 independent dyadic oracle verified. $
module opt17_norm_nf (
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
            sf_norm = sf + sf_t'(acc[25]);
            frac_norm = acc[25] ? {acc[24:0], 28'b0}
                                : {acc[23:0], 29'b0};
        end else begin
            sf_norm = sf + sf_t'(acc[53]);
            frac_norm = acc[53] ? acc[52:0] : {acc[51:0], 1'b0};
        end
    end
endmodule
// End of opt17_norm_nf.sv
