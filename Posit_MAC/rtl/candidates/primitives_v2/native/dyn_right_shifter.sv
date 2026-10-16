//-----------------------------------------------------------------------------
// File          : dyn_right_shifter.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP
// Creation Date : 2026-10-16
// Description   : Candidate: native.
// $Source: $ $Revision: 2.0-candidate $ $Log: No pipeline or interface change. $
//-----------------------------------------------------------------------------
module dyn_right_shifter #(
    parameter int N = 32,
    parameter int SHIFT_W = (N > 1) ? $clog2(N) : 1,
    parameter bit ARITH = 1'b0
)(
    input logic [N-1:0] in,
    input logic [SHIFT_W-1:0] b,
    input logic fill_val,
    output logic [N-1:0] out
);
    logic fill;
    assign fill = ARITH ? in[N-1] : fill_val;
    generate
        if (N < 1 || SHIFT_W < 1) begin : g_invalid
            initial $fatal(1, "dyn_right_shifter: invalid parameters");
        end
        // Transform custom-fill shift into a zero-fill shift.
        // The sign/custom pad is recovered after shifting, including overshift.
        wire [N-1:0] data_zero;
        wire [N-1:0] shifted_zero;
        assign data_zero = in ^ {N{fill}};
        assign shifted_zero = data_zero >> b;
        assign out = shifted_zero ^ {N{fill}};
    endgenerate
endmodule
// End of dyn_right_shifter.sv
