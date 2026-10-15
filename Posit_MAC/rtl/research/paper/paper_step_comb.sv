//-----------------------------------------------------------------------------
// File          : paper_step_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP - separate research branch
// Creation Date : 2026-10-09
// Description   : Q12 RND/complement, first anchor, signed coefficient.
//                 13 payload bits plus carry; FLOOR before add/subtract.
//                 Functional step, without a pipeline or author-RTL claim.
// $Source: $ $Revision: 1.0 $ $Log: W9-R1 frozen reconstruction. $
//-----------------------------------------------------------------------------
module paper_step_comb (
    input logic [12:0] mantissa,
    input logic signed [7:0] exponent,
    input logic negative_coefficient,
    input logic anchor,
    input logic [12:0] y_mant,
    input logic [13:0] acc,
    output logic signed [7:0] power,
    output logic [12:0] mantissa_next,
    output logic signed [7:0] exponent_next,
    output logic negative_next,
    output logic [13:0] term,
    output logic term_tail,
    output logic [13:0] acc_next,
    output logic state_error
);
    logic up;
    logic [12:0] residue;
    logic signed [15:0] sum;
    integer shift_amount;
    always_comb begin
        up = mantissa[11];
        power = exponent + (up ? 8'sd1 : 8'sd0);
        shift_amount = (anchor ? 1 : 0) - $signed(power);
        term = '0;
        term_tail = 1'b0;
        if (shift_amount >= 0) begin
            term = {1'b0, y_mant} >> shift_amount;
            for (int b=0; b<13; b++) begin
                if (b < shift_amount) term_tail = term_tail | y_mant[b];
            end
        end
        sum = $signed({2'b00, acc});
        if (negative_coefficient) begin
            sum = sum - $signed({2'b00, term});
        end else begin
            sum = sum + $signed({2'b00, term});
        end
        acc_next = sum[13:0];
        state_error = shift_amount < 0 || sum < 0 || sum > 16383 ||
                      mantissa < 4096;
        residue = up ? (13'd8191 - mantissa) : (mantissa - 13'd4096);
        exponent_next = exponent;
        for (int b=0; b<12; b++) begin
            if (residue != 0 && !residue[12]) begin
                residue = residue << 1;
                exponent_next = exponent_next - 8'sd1;
            end
        end
        mantissa_next = residue;
        negative_next = negative_coefficient ^ up;
    end
endmodule
// End of paper_step_comb.sv
