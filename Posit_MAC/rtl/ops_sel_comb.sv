//-----------------------------------------------------------------------------
// File          : ops_sel_comb.sv
// Author(s)     : Dan Huy
// Email         :
// Project       : Posit MAC IP
// Creation Date : 2026-10-08
// Description   : SPEC 5.4 finite-input OPS, without M0 registers.
//                 Exact uses full fraction; approx cuts before popcount.
//                 Outputs are right-aligned Q(active_width), without hidden X.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: 2026-10-08: week9 normative combinational contract. $

module ops_sel_comb #(
    parameter int FRAC_MAX = 27,
    parameter int FRAC_W = 12,
    parameter int SF_W = 11,
    parameter bit EXACT_EN = 1'b1,
    parameter bit OPS_EN = 1'b1,
    parameter int WIDTH_W = (FRAC_MAX > 1) ? $clog2(FRAC_MAX + 1) : 1
)(
    input logic [FRAC_MAX-1:0] frac_a,
    input logic [FRAC_MAX-1:0] frac_b,
    input logic s_a,
    input logic s_b,
    input logic signed [SF_W-1:0] sf_a,
    input logic signed [SF_W-1:0] sf_b,
    input logic cfg_mode,                    // 0 exact, 1 approximate
    input logic [1:0] cfg_ops,                // 0 fixed A, 1 min-popcount
    output logic [FRAC_MAX-1:0] x_frac,
    output logic [FRAC_MAX:0] y_mant,
    output logic [WIDTH_W-1:0] active_width,
    output logic sign_o,
    output logic signed [SF_W-1:0] sf_o,
    output logic swapped,
    output logic input_cut,
    output logic cfg_error
);
    localparam int COUNT_W = WIDTH_W;
    localparam int PAD_N = 1 << ((FRAC_MAX > 1) ? $clog2(FRAC_MAX) : 0);

    logic [FRAC_MAX-1:0] effective_a;
    logic [FRAC_MAX-1:0] effective_b;
    logic discarded;
    wire choose_b;
    wire [COUNT_W-1:0] count_a [2*PAD_N-1:1];
    wire [COUNT_W-1:0] count_b [2*PAD_N-1:1];

    genvar bit_index;
    genvar node;
    generate
        if (FRAC_MAX < 1 || FRAC_MAX > 27 || FRAC_W < 1 || FRAC_W > FRAC_MAX) begin : g_bad_width
            initial $fatal(1, "ops_sel_comb: invalid fraction width");
        end
        if (SF_W < 2 || WIDTH_W < $clog2(FRAC_MAX + 1)) begin : g_bad_control_width
            initial $fatal(1, "ops_sel_comb: invalid control width");
        end
        for (bit_index = 0; bit_index < PAD_N; bit_index++) begin : g_count_leaves
            if (bit_index < FRAC_MAX) begin : g_used
                if (COUNT_W == 1) begin : g_one_bit_count
                    assign count_a[PAD_N + bit_index] = effective_a[bit_index];
                    assign count_b[PAD_N + bit_index] = effective_b[bit_index];
                end else begin : g_extend_count
                    assign count_a[PAD_N + bit_index] = {{(COUNT_W-1){1'b0}}, effective_a[bit_index]};
                    assign count_b[PAD_N + bit_index] = {{(COUNT_W-1){1'b0}}, effective_b[bit_index]};
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

    always_comb begin
        effective_a = frac_a;
        effective_b = frac_b;
        discarded = 1'b0;

        if (cfg_mode) begin
            effective_a = '0;
            effective_b = '0;
            effective_a[FRAC_W-1:0] = frac_a[FRAC_MAX-1 -: FRAC_W];
            effective_b[FRAC_W-1:0] = frac_b[FRAC_MAX-1 -: FRAC_W];
            for (int bit_index = 0; bit_index < FRAC_MAX-FRAC_W; bit_index++) begin
                discarded = discarded | frac_a[bit_index] | frac_b[bit_index];
            end
        end
    end

    assign choose_b = OPS_EN && (cfg_ops == 2'd1) && (count_b[1] < count_a[1]);

    always_comb begin
        cfg_error = (cfg_ops > 2'd1) || (!OPS_EN && (cfg_ops != 2'd0)) ||
                    (!EXACT_EN && !cfg_mode);
        x_frac = '0;
        y_mant = '0;
        active_width = '0;
        sign_o = 1'b0;
        sf_o = '0;
        swapped = 1'b0;
        input_cut = 1'b0;

        if (!cfg_error) begin
            x_frac = choose_b ? effective_b : effective_a;
            y_mant[FRAC_MAX-1:0] = choose_b ? effective_a : effective_b;
            if (cfg_mode) begin
                y_mant[FRAC_W] = 1'b1;
                active_width = FRAC_W[WIDTH_W-1:0];
            end else begin
                y_mant[FRAC_MAX] = 1'b1;
                active_width = FRAC_MAX[WIDTH_W-1:0];
            end
            sign_o = s_a ^ s_b;
            sf_o = sf_a + sf_b;
            swapped = choose_b;
            input_cut = discarded;
        end
    end
endmodule
//-----------------------------------------------------------------------------
// End of ops_sel_comb
//-----------------------------------------------------------------------------
