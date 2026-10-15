//-----------------------------------------------------------------------------
// File          : posit_pack_prepare.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-06
// Description   : P1 combinational encoding, bounded shift and G/R/S collection.
//                 Input fraction excludes the hidden bit and is MSB aligned.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: Initial implementation of SPEC 5.9-D. $

module posit_pack_prepare #(
    parameter int NB = 32,
    parameter int ES = 2,
    parameter int F_IN = 2 * (NB - 3 - ES) + 1,
    parameter int SF_W = $clog2(64'd4 * (longint'(NB) - 64'd2) * (64'd1 << ES) + 64'd4) + 1
)(
    input  logic sign,
    input  logic is_zero,
    input  logic is_nar,
    input  logic signed [SF_W-1:0] sf,
    input  logic [F_IN-1:0] frac,
    input  logic sticky,
    input  logic [4:0] flags_in,
    output logic [NB-2:0] mag_trunc,
    output logic guard_bit,
    output logic round_bit,
    output logic sticky_bit,
    output logic sign_o,
    output logic [2:0] special_sel,
    output logic [4:0] flags_o
);
    localparam int SF_MAX = int'((longint'(NB) - 64'd2) * (64'd1 << ES));
    localparam int SHIFT_W = $clog2(NB - 1);
    localparam int PAYLOAD_W = 2 + ES + F_IN + 1;
    localparam logic [2:0] NORMAL = 3'd0;
    localparam logic [2:0] ZERO = 3'd1;
    localparam logic [2:0] NAR = 3'd2;
    localparam logic [2:0] MAXPOS = 3'd3;
    localparam logic [2:0] MINPOS = 3'd4;

    typedef logic [SHIFT_W-1:0] offset_value_t;
    wire [SHIFT_W-1:0] regime;
    wire first_regime_bit;
    wire [SHIFT_W-1:0] offset;
    wire [PAYLOAD_W-1:0] payload;
    wire [PAYLOAD_W-1:0] shifted;
    wire [PAYLOAD_W-1:0] lost_mask;
    wire lost_sticky;

    generate
        if (NB < 4 || NB > 32 || ES < 0 || ES > NB - 4 ||
            F_IN < NB - 3 - ES + 2 || F_IN > 63 ||
            SF_W < $clog2(64'd4 * SF_MAX + 64'd4) + 1) begin : g_invalid
            initial $fatal(1, "posit_pack_prepare: unsupported parameters");
        end
    endgenerate

    // Paper Fig.5(b): k>=0 gives m=k; k<0 gives m=~k=|k|-1.
    // Pre-clamping guarantees that the normal path uses offset <= NB-3.
    assign regime = offset_value_t'($signed(sf) >>> ES);
    assign first_regime_bit = !sf[SF_W-1];
    assign offset = regime[SHIFT_W-1:0]
                  ^ {SHIFT_W{sf[SF_W-1]}};

    generate
        if (ES == 0) begin : g_es_zero
            assign payload = {first_regime_bit, !first_regime_bit, frac, 1'b0};
        end else begin : g_es_nonzero
            assign payload = {first_regime_bit, !first_regime_bit,
                              sf[ES-1:0], frac, 1'b0};
        end
    endgenerate

    dyn_right_shifter #(
        .N (PAYLOAD_W),
        .SHIFT_W (SHIFT_W),
        .ARITH (1'b0)
    ) u_payload_shift (
        .in (payload),
        .b (offset),
        .fill_val (first_regime_bit),
        .out (shifted)
    );

    // This mask collects original bits discarded by the right shift.
    // It does not include the regime fill bits introduced above the payload.
    assign lost_mask = ~({PAYLOAD_W{1'b1}} << offset);
    assign lost_sticky = |(payload & lost_mask);

    always_comb begin
        mag_trunc = shifted[PAYLOAD_W-1 -: NB-1];
        guard_bit = shifted[PAYLOAD_W-NB];
        round_bit = shifted[PAYLOAD_W-NB-1];
        sticky_bit = sticky
                   | lost_sticky
                   | (|shifted[PAYLOAD_W-NB-2:0]);
        sign_o = sign;
        special_sel = NORMAL;
        flags_o = {1'b0, flags_in[3:0]};
        flags_o[1] = flags_in[1]
                   | guard_bit
                   | round_bit
                   | sticky_bit;

        if (is_nar || flags_in[4]) begin
            special_sel = NAR;
            flags_o = 5'b10000;
            mag_trunc = '0;
            guard_bit = 1'b0;
            round_bit = 1'b0;
            sticky_bit = 1'b0;
        end else if (is_zero) begin
            special_sel = ZERO;
            mag_trunc = '0;
            guard_bit = 1'b0;
            round_bit = 1'b0;
            sticky_bit = 1'b0;
            flags_o = {1'b0, flags_in[3:0]};
        end else if (int'($signed(sf)) >= SF_MAX) begin
            special_sel = MAXPOS;
            mag_trunc = {NB-1{1'b1}};
            guard_bit = 1'b0;
            round_bit = 1'b0;
            sticky_bit = 1'b0;
            flags_o = {1'b0, flags_in[3:0]};
            if (int'($signed(sf)) > SF_MAX || (|frac) || sticky) begin
                flags_o[3] = 1'b1;
                flags_o[1] = 1'b1;
            end
        end else if (int'($signed(sf)) < -SF_MAX) begin
            special_sel = MINPOS;
            mag_trunc = {{NB-2{1'b0}}, 1'b1};
            guard_bit = 1'b0;
            round_bit = 1'b0;
            sticky_bit = 1'b0;
            flags_o = {1'b0, flags_in[3:0]};
            flags_o[2] = 1'b1;
            flags_o[1] = 1'b1;
        end
    end
endmodule
//----------------------------------------------------------------------------- 
// End of posit_pack_prepare.sv
//-----------------------------------------------------------------------------
