//-----------------------------------------------------------------------------
// File          : dyn_right_shifter.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Isolated candidate; overshifts emerge from the cascade.
//                 Retains custom fill, sign fill and the high-bit guard.
// $Source: $ $Revision: 1.1-candidate $ $Log: BASE-01; no pipeline change. $
//-----------------------------------------------------------------------------
module dyn_right_shifter #(
    parameter int N       = 32,
    parameter int SHIFT_W = (N > 1) ? $clog2(N) : 1,
    parameter bit ARITH   = 1'b0
)(
    input  logic [N-1:0]       in,
    input  logic [SHIFT_W-1:0] b,
    input  logic               fill_val,
    output logic [N-1:0]       out
);
    logic fill;
    assign fill = ARITH ? in[N-1] : fill_val;

    generate
        if (N < 1 || SHIFT_W < 1) begin : g_invalid
            initial $fatal(1, "dyn_right_shifter: invalid parameters");
        end

        if (N == 1) begin : g_single_bit
            assign out = (|b) ? fill : in;
        end else begin : g_multi_bit
            localparam int S = $clog2(N);
            localparam int EFF_S = (SHIFT_W < S) ? SHIFT_W : S;

            logic [N-1:0] stage [EFF_S:0] /* verilator split_var */;
            assign stage[0] = in;

            for (genvar i = 0; i < EFF_S; i++) begin : g_stages
                localparam int STEP = 1 << i;
                assign stage[i+1] = b[i]
                    ? {{STEP{fill}}, stage[i][N-1:STEP]}
                    : stage[i];
            end

            if (SHIFT_W > S) begin : g_high_guard
                assign out = (|b[SHIFT_W-1:S]) ? {N{fill}} : stage[EFF_S];
            end else begin : g_no_high_guard
                assign out = stage[EFF_S];
            end
        end
    endgenerate
endmodule
// End of dyn_right_shifter.sv
