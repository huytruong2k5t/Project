//-----------------------------------------------------------------------------
// File          : posit_add_arith.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-12
// Description   : Full-width magnitude add/subtract, retaining the carry bit.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: W10 implementation, SPEC 5.8-A..D. $

module posit_add_arith (
    input logic [30:0] x,
    input logic [30:0] y,
    input logic subtract,
    output wire [30:0] magnitude
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    

    assign magnitude = subtract ? x - y : x + y;
endmodule

//-----------------------------------------------------------------------------
// End of posit_add_arith.sv
//-----------------------------------------------------------------------------
