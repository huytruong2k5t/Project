//-----------------------------------------------------------------------------
// File          : posit_add_align.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-12
// Description   : Select magnitude and align/jam exact normalized operands.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: W10 implementation, SPEC 5.8-A..D. $

module posit_add_align_before #(
    parameter int NB = 32,
    parameter int ES = 2,
    parameter int F = NB - 3 - ES,
    parameter int SF_W = $clog2(64'd4 * (longint'(NB) - 64'd2) * (64'd1 << ES) + 64'd4) + 1
)(
    input logic a_sign,
    input logic a_is_zero,
    input logic a_is_nar,
    input logic signed [SF_W-1:0] a_sf,
    input logic [F-1:0] a_frac,
    input logic b_sign,
    input logic b_is_zero,
    input logic b_is_nar,
    input logic signed [SF_W-1:0] b_sf,
    input logic [F-1:0] b_frac,
    input logic [4:0] flags_in,
    output logic [F+4:0] x,
    output logic [F+4:0] y,
    output logic subtract,
    output logic sign_base,
    output logic signed [SF_W-1:0] sf_base,
    output logic alignment_tail,
    output logic is_zero,
    output logic is_nar,
    output logic [4:0] flags_o
);
    localparam int ADD_W = F + 5;
    localparam int SHIFT_W = $clog2(ADD_W);
    typedef logic [ADD_W-1:0] word_t;
    typedef logic signed [SF_W:0] delta_t;
    typedef logic [SHIFT_W-1:0] shift_t;
    logic choose_a;
    logic both_finite;
    logic [ADD_W-1:0] x_seed;
    logic [ADD_W-1:0] y_seed;
    logic signed [SF_W-1:0] sf_small;
    logic signed [SF_W-1:0] sf_selected;
    delta_t delta_sf;
    logic [SHIFT_W-1:0] shift_amount;
    logic clamped;
    logic [ADD_W-1:0] shifted_y;
    logic [ADD_W-1:0] lost_mask;
    logic lost_tail;
    wire fill_val = 1'b0;

    generate
        if (F != NB - 3 - ES || F < 2 || NB > 32 || NB < 4 || ES < 0
            || SF_W < $clog2(64'd4 * (longint'(NB) - 64'd2) * (64'd1 << ES) + 64'd4) + 1) begin : g_invalid
            initial $fatal(1, "posit_add_align: unsupported parameters");
        end
    endgenerate

    always_comb begin
        choose_a = !a_is_zero
                 && (b_is_zero || a_sf > b_sf
                 || (a_sf == b_sf && a_frac >= b_frac));
        both_finite = !a_is_zero && !b_is_zero;
        x_seed = choose_a ? {1'b0, 1'b1, a_frac, 3'b000}
                          : {1'b0, 1'b1, b_frac, 3'b000};
        y_seed = choose_a ? {1'b0, 1'b1, b_frac, 3'b000}
                          : {1'b0, 1'b1, a_frac, 3'b000};
        sf_selected = choose_a ? a_sf : b_sf;
        sf_small = choose_a ? b_sf : a_sf;
        delta_sf = both_finite ? delta_t'(sf_selected) - delta_t'(sf_small) : '0;
        clamped = delta_sf > delta_t'(F + 2);
        shift_amount = clamped ? shift_t'(F + 2) : shift_t'(delta_sf);
        lost_mask = shift_amount == '0 ? '0
                  : (word_t'(1) << shift_amount) - word_t'(1);
        lost_tail = |(y_seed & lost_mask);
    end

    dyn_right_shifter #(
        .N (ADD_W),
        .SHIFT_W (SHIFT_W),
        .ARITH (1'b0)
    ) u_align_shift (
        .in (y_seed),
        .b (shift_amount),
        .fill_val (fill_val),
        .out (shifted_y)
    );

    always_comb begin
        x = x_seed;
        sf_base = sf_selected;
        y = '0;
        subtract = both_finite && (a_sign != b_sign);
        sign_base = choose_a ? a_sign : b_sign;
        alignment_tail = 1'b0;
        is_zero = a_is_zero && b_is_zero;
        is_nar = a_is_nar || b_is_nar || flags_in[4];
        flags_o = {1'b0, flags_in[3:0]};
        if (both_finite) begin
            alignment_tail = clamped || lost_tail;
            y = clamped ? word_t'(1) : shifted_y | word_t'(lost_tail);
        end
        if (is_nar) begin
            x = '0;
            sf_base = '0;
            y = '0;
            subtract = 1'b0;
            sign_base = 1'b1;
            alignment_tail = 1'b0;
            is_zero = 1'b0;
            flags_o = 5'b10000;
        end else if (is_zero) begin
            x = '0;
            sf_base = '0;
            y = '0;
            subtract = 1'b0;
            sign_base = 1'b0;
            alignment_tail = 1'b0;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// End of posit_add_align.sv
//-----------------------------------------------------------------------------
