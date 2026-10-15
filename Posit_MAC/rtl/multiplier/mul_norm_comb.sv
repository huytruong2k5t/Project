//-----------------------------------------------------------------------------
// File          : mul_norm_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : Normalize on the L1 grid, remove hidden, adapt to F_IN.
//                 No rounding. input_cut is NOT numerical RNE sticky.
// $Source: $ $Revision: 1.0 $ $Log: Initial week9 implementation. $
//-----------------------------------------------------------------------------
module mul_norm_comb #(
    parameter int FRAC_MAX = 27,
    parameter int FRAC_W = 12,
    parameter int ROUND_SCHEME = 0,
    parameter bit EXACT_EN = 1'b1,
    parameter int ACC_W = EXACT_EN ? ((2*FRAC_MAX+2 > FRAC_W+4) ? 2*FRAC_MAX+2 : FRAC_W+4) : FRAC_W+4,
    parameter int SF_W = 11,
    parameter int F_IN = 2*FRAC_MAX+1
)(
    input logic cfg_mode,
    input logic [ACC_W-1:0] acc,
    input logic sticky_acc,
    input logic signed [SF_W-1:0] sf,
    output logic signed [SF_W-1:0] sf_norm,
    output logic [F_IN-1:0] frac_norm,
    output logic sticky_norm
);
    logic [ACC_W-1:0] grid;
    integer q;
    always_comb begin
        q = 2*FRAC_MAX;
        grid = acc;
        if (cfg_mode) begin
            q = FRAC_W + ((ROUND_SCHEME == 1) ? 2 : 0);
            if (ROUND_SCHEME == 0) begin
                grid = acc >> 2;
            end
        end
        sf_norm = sf;
        sticky_norm = sticky_acc;
        if (grid[q+1]) begin
            sticky_norm = sticky_norm | grid[0];
            grid = grid >> 1;
            sf_norm = sf + 1'b1;
        end
        frac_norm = '0;
        // Generate the adapter wiring without a second rounding operation.
        for (int bit_index = 0; bit_index < ACC_W; bit_index++) begin
            if (bit_index < q) begin
                if (bit_index + F_IN >= q) begin
                    frac_norm[bit_index + F_IN - q] = grid[bit_index];
                end else begin
                    sticky_norm = sticky_norm | grid[bit_index];
                end
            end
        end
    end
endmodule
// End of mul_norm_comb.sv
