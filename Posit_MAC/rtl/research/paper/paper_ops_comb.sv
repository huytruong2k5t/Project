//-----------------------------------------------------------------------------
// File          : paper_ops_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP - separate research branch
// Creation Date : 2026-10-09
// Description   : PT2 prefix7 zero-extended to Q12; tie-A is an assumption.
//                 Not a normative cfg_ops policy or recovered author RTL.
// $Source: $ $Revision: 1.0 $ $Log: W9-R1 frozen reconstruction. $
//-----------------------------------------------------------------------------
module paper_ops_comb (
    input logic [12:0] mant_a,
    input logic [12:0] mant_b,
    input logic force_a,
    output logic [12:0] x_mant,
    output logic [12:0] y_mant,
    output logic [11:0] score_a,
    output logic [11:0] score_b,
    output logic swapped
);
    function automatic [11:0] score(input logic [6:0] prefix);
        integer m, first_power, residue, second_power, prediction, error;
        begin
            m = (128 + prefix) * 32;
            first_power = (m >= 6144) ? 8192 : 4096;
            residue = (m >= 6144) ? 8191-m : m-4096;
            second_power = 0;
            for (int b=0; b<12; b++) begin
                if (residue >= (1 << b)) begin
                    second_power = 1 << b;
                end
            end
            if (second_power > 1 && 2*residue >= 3*second_power) begin
                second_power = second_power * 2;
            end
            prediction = first_power + ((m >= 6144) ? -second_power : second_power);
            error = m-prediction;
            if (error < 0) error = -error;
            score = error[11:0];
        end
    endfunction
    always_comb begin
        score_a = score(mant_a[11:5]);
        score_b = score(mant_b[11:5]);
        swapped = !force_a && (score_b < score_a);
        x_mant = swapped ? mant_b : mant_a;
        y_mant = swapped ? mant_a : mant_b;
    end
endmodule
// End of paper_ops_comb.sv
