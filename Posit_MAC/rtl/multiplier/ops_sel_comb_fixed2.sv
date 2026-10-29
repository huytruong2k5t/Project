//-----------------------------------------------------------------------------
// File          : ops_sel_comb_fixed2.sv
// Author(s)     : Dan Huy
// Email         :
// Project       : Posit MAC IP
// Creation Date : 2026-10-08
// Description   : Approximate-only 12-bit finite-input OPS, without M0 regs.
//                 Counts ones on the 12 retained MSBs of frac_a and frac_b,
//                 swaps X/Y when cfg_ops == 1 and popcount(B) < popcount(A),
//                 and prepends the hidden '1' bit to Y.
//-----------------------------------------------------------------------------

module ops_sel_comb_fixed2 (
    input logic [25:0] frac_a,
    input logic [25:0] frac_b,
    input logic s_a,
    input logic s_b,
    input logic signed [10:0] sf_a,
    input logic signed [10:0] sf_b,
    input logic [1:0] cfg_ops,                // 0 fixed A, 1 min-popcount
    output logic [11:0] x_frac,
    output logic [12:0] y_mant,
    output logic sign_o,
    output logic signed [10:0] sf_o,
    output logic input_cut
);
    // Fixed posit32/ES3 approximate-12 elaboration; no public parameters.
    localparam int FRAC_MAX = 26;
    localparam int FRAC_W   = 12;
    localparam int CUT_W    = FRAC_MAX - FRAC_W; // 14 discarded LSBs
    localparam int COUNT_W  = 4;                 // popcount range 0..12
    localparam int PAD_N    = 16;                // next power of two >= 12

    wire [FRAC_W-1:0] pop_a;
    wire [FRAC_W-1:0] pop_b;
    wire choose_b;
    wire [COUNT_W-1:0] count_a [2*PAD_N-1:1] /* verilator split_var */;
    wire [COUNT_W-1:0] count_b [2*PAD_N-1:1] /* verilator split_var */;

    assign pop_a = frac_a[FRAC_MAX-1 -: FRAC_W];
    assign pop_b = frac_b[FRAC_MAX-1 -: FRAC_W];

    genvar bit_index;
    genvar node;
    generate
        for (bit_index = 0; bit_index < PAD_N; bit_index++) begin : g_count_leaves
            if (bit_index < FRAC_W) begin : g_used
                assign count_a[PAD_N + bit_index] = {{(COUNT_W-1){1'b0}}, pop_a[bit_index]};
                assign count_b[PAD_N + bit_index] = {{(COUNT_W-1){1'b0}}, pop_b[bit_index]};
            end else begin : g_padding
                assign count_a[PAD_N + bit_index] = '0;
                assign count_b[PAD_N + bit_index] = '0;
            end
        end
        for (node = 1; node < PAD_N; node++) begin : g_count_tree
            assign count_a[node] = count_a[2*node] + count_a[2*node + 1];
            assign count_b[node] = count_b[2*node] + count_b[2*node + 1];
        end
    endgenerate

    assign choose_b  = (cfg_ops == 2'd1) && (count_b[1] < count_a[1]);
    assign x_frac    = choose_b ? pop_b : pop_a;
    assign y_mant    = {1'b1, (choose_b ? pop_a : pop_b)};
    assign sign_o    = s_a ^ s_b;
    assign sf_o      = sf_a + sf_b;
    assign input_cut = |(frac_a[CUT_W-1:0] | frac_b[CUT_W-1:0]);
endmodule
//-----------------------------------------------------------------------------
// End of ops_sel_comb_fixed2
//-----------------------------------------------------------------------------
