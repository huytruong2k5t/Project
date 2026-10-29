//-----------------------------------------------------------------------------
// File          : fused_prepare_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : W12-F-1 fused datapath, approximate posit(32,3).
// $Source: $ $Revision: 1.0 $ $Log: Week13 RTL implementation. $
//-----------------------------------------------------------------------------
module fused_prepare_comb (
    input  logic [13:0] p_magnitude,
    input  logic signed [10:0] p_scale,
    input  logic p_sign,
    input  logic p_zero,
    input  logic signed [10:0] c_sf,
    input  logic [25:0] c_frac,
    input  logic c_sign,
    input  logic c_zero,
    output wire [30:0] large_seed,
    output wire [30:0] small_seed,
    output wire signed [10:0] anchor,
    output wire [4:0] shift_amount,
    output wire shift_all,
    output wire base_sign,
    output wire subtract
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    localparam int SF_W = 11;

    typedef logic signed [SF_W-1:0] sf_t;
    typedef logic signed [SF_W:0] delta_t;
    wire [30:0] p_seed;
    wire [30:0] c_seed;
    wire signed [SF_W-1:0] p_sf;
    wire signed [SF_W:0] diff_pc;
    wire signed [SF_W:0] diff_cp;
    wire signed [SF_W:0] distance;
    wire choose_p;
    wire both_nonzero;

    // Fixed wiring handles carry without a variable-index normalization mux.
    assign p_seed = p_zero ? 31'b0
                  : p_magnitude[13] ? {1'b0, p_magnitude, 16'b0}
                                    : {1'b0, p_magnitude[12:0], 17'b0};
    assign c_seed = c_zero ? 31'b0 : {1'b0, 1'b1, c_frac, 3'b0};
    assign p_sf = p_scale + sf_t'(p_magnitude[13]);
    assign diff_pc = delta_t'(p_sf) - delta_t'(c_sf);
    assign diff_cp = delta_t'(c_sf) - delta_t'(p_sf);
    assign both_nonzero = !p_zero && !c_zero;
    assign choose_p = !p_zero && (c_zero || !diff_pc[SF_W]);
    assign distance = !both_nonzero ? '0
                    : diff_pc[SF_W] ? diff_cp : diff_pc;
    assign shift_all = distance >= delta_t'(31);
    assign shift_amount = distance[4:0];
    assign large_seed = choose_p ? p_seed : c_seed;
    assign small_seed = choose_p ? c_seed : p_seed;
    assign anchor = (p_zero && c_zero) ? '0 : choose_p ? p_sf : c_sf;
    assign base_sign = choose_p ? p_sign : c_sign;
    assign subtract = p_sign ^ c_sign;
endmodule
// End of fused_prepare_comb.sv
