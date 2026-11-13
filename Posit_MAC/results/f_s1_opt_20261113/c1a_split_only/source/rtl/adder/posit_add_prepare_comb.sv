//-----------------------------------------------------------------------------
// File          : posit_add_prepare_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-31
// Description   : Stage S1 of 5-stage Posit(32,3) adder: parallel scale-factor
//                 difference, magnitude comparison, and operand swap (X >= Y).
//-----------------------------------------------------------------------------
module posit_add_prepare_comb (
    input  logic              a_sign,
    input  logic              a_is_zero,
    input  logic              a_is_nar,
    input  logic signed [10:0] a_sf,
    input  logic [25:0]       a_frac,
    input  logic              b_sign,
    input  logic              b_is_zero,
    input  logic              b_is_nar,
    input  logic signed [10:0] b_sf,
    input  logic [25:0]       b_frac,
    input  logic [4:0]        flags_in,
    output logic [25:0]       x_frac,
    output logic [25:0]       y_frac,
    output logic [4:0]        shift_amount,
    output logic              clamped,
    output logic              both_nonzero,
    output logic              subtract,
    output logic              sign_base,
    output logic signed [10:0] sf_base,
    output logic              both_zero,
    output logic              is_nar,
    output logic [3:0]        flags_lo
);
    wire signed [11:0] diff_ab = {a_sf[10], a_sf} - {b_sf[10], b_sf};
    wire signed [11:0] diff_ba = {b_sf[10], b_sf} - {a_sf[10], a_sf};

    wire sf_a_lt_b   = diff_ab[11];
    wire sf_equal    = (a_sf == b_sf);
    wire frac_a_ge_b = (a_frac >= b_frac);

    // Effective non-clamped shift is <= F + 2 = 28; delta >= 29 saturates to jam=1.
    wire clamp_ab = !diff_ab[11] && ((|diff_ab[10:5]) || (diff_ab[4:0] > 5'd28));
    wire clamp_ba = !diff_ba[11] && ((|diff_ba[10:5]) || (diff_ba[4:0] > 5'd28));

    wire choose_a_cond = !a_is_zero
                       && (b_is_zero || (!sf_a_lt_b && (!sf_equal || frac_a_ge_b)));

    (* dont_touch = "true" *) wire choose_a_frac0 = choose_a_cond;
    (* dont_touch = "true" *) wire choose_a_frac1 = choose_a_cond;
    (* dont_touch = "true" *) wire choose_a_frac2 = choose_a_cond;
    (* dont_touch = "true" *) wire choose_a_meta  = choose_a_cond;

    assign both_nonzero       = !a_is_zero && !b_is_zero;
    assign x_frac[8:0]        = choose_a_frac0 ? a_frac[8:0]   : b_frac[8:0];
    assign y_frac[8:0]        = choose_a_frac0 ? b_frac[8:0]   : a_frac[8:0];
    assign x_frac[17:9]       = choose_a_frac1 ? a_frac[17:9]  : b_frac[17:9];
    assign y_frac[17:9]       = choose_a_frac1 ? b_frac[17:9]  : a_frac[17:9];
    assign x_frac[25:18]      = choose_a_frac2 ? a_frac[25:18] : b_frac[25:18];
    assign y_frac[25:18]      = choose_a_frac2 ? b_frac[25:18] : a_frac[25:18];
    assign shift_amount       = sf_a_lt_b ? diff_ba[4:0] : diff_ab[4:0];
    assign clamped            = sf_a_lt_b ? clamp_ba : clamp_ab;
    assign subtract           = both_nonzero && (a_sign != b_sign);
    assign sign_base          = choose_a_meta ? a_sign : b_sign;
    assign sf_base            = choose_a_meta ? a_sf   : b_sf;
    assign both_zero    = a_is_zero && b_is_zero;
    assign is_nar       = a_is_nar || b_is_nar || flags_in[4];
    assign flags_lo     = flags_in[3:0];

endmodule
//-----------------------------------------------------------------------------
// End of posit_add_prepare_comb.sv
//-----------------------------------------------------------------------------

