//-----------------------------------------------------------------------------
// File          : dyn_right_shifter.sv
// Author(s)     : Dan Huy
// Email         : 
// Project       : Posit MAC IP (Approximate & Iterative Posit MAC)
// Creation Date : 2026-10-02
//
// Description   : Parameterized Logarithmic Dynamic Right Shifter.
//                 Uses an S-stage multiplexer cascade (S = $clog2(N)).
//                 Logic depth is O(log2 N), hardware-optimized for FPGA LUTs.
//                 Shifting by 2^i is pure wiring (zero logic gates).
//                 Supports:
//                   - Logical right shift (ARITH = 0, fills with 0 by default)
//                   - Arithmetic right shift (ARITH = 1, fills with in[N-1])
//                   - Dynamic fill bit via fill_val port (e.g. ~rc in Posit Packer)
//                 Includes static overflow detection: if shift amount b >= N,
//                 the output is safely clamped to all fill bits ({N{fill}}).
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: $

module dyn_right_shifter #(
    parameter int N       = 32,
    parameter int SHIFT_W = (N > 1) ? $clog2(N) : 1,
    parameter bit ARITH   = 1'b0  // 0: Logical (or custom fill_val), 1: Arithmetic (sign extension)
)(
    input  logic [N-1:0]       in,
    input  logic [SHIFT_W-1:0] b,
    input  logic               fill_val, // Tie to 1'b0 for logical zero fill; ignored when ARITH = 1
    output logic [N-1:0]       out
);

    //-------------------------------------------------------------------------
    // Parameter Validation
    //-------------------------------------------------------------------------
    generate
        if (N < 1) begin : g_param_check_n
            initial $fatal(1, "dyn_right_shifter: Parameter N must be >= 1, got %0d", N);
        end
        if (SHIFT_W < 1) begin : g_param_check_sw
            initial $fatal(1, "dyn_right_shifter: Parameter SHIFT_W must be >= 1, got %0d", SHIFT_W);
        end
    endgenerate

    // Determine the effective fill bit: in[N-1] if ARITH = 1, else fill_val
    logic fill;
    assign fill = ARITH ? in[N-1] : fill_val;

    //-------------------------------------------------------------------------
    // Implementation
    //-------------------------------------------------------------------------
    generate
    if (N == 1) begin : g_single_bit
        assign out = (|b) ? fill : in;
    end else begin : g_multi_bit
        localparam int S = $clog2(N);

        // Stage array: stage[0] is input, stage[S] is output after S MUX stages
        logic [N-1:0] stage [S:0] /* verilator split_var */;
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
                    assign stage[i+1] = sel ? {{SHIFT_VAL{fill}}, stage[i][N - 1 : SHIFT_VAL]}
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

        assign out = is_overflow ? {N{fill}} : stage[S];
    end

    endgenerate
endmodule
