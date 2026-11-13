//-----------------------------------------------------------------------------
// File          : posit_add_arith_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-31
// Description   : Stage S3 of 5-stage Posit(32,3) adder: unsigned 31-bit
//                 add/subtract (guaranteed X >= Y) and parallel sf_base + 1.
//-----------------------------------------------------------------------------
module posit_add_arith_comb (
    input  logic [25:0]        x_frac,
    input  logic [30:0]        y,
    input  logic               subtract,
    input  logic signed [10:0] sf_base,
    output logic [30:0]        magnitude,
    output logic signed [10:0] sf_inc
);
    wire [30:0] x = {1'b0, 1'b1, x_frac, 3'b000};

    assign magnitude = subtract ? (x - y) : (x + y);
    assign sf_inc    = sf_base + 11'sd1;

endmodule
//-----------------------------------------------------------------------------
// End of posit_add_arith_comb.sv
//-----------------------------------------------------------------------------

