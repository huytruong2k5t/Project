//-----------------------------------------------------------------------------
// File          : dyn_right_shifter.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP
// Creation Date : 2026-10-16
// Description   : Candidate: reverse.
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
        if (N == 1) begin : g_single
            assign out = (|b) ? fill : in;
        end else begin : g_multi
            localparam int S = $clog2(N);
            localparam int EFF_S = (SHIFT_W < S) ? SHIFT_W : S;
            localparam int STAGES = EFF_S;
            wire [N-1:0] stage [STAGES:0] /* verilator split_var */;
            assign stage[0] = in;
            for (genvar i = 0; i < STAGES; i++) begin : g_stages
                localparam int BIT_INDEX = EFF_S - 1 - i;
                localparam int STEP = 1 << BIT_INDEX;
                assign stage[i+1] = b[BIT_INDEX] ? {{STEP{fill}}, stage[i][N-1:STEP]} : stage[i];
            end
            if (SHIFT_W > S) begin : g_guard
                assign out = (|b[SHIFT_W-1:S]) ? {N{fill}} : stage[STAGES];
            end else begin : g_no_guard
                assign out = stage[STAGES];
            end
        end
    endgenerate
endmodule
// End of dyn_right_shifter.sv
