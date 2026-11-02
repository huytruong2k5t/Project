//-----------------------------------------------------------------------------
// File          : sac_step_comb_fixed2.sv
// Author(s)     : Dan Huy
// Email         :
// Project       : Posit MAC IP
// Creation Date : 2026-10-08
// Description   : SPEC 5.5 one fraction step, with no state or hidden token.
//                 sa=clz(fx)+1; scale_next=scale+sa; fx_next=fx<<sa.
//                 The controller owns first/last/init_only and iteration count.
//-----------------------------------------------------------------------------

module sac_step_comb_fixed2 (
    input logic [11:0] fx,
    input logic [4:0] scale,
    output logic [4:0] scale_next,
    output logic [11:0] fx_next,
    output logic exhausted,
    output logic state_error
);
    // Fixed posit32/ES3 approximate-12 elaboration; no public parameters.
    localparam int W_X = 12;

    wire [3:0] leading_count;
    wire leading_valid;
    wire [11:0] pre_shifted;
    wire [11:0] shifted;

    // 1. Detect position of first '1' bit
    lod_lzd_core_fixed4 u_lod (
        .in  (fx),
        .K   (leading_count),
        .vld (leading_valid)
    );

    // 2. Prepare next fraction by dropping the leading '1' and shifting left
    assign pre_shifted = {fx[10:0], 1'b0};

    dyn_left_shifter_fixed5 u_shift (
        .in  (pre_shifted),
        .b   (leading_count),
        .out (shifted)
    );

    // 3. Cumulative scale calculation via direct carry-in addition
    wire [5:0] scale_sum = {1'b0, scale} + {2'b0, leading_count} + 6'd1;

    // Range checks: scale cannot exceed fraction width (12)
    wire scale_out_of_range = (scale > 5'd12);
    wire sum_out_of_range   = leading_valid && (scale_sum > 6'd12);

    // 4. Exhaustion check: true if fx has at most one bit '1' remaining (self-contained, parallel)
    wire single_one = ((fx & (fx - 1'b1)) == 12'd0);

    // 5. Outputs
    assign state_error = scale_out_of_range || sum_out_of_range;
    assign scale_next  = leading_valid ? scale_sum[4:0] : scale;
    assign fx_next     = leading_valid ? shifted : fx;
    assign exhausted   = single_one;

endmodule
//-----------------------------------------------------------------------------
// End of sac_step_comb_fixed2
//-----------------------------------------------------------------------------
