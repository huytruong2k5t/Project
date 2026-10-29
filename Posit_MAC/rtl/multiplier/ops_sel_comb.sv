//-----------------------------------------------------------------------------
// File          : ops_sel_comb.sv
// Author(s)     : Dan Huy
// Email         :
// Project       : Posit MAC IP
// Creation Date : 2026-10-08
// Description   : SPEC 5.4 finite-input OPS, without M0 registers.
//                 Parallel masked popcount and prepared data candidates.
//                 Exact uses full fraction; approx counts the high FRAC_W bits.
//                 Outputs are right-aligned Q(active_width), without hidden X.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.1 $
// $Log: 2026-10-14: mask low count bits; prepare hidden before final swap. $

module ops_sel_comb (
    input logic [25:0] frac_a,
    input logic [25:0] frac_b,
    input logic s_a,
    input logic s_b,
    input logic signed [10:0] sf_a,
    input logic signed [10:0] sf_b,
    input logic cfg_mode,                    // 0 exact, 1 approximate
    input logic [1:0] cfg_ops,                // 0 fixed A, 1 min-popcount
    output logic [25:0] x_frac,
    output logic [26:0] y_mant,
    output logic [4:0] active_width,
    output logic sign_o,
    output logic signed [10:0] sf_o,
    output logic swapped,
    output logic input_cut,
    output logic cfg_error
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    localparam int FRAC_MAX = 26;
    localparam int FRAC_W = 12;
    localparam int SF_W = 11;
    localparam bit EXACT_EN = 1'h1;
    localparam bit OPS_EN = 1'h1;
    localparam int WIDTH_W = 5;

    localparam int COUNT_W = 5; // WIDTH_W
    localparam int PAD_N = 32; // 1 << ((FRAC_MAX > 1) ? $clog2(FRAC_MAX) : 0)

    localparam int CUT_W = 14; // FRAC_MAX - FRAC_W

    wire [FRAC_MAX-1:0] pop_a;
    wire [FRAC_MAX-1:0] pop_b;
    wire discarded;
    logic [FRAC_MAX-1:0] candidate_x_a;
    logic [FRAC_MAX-1:0] candidate_x_b;
    logic [FRAC_MAX:0] candidate_y_a;
    logic [FRAC_MAX:0] candidate_y_b;
    wire choose_b;
    wire [COUNT_W-1:0] count_a [2*PAD_N-1:1] /* verilator split_var */;
    wire [COUNT_W-1:0] count_b [2*PAD_N-1:1] /* verilator split_var */;

    genvar bit_index;
    genvar node;
    generate
        if (FRAC_MAX < 1 || FRAC_MAX > 27 || FRAC_W < 1 || FRAC_W > FRAC_MAX) begin : g_bad_width
            initial $fatal(1, "ops_sel_comb: invalid fraction width");
        end
        if (SF_W < 2 || WIDTH_W < $clog2(FRAC_MAX + 1)) begin : g_bad_control_width
            initial $fatal(1, "ops_sel_comb: invalid control width");
        end

        // Counting is invariant to bit position. Keep the prefix in place;
        // exact includes the low bits, approximate masks them with one AND.
        for (bit_index = 0; bit_index < FRAC_MAX; bit_index++) begin : g_count_mask
            if (bit_index < CUT_W) begin : g_low
                assign pop_a[bit_index] = frac_a[bit_index] & !cfg_mode;
                assign pop_b[bit_index] = frac_b[bit_index] & !cfg_mode;
            end else begin : g_high
                assign pop_a[bit_index] = frac_a[bit_index];
                assign pop_b[bit_index] = frac_b[bit_index];
            end
        end

        // Do not elaborate a negative slice when approximate keeps every bit.
        if (FRAC_W < FRAC_MAX) begin : g_cut_bits
            assign discarded = cfg_mode
                             & (|(frac_a[CUT_W-1:0] | frac_b[CUT_W-1:0]));
        end else begin : g_no_cut
            assign discarded = 1'b0;
        end

        for (bit_index = 0; bit_index < PAD_N; bit_index++) begin : g_count_leaves
            if (bit_index < FRAC_MAX) begin : g_used
                if (COUNT_W == 1) begin : g_one_bit_count
                    assign count_a[PAD_N + bit_index] = pop_a[bit_index];
                    assign count_b[PAD_N + bit_index] = pop_b[bit_index];
                end else begin : g_extend_count
                    assign count_a[PAD_N + bit_index] = {{(COUNT_W-1){1'b0}}, pop_a[bit_index]};
                    assign count_b[PAD_N + bit_index] = {{(COUNT_W-1){1'b0}}, pop_b[bit_index]};
                end
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

    assign choose_b = OPS_EN && (cfg_ops == 2'd1) && (count_b[1] < count_a[1]);
    assign cfg_error = (cfg_ops > 2'd1)
                     || (!OPS_EN && (cfg_ops != 2'd0))
                     || (!EXACT_EN && !cfg_mode);

    // This branch does not depend on choose_b. Alignment, hidden insertion
    // and invalid-config clearing are complete before the final swap MUXes.
    always_comb begin
        candidate_x_a = '0;
        candidate_x_b = '0;
        candidate_y_a = '0;
        candidate_y_b = '0;
        active_width = '0;
        sign_o = 1'b0;
        sf_o = '0;
        input_cut = 1'b0;

        if (!cfg_error) begin
            if (cfg_mode) begin
                candidate_x_a[FRAC_W-1:0] = frac_a[FRAC_MAX-1 -: FRAC_W];
                candidate_x_b[FRAC_W-1:0] = frac_b[FRAC_MAX-1 -: FRAC_W];
                candidate_y_a[FRAC_W:0] = {1'b1, frac_a[FRAC_MAX-1 -: FRAC_W]};
                candidate_y_b[FRAC_W:0] = {1'b1, frac_b[FRAC_MAX-1 -: FRAC_W]};
                active_width = FRAC_W[WIDTH_W-1:0];
            end else begin
                candidate_x_a = frac_a;
                candidate_x_b = frac_b;
                candidate_y_a = {1'b1, frac_a};
                candidate_y_b = {1'b1, frac_b};
                active_width = FRAC_MAX[WIDTH_W-1:0];
            end
            sign_o = s_a ^ s_b;
            sf_o = sf_a + sf_b;
            input_cut = discarded;
        end
    end

    // Selection metadata is separate from candidate preparation as well.
    always_comb begin
        swapped = 1'b0;
        if (!cfg_error) begin
            swapped = choose_b;
        end
    end

    // One parallel swap stage; X has no hidden bit, Y already has its hidden.
    assign x_frac = choose_b ? candidate_x_b : candidate_x_a;
    assign y_mant = choose_b ? candidate_y_a : candidate_y_b;
endmodule
//-----------------------------------------------------------------------------
// End of ops_sel_comb
//-----------------------------------------------------------------------------
