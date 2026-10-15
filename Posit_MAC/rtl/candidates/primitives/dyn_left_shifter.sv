//-----------------------------------------------------------------------------
// File          : dyn_left_shifter.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Isolated candidate. Cascade handles low-bit overshifts;
//                 only unimplemented high shift bits need an output guard.
// $Source: $ $Revision: 1.1-candidate $ $Log: BASE-01; no pipeline change. $
//-----------------------------------------------------------------------------
module dyn_left_shifter #(
    parameter int N       = 32,
    parameter int SHIFT_W = (N > 1) ? $clog2(N) : 1
)(
    input  logic [N-1:0]       in,
    input  logic [SHIFT_W-1:0] b,
    output logic [N-1:0]       out
);
    generate
        if (N < 1 || SHIFT_W < 1) begin : g_invalid
            initial $fatal(1, "dyn_left_shifter: invalid parameters");
        end

        if (N == 1) begin : g_single_bit
            assign out = (|b) ? 1'b0 : in;
        end else begin : g_multi_bit
            localparam int S = $clog2(N);
            localparam int EFF_S = (SHIFT_W < S) ? SHIFT_W : S;

            logic [N-1:0] stage [EFF_S:0] /* verilator split_var */;
            assign stage[0] = in;

            for (genvar i = 0; i < EFF_S; i++) begin : g_stages
                localparam int STEP = 1 << i;
                assign stage[i+1] = b[i]
                    ? {stage[i][N-1-STEP:0], {STEP{1'b0}}}
                    : stage[i];
            end

            // A sum of the implemented shifts >= N already clears every bit.
            // High b bits represent shifts beyond this cascade's range.
            if (SHIFT_W > S) begin : g_high_guard
                assign out = (|b[SHIFT_W-1:S]) ? '0 : stage[EFF_S];
            end else begin : g_no_high_guard
                assign out = stage[EFF_S];
            end
        end
    endgenerate
endmodule
// End of dyn_left_shifter.sv
