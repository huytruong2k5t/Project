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

module posit_add_arith #(
    parameter int F = 27
)(
    input logic [F+4:0] x,
    input logic [F+4:0] y,
    input logic subtract,
    output wire [F+4:0] magnitude
);
    assign magnitude = subtract ? x - y : x + y;
endmodule

//-----------------------------------------------------------------------------
// End of posit_add_arith.sv
//-----------------------------------------------------------------------------
