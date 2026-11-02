//-----------------------------------------------------------------------------
// File          : quire_align_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-11-03
// Description   : FULL_TERM26/Q24 to signed972, grid2^-480. No rounding/jam.
// $Revision: 1.0 $ $Log: Q12-1024 alignment with explicit suffix/range checks. $
//-----------------------------------------------------------------------------
module quire_align_comb (
    input  logic [25:0]        magnitude,
    input  logic              sign,
    input  logic signed [10:0] sf,
    output logic [971:0]      term,
    output logic              align_error
);
    logic signed [11:0] shift_amount;
    logic [25:0] aligned_magnitude;
    logic [26:0] signed_coefficient;
    logic [971:0] extended_coefficient;
    logic [25:0] discarded_mask;

    always_comb begin
        // sf - Q24 - E_LSB = sf +456. Legal raw Posit products may be negative.
        shift_amount = {sf[10], sf} + 12'sd456;
        aligned_magnitude = magnitude;
        discarded_mask = '0;
        align_error = 1'b0;
        if (magnitude != 26'b0) begin
            if (shift_amount < 0) begin
                if (shift_amount <= -12'sd26) begin
                    align_error = 1'b1;
                end else begin
                    discarded_mask = ~(26'h3ffffff << (-shift_amount));
                    align_error = |(magnitude & discarded_mask);
                    aligned_magnitude = magnitude >> (-shift_amount);
                end
            end else if (shift_amount > 12'sd945) begin
                // At most bit25 of M; preserve signed bit971 for the sign.
                align_error = 1'b1;
            end
        end
        // Change sign while the coefficient is only27 bits. Sign extension and
        // arithmetic alignment are exact wiring/MUX operations, no972-bit adder.
        signed_coefficient = sign ? (~{1'b0, aligned_magnitude} + 27'd1)
                                  : {1'b0, aligned_magnitude};
        extended_coefficient = {{945{signed_coefficient[26]}}, signed_coefficient};
        if (align_error) term = '0;
        else if (shift_amount < 0) term = extended_coefficient;
        else term = extended_coefficient << shift_amount;
    end
endmodule
// End of quire_align_comb.sv
