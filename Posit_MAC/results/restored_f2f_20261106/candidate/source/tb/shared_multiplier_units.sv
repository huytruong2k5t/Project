//-----------------------------------------------------------------------------
// File          : shared_multiplier_units.sv
// Project       : Posit MAC IP
// Description   : Explicit verification-only ports for the five shared leaves.
//-----------------------------------------------------------------------------
module shared_multiplier_units (
    input logic [11:0] op_a,
    input logic [11:0] op_b,
    input logic op_sa,
    input logic op_sb,
    input logic signed [10:0] op_sfa,
    input logic signed [10:0] op_sfb,
    input logic op_mode,
    output wire [11:0] op_x,
    output wire [12:0] op_y,
    output wire op_sign,
    output wire signed [10:0] op_sf,
    input logic [11:0] sac_fx,
    input logic [3:0] sac_scale,
    output wire [11:0] sac_next,
    output wire [3:0] sac_next_scale,
    output wire sac_exhausted,
    output wire sac_error,
    input logic [12:0] shift_y,
    input logic [3:0] shift_scale,
    input logic shift_init,
    output wire [25:0] shift_base,
    output wire [25:0] shift_term,
    input logic acc_first,
    input logic [25:0] acc_base,
    input logic [25:0] acc_term,
    input logic [25:0] acc_previous,
    output wire [25:0] acc_next,
    output wire acc_overflow,
    input logic [25:0] norm_m,
    input logic signed [10:0] norm_sf,
    input logic signed [10:0] norm_sf_inc,
    output wire signed [10:0] norm_out_sf,
    output wire [25:0] norm_fraction
);
    ops_sel_comb u_ops (
        .frac_a(op_a),
        .frac_b(op_b),
        .s_a(op_sa),
        .s_b(op_sb),
        .sf_a(op_sfa),
        .sf_b(op_sfb),
        .cfg_ops(op_mode),
        .x_frac(op_x),
        .y_mant(op_y),
        .sign_o(op_sign),
        .sf_o(op_sf)
    );
    sac_step_comb u_sac (
        .fx(sac_fx),
        .scale(sac_scale),
        .scale_next(sac_next_scale),
        .fx_next(sac_next),
        .exhausted(sac_exhausted),
        .state_error(sac_error)
    );
    sbm_shift_comb u_shift (
        .y_mant(shift_y),
        .scale(shift_scale),
        .init_only(shift_init),
        .y_base(shift_base),
        .term(shift_term)
    );
    sbm_accum_comb u_accum (
        .first(acc_first),
        .y_base(acc_base),
        .term(acc_term),
        .acc(acc_previous),
        .acc_next(acc_next),
        .carry_error(acc_overflow)
    );
    mul_prepack_norm_comb u_norm (
        .acc(norm_m),
        .sf(norm_sf),
        .sf_inc(norm_sf_inc),
        .sf_norm(norm_out_sf),
        .frac_norm(norm_fraction)
    );
endmodule
// End of shared_multiplier_units.sv
