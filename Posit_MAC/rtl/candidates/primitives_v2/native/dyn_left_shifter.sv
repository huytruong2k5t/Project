//-----------------------------------------------------------------------------
// File          : dyn_left_shifter.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP
// Creation Date : 2026-10-16
// Description   : Candidate: native.
// $Source: $ $Revision: 2.0-candidate $ $Log: No pipeline or interface change. $
//-----------------------------------------------------------------------------
module dyn_left_shifter #(
    parameter int N = 32,
    parameter int SHIFT_W = (N > 1) ? $clog2(N) : 1
)(
    input logic [N-1:0] in,
    input logic [SHIFT_W-1:0] b,
    output logic [N-1:0] out
);
    generate
        if (N < 1 || SHIFT_W < 1) begin : g_invalid
            initial $fatal(1, "dyn_left_shifter: invalid parameters");
        end
        assign out = in << b;
    endgenerate
endmodule
// End of dyn_left_shifter.sv
