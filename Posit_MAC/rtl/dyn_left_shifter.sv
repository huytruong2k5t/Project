//-----------------------------------------------------------------------------
// File          : dyn_left_shifter.sv
// Author(s)     : Dan Huy
// Email         : 
// Project       : Posit MAC IP (Approximate & Iterative Posit MAC)
// Creation Date : 2026-10-02
//
// Description   : Parameterized Logarithmic Dynamic Left Shifter.
//                 Uses an S-stage multiplexer cascade (S = $clog2(N)).
//                 Logic depth is O(log2 N), hardware-optimized for FPGA LUTs.
//                 Shifting by 2^i is pure wiring (zero logic gates).
//                 Includes static overflow detection: if shift amount b >= N,
//                 the output is safely clamped to all zeros ({N{1'b0}}).
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: $

module dyn_left_shifter #(
    parameter int N       = 32,
    parameter int SHIFT_W = (N > 1) ? $clog2(N) : 1
)(
    input  logic [N-1:0]       in,
    input  logic [SHIFT_W-1:0] b,
    output logic [N-1:0]       out
);

    //-------------------------------------------------------------------------
    // Parameter Validation
    //-------------------------------------------------------------------------
    generate
        if (N < 1) begin : g_param_check_n
            initial $fatal(1, "dyn_left_shifter: Parameter N must be >= 1, got %0d", N);
        end
        if (SHIFT_W < 1) begin : g_param_check_sw
            initial $fatal(1, "dyn_left_shifter: Parameter SHIFT_W must be >= 1, got %0d", SHIFT_W);
        end
    endgenerate

    //-------------------------------------------------------------------------
    // Implementation
    //-------------------------------------------------------------------------
    if (N == 1) begin : g_single_bit
        assign out = (|b) ? 1'b0 : in;
    end else begin : g_multi_bit
        localparam int S = $clog2(N);

        // Stage array: stage[0] is input, stage[S] is output after S MUX stages
        logic [N-1:0] stage [S:0];
        assign stage[0] = in;

        genvar i;
            for (i = 0; i < S; i = i + 1) begin : g_stages
                localparam int SHIFT_VAL = 1 << i;

                // Select bit b[i] if within range of SHIFT_W, else 0
                logic sel;
                if (i < SHIFT_W) begin : g_sel_in_range
                    assign sel = b[i];
                end else begin : g_sel_out_of_range
                    assign sel = 1'b0;
                end

                if (SHIFT_VAL < N) begin : g_shift_step
                    assign stage[i+1] = sel ? {stage[i][N - 1 - SHIFT_VAL : 0], {SHIFT_VAL{1'b0}}}
                                            : stage[i];
                end else begin : g_shift_bypass
                    assign stage[i+1] = stage[i];
                end
            end

        // Overflow detection (b >= N):
        // 1. Any upper bit b[SHIFT_W-1:S] is 1 (when SHIFT_W > S)
        // 2. Or lower S bits b[S-1:0] >= N (when N is not a power of 2)
        logic is_overflow;
        if (SHIFT_W > S && ((1 << S) != N)) begin : g_ovf_both
            assign is_overflow = (|b[SHIFT_W-1:S]) || (b[S-1:0] >= N[S-1:0]);
        end else if (SHIFT_W > S) begin : g_ovf_upper
            assign is_overflow = |b[SHIFT_W-1:S];
        end else if (SHIFT_W == S && ((1 << S) != N)) begin : g_ovf_non_pow2
            assign is_overflow = (b[S-1:0] >= N[S-1:0]);
        end else begin : g_no_ovf
            assign is_overflow = 1'b0;
        end

        assign out = is_overflow ? {N{1'b0}} : stage[S];
    end

endmodule
