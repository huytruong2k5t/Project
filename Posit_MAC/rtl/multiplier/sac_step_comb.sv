//-----------------------------------------------------------------------------
// File          : sac_step_comb.sv
// Author(s)     : Dan Huy
// Email         :
// Project       : Posit MAC IP
// Creation Date : 2026-10-08
// Description   : SPEC 5.5 one fraction step, with no state or hidden token.
//                 sa=clz(fx)+1; scale_next=scale+sa; fx_next=fx<<sa.
//                 The controller owns first/last/init_only and iteration count.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: 2026-10-08: width-safe normative SAC combinational step. $

module sac_step_comb (
    input logic [25:0] fx,
    input logic [4:0] scale,
    output logic term_valid,
    output logic [4:0] sa,
    output logic [4:0] scale_next,
    output logic [25:0] fx_next,
    output logic exhausted,
    output logic state_error
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    // W_X: 12 (original).
    localparam int W_X = 26;
    // S_W: (W_X > 1) ? $clog2(W_X + 1) : 1 (original).
    localparam int S_W = 5;

    typedef logic [S_W:0] scale_limit_t;
    localparam int K_W = 5; // (W_X > 1) ? $clog2(W_X) : 1
    localparam logic [S_W:0] MAX_SCALE = scale_limit_t'(W_X);
    localparam logic [S_W-1:0] ONE_STEP = 1;
    wire [K_W-1:0] leading_count;
    wire [S_W-1:0] leading_count_extended;
    wire leading_valid;
    wire [W_X-1:0] shifted;
    wire [W_X-1:0] pre_shifted;
    logic [S_W-1:0] step_amount;
    logic [S_W:0] scale_sum;
    wire scale_out_of_range;
    wire single_one;

    generate
        if (S_W == K_W) begin : g_count_same_width
            assign leading_count_extended = leading_count;
        end else begin : g_count_extend
            assign leading_count_extended = {{(S_W-K_W){1'b0}}, leading_count};
        end
        if (W_X < 1 || W_X > 27 || S_W < $clog2(W_X + 1)) begin : g_bad_width
            initial $fatal(1, "sac_step_comb: invalid width");
        end
        if (W_X == 1) begin : g_single_bit
            assign leading_count = '0;
            assign leading_valid = fx[0];
        end else begin : g_detector
            lod_lzd_core_fixed3  u_lod (
                .in(fx),
                .K(leading_count),
                .vld(leading_valid)
            );
        end
    endgenerate

    // Remove the leading one with wiring before the variable shift.
    // LOD still observes the original fraction, not pre_shifted.
    generate
        if (W_X == 1) begin : g_pre_shift_single
            assign pre_shifted = '0;
        end else begin : g_pre_shift
            assign pre_shifted = {fx[W_X-2:0], 1'b0};
        end
    endgenerate

    localparam int ONE_LEVELS = 5; // $clog2(W_X)
    localparam int ONE_PAD = 32; // 1 << ONE_LEVELS
    wire [ONE_PAD-1:0] zero_tree [ONE_LEVELS:0] /* verilator split_var */;
    wire [ONE_PAD-1:0] one_tree [ONE_LEVELS:0] /* verilator split_var */;
    generate
        for (genvar j = 0; j < ONE_PAD; j++) begin : g_one_leaves
            if (j < W_X) begin : g_used
                assign zero_tree[0][j] = !fx[j];
                assign one_tree[0][j] = fx[j];
            end else begin : g_padding
                assign zero_tree[0][j] = 1'b1;
                assign one_tree[0][j] = 1'b0;
            end
        end
        for (genvar l = 0; l < ONE_LEVELS; l++) begin : g_one_levels
            for (genvar j = 0; j < (ONE_PAD >> (l + 1)); j++) begin : g_nodes
                assign zero_tree[l+1][j] = zero_tree[l][2*j]
                                        & zero_tree[l][2*j+1];
                assign one_tree[l+1][j] = (one_tree[l][2*j] & zero_tree[l][2*j+1])
                                       | (zero_tree[l][2*j] & one_tree[l][2*j+1]);
            end
        end
    endgenerate
    assign single_one = zero_tree[ONE_LEVELS][0] | one_tree[ONE_LEVELS][0];

    generate
        if ({1'b0, {S_W{1'b1}}} > MAX_SCALE) begin : g_scale_range
            assign scale_out_of_range = ({1'b0, scale} > MAX_SCALE);
        end else begin : g_scale_always_in_range
            assign scale_out_of_range = 1'b0;
        end
    endgenerate

    dyn_left_shifter_fixed3  u_shift (
        .in(pre_shifted),
        .b(leading_count_extended),
        .out(shifted)
    );

    assign step_amount = leading_valid ? leading_count_extended + ONE_STEP : '0;

    always_comb begin
        scale_sum = {1'b0, scale}
                  + {1'b0, leading_count_extended}
                  + scale_limit_t'(1);
        state_error = scale_out_of_range ||
                      (leading_valid && (scale_sum > MAX_SCALE));
        term_valid = leading_valid && !state_error;
        sa = '0;
        scale_next = scale;
        fx_next = fx;
        exhausted = !leading_valid;

        if (term_valid) begin
            sa = step_amount;
            scale_next = scale_sum[S_W-1:0];
            fx_next = shifted;
            exhausted = single_one;
        end
    end
endmodule
//-----------------------------------------------------------------------------
// End of sac_step_comb
//-----------------------------------------------------------------------------
