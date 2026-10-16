//-----------------------------------------------------------------------------
// File          : dyn_left_shifter.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP
// Creation Date : 2026-10-16
// Description   : Candidate: reverse.
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
        if (N == 1) begin : g_single
            assign out = (|b) ? 1'b0 : in;
        end else begin : g_multi
            localparam int S = $clog2(N);
            localparam int EFF_S = (SHIFT_W < S) ? SHIFT_W : S;
            localparam int STAGES = EFF_S;
            wire [N-1:0] stage [STAGES:0] /* verilator split_var */;
            assign stage[0] = in;
            for (genvar i = 0; i < STAGES; i++) begin : g_stages
                localparam int BIT_INDEX = EFF_S - 1 - i;
                localparam int STEP = 1 << BIT_INDEX;
                assign stage[i+1] = b[BIT_INDEX] ? {stage[i][N-1-STEP:0], {STEP{1'b0}}} : stage[i];
            end
            if (SHIFT_W > S) begin : g_guard
                assign out = (|b[SHIFT_W-1:S]) ? {N{1'b0}} : stage[STAGES];
            end else begin : g_no_guard
                assign out = stage[STAGES];
            end
        end
    endgenerate
endmodule
// End of dyn_left_shifter.sv
