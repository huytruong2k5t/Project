//-----------------------------------------------------------------------------
// File          : paper_norm_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP - separate research branch
// Creation Date : 2026-10-09
// Description   : Normalize Q2.12 and adapt to the shared TRUNC packer.
//                 Numerical contract is the frozen Fig.3 reconstruction.
// $Source: $ $Revision: 1.0 $ $Log: Autonomous research integration. $
//-----------------------------------------------------------------------------
module paper_norm_comb (
    input logic [13:0] acc,
    input logic signed [10:0] sf_base,
    input logic anchor,
    output logic [13:0] normalized,
    output logic signed [10:0] sf,
    output wire [52:0] frac
);
    assign frac = {normalized[11:0], 41'b0};

    always_comb begin
        normalized = acc;
        sf = sf_base + (anchor ? 11'sd1 : 11'sd0);

        for (int k = 0; k < 14; k++) begin
            if (normalized >= 14'd8192) begin
                normalized = normalized >> 1;
                sf = sf + 11'sd1;
            end else if (normalized != 0 && normalized < 14'd4096) begin
                normalized = normalized << 1;
                sf = sf - 11'sd1;
            end
        end
    end
endmodule
// End of paper_norm_comb.sv
