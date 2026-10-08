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

module sac_step_comb #(
    parameter int W_X = 12,
    parameter int S_W = (W_X > 1) ? $clog2(W_X + 1) : 1
)(
    input logic [W_X-1:0] fx,
    input logic [S_W-1:0] scale,
    output logic term_valid,
    output logic [S_W-1:0] sa,
    output logic [S_W-1:0] scale_next,
    output logic [W_X-1:0] fx_next,
    output logic exhausted,
    output logic state_error
);
    localparam int K_W = (W_X > 1) ? $clog2(W_X) : 1;
    localparam logic [S_W:0] MAX_SCALE = W_X;
    localparam logic [S_W-1:0] ONE_STEP = 1;
    wire [K_W-1:0] leading_count;
    wire [S_W-1:0] leading_count_extended;
    wire leading_valid;
    wire [W_X-1:0] shifted;
    logic [S_W-1:0] step_amount;
    logic [S_W:0] scale_sum;

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
            lod_lzd_core #(
                .N(W_X),
                .MODE(0),
                .S(K_W)
            ) u_lod (
                .in(fx),
                .K(leading_count),
                .vld(leading_valid)
            );
        end
    endgenerate

    dyn_left_shifter #(
        .N(W_X),
        .SHIFT_W(S_W)
    ) u_shift (
        .in(fx),
        .b(step_amount),
        .out(shifted)
    );

    always_comb begin
        step_amount = '0;
        if (leading_valid) begin
            step_amount = leading_count_extended + ONE_STEP;
        end
        scale_sum = {1'b0, scale} + {1'b0, step_amount};
        state_error = ({1'b0, scale} > MAX_SCALE) ||
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
            exhausted = (shifted == '0);
        end
    end
endmodule
//-----------------------------------------------------------------------------
// End of sac_step_comb
//-----------------------------------------------------------------------------
