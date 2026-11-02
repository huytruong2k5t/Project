//-----------------------------------------------------------------------------
// File          : ops_sel_comb_fixed2.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-08
// Description   : Approximate-only 12-bit finite-input OPS, without M0 regs.
//                 Refactored with LUT6-native 2-level popcount:
//                   - Level 1: 6-bit popcount on [5:0] and [11:6] (6 inputs -> 1 LUT6)
//                   - Level 2: 3-bit + 3-bit sum (6 inputs -> 1 LUT6)
//                   - Clean flat signals for waveform debugging
//-----------------------------------------------------------------------------

module ops_sel_comb_fixed2 (
    input  logic        [11:0] frac_a,
    input  logic        [11:0] frac_b,
    input  logic               s_a,
    input  logic               s_b,
    input  logic signed [10:0] sf_a,
    input  logic signed [10:0] sf_b,
    input  logic               cfg_ops, // 0 fixed A, 1 min-popcount
    output logic        [11:0] x_frac,
    output logic        [12:0] y_mant,
    output logic               sign_o,
    output logic signed [10:0] sf_o
);
    // 6-input LUT-native popcount helper (maps 6 bits -> 3-bit count 0..6 in 1 LUT6)
    function automatic logic [2:0] popcount6(input logic [5:0] v);
        popcount6 = {2'b00, v[0]} + {2'b00, v[1]} + {2'b00, v[2]}
                  + {2'b00, v[3]} + {2'b00, v[4]} + {2'b00, v[5]};
    endfunction

    // Level 1: Independent 6-bit half popcounts
    wire [2:0] cnt_a_lo = popcount6(frac_a[5:0]);
    wire [2:0] cnt_a_hi = popcount6(frac_a[11:6]);
    wire [2:0] cnt_b_lo = popcount6(frac_b[5:0]);
    wire [2:0] cnt_b_hi = popcount6(frac_b[11:6]);

    // Level 2: Combine two 3-bit counts (6 inputs total -> 1 LUT6 per bit)
    wire [3:0] count_a = {1'b0, cnt_a_lo} + {1'b0, cnt_a_hi};
    wire [3:0] count_b = {1'b0, cnt_b_lo} + {1'b0, cnt_b_hi};

    wire choose_b = cfg_ops && (count_b < count_a);

    assign x_frac = choose_b ? frac_b : frac_a;
    assign y_mant = {1'b1, (choose_b ? frac_a : frac_b)};
    assign sign_o = s_a ^ s_b;
    assign sf_o   = sf_a + sf_b;

endmodule
//-----------------------------------------------------------------------------
// End of ops_sel_comb_fixed2.sv
//-----------------------------------------------------------------------------
