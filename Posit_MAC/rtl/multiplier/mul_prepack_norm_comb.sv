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
    // FRAC_MAX: 26 (original).
    localparam int FRAC_MAX = 26;
    // FRAC_W: 12 (original).
    localparam int FRAC_W = 12;
    // EXACT_EN: 1'b1 (original).
    
    // ACC_W: EXACT_EN ? ((2*FRAC_MAX+2 > FRAC_W+4) ? 2*FRAC_MAX+2 : FRAC_W+4) : FRAC_W+4 (original).
    localparam int ACC_W = 54;
    // SF_W: 11 (original).
    localparam int SF_W = 11;
    // F_IN: 2*FRAC_MAX+1 (original).
    localparam int F_IN = 53;

    logic [ACC_W-1:0] grid;
    integer q;
    integer hidden_position;
    typedef logic signed [SF_W-1:0] sf_t;

    always_comb begin
        grid = cfg_mode ? acc >> 2 : acc;
        q = cfg_mode ? FRAC_W : 2*FRAC_MAX;
        hidden_position = q;
        sf_norm = sf;
        if (grid[q+1]) begin
            hidden_position = q+1;
            sf_norm = sf + sf_t'(1);
        end
        // Keep the original grid. Changing the hidden-bit position costs no bit.
        frac_norm = '0;
        for (int bit_index = 0; bit_index < ACC_W; bit_index++) begin
            if (bit_index < hidden_position && bit_index+F_IN >= hidden_position) begin
                frac_norm[bit_index+F_IN-hidden_position] = grid[bit_index];
            end
        end
    end
endmodule
// End of mul_prepack_norm_comb.sv
