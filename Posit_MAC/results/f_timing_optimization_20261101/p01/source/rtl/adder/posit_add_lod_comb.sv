//-----------------------------------------------------------------------------
// File          : posit_add_lod_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-31
// Description   : Stage S4 of 5-stage Posit(32,3) adder: unified 31-bit
//                 Radix-4 Leading-One Detection and carry-jam preparation.
//-----------------------------------------------------------------------------
module posit_add_lod_comb (
    input  logic [30:0] magnitude,
    input  logic        alignment_tail,
    output logic [29:0] norm_seed,
    output logic [4:0]  leading_count,
    output logic        nonzero,
    output logic        sticky_raw
);
    lod_lzd_core_fixed2 u_lod (
        .in  (magnitude),
        .K   (leading_count),
        .vld (nonzero)
    );

    wire lost_carry = magnitude[30] & magnitude[0];

    assign norm_seed  = {magnitude[29:2], magnitude[1] | lost_carry, magnitude[0]};
    assign sticky_raw = alignment_tail | lost_carry;

endmodule
//-----------------------------------------------------------------------------
// End of posit_add_lod_comb.sv
//-----------------------------------------------------------------------------

