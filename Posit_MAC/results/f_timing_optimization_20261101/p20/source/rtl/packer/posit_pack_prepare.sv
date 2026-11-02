//-----------------------------------------------------------------------------
// File          : posit_pack_prepare.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-06
// Description   : P1 combinational encoding, bounded shift and G/R/S collection.
//                 Input fraction excludes the hidden bit and is MSB aligned.
//                 Refactored & timing-optimized for posit(32,3):
//                   - Direct bit-slice regime extraction sf[7:3] ^ {5{sf[10]}}
//                   - Split constant 25-bit sticky_low & 1-LUT6 thermometer mask
//                   - Direct shifter-to-register feedthrough (no P1 endpoint MUX)
//                   - Deferred NORMAL G/R/S inexact flag merge to P2 finish stage
//-----------------------------------------------------------------------------

module posit_pack_prepare (
    input  logic               sign,
    input  logic               is_zero,
    input  logic               is_nar,
    input  logic signed [10:0] sf,
    input  logic        [52:0] frac,
    input  logic               sticky,
    input  logic        [4:0]  flags_in,
    output logic        [30:0] mag_trunc,
    output logic               guard_bit,
    output logic               round_bit,
    output logic               sticky_bit,
    output logic               sign_o,
    output logic        [2:0]  special_sel,
    output logic        [4:0]  flags_o
);
    // Fixed posit(32,3) parameters
    localparam int NB        = 32;
    localparam int ES        = 3;
    localparam int SF_MAX    = 240; // (NB - 2) * (1 << ES)
    localparam int SHIFT_W   = 5;
    localparam int PAYLOAD_W = 59;  // 2 + ES + 53 + 1

    // Special case encodings for P2 finish stage
    localparam logic [2:0] NORMAL = 3'd0;
    localparam logic [2:0] ZERO   = 3'd1;
    localparam logic [2:0] NAR    = 3'd2;
    localparam logic [2:0] MAXPOS = 3'd3;
    localparam logic [2:0] MINPOS = 3'd4;

    //-------------------------------------------------------------------------
    // 1. Regime & Payload Assembly (Pure Wiring + 1 XOR Level)
    //-------------------------------------------------------------------------
    // k = sf >>> 3. For k >= 0 (sf[10]=0): offset = k[4:0].
    // For k < 0 (sf[10]=1): offset = ~k[4:0] = |k| - 1.
    wire               first_regime_bit = ~sf[10];
    wire [SHIFT_W-1:0] offset           = sf[7:3] ^ {SHIFT_W{sf[10]}};
    wire [PAYLOAD_W-1:0] payload        = {first_regime_bit, ~first_regime_bit, sf[2:0], frac, 1'b0};

    //-------------------------------------------------------------------------
    // 2. Bounded Regime Right Shift (5-Stage MUX Cascade)
    //-------------------------------------------------------------------------
    wire [PAYLOAD_W-1:0] shifted;

    dyn_right_shifter_fixed2 u_payload_shift (
        .in       (payload),
        .b        (offset),
        .fill_val (first_regime_bit),
        .out      (shifted)
    );

    //-------------------------------------------------------------------------
    // 3. Parallel Thermometer-Mask Sticky & Range Classification
    //-------------------------------------------------------------------------
    // frac[24:0] (payload[25:1]) is always in sticky for any offset >= 0.
    // Upper 31 bits {sf[2:0], frac[52:25]} (payload[56:26]) enter sticky iff k < offset.
    // Each sticky_masked[k] has 6 inputs (1 data + 5 offset) -> 1 single LUT6.
    wire        sticky_low   = sticky | (|frac[24:0]);
    wire [30:0] sticky_upper = {sf[2:0], frac[52:25]};
    wire [30:0] sticky_masked;

    genvar k;
    generate
        for (k = 0; k < 31; k = k + 1) begin : g_sticky_mask
            localparam [4:0] IDX = k;
            assign sticky_masked[k] = sticky_upper[k] & (IDX < offset);
        end
    endgenerate

    wire normal_guard  = shifted[PAYLOAD_W - NB];     // shifted[27]
    wire normal_round  = shifted[PAYLOAD_W - NB - 1]; // shifted[26]
    wire normal_sticky = sticky_low | (|sticky_masked);

    // Explicit parallel range/special signals for waveform visibility
    wire nar_eff    = is_nar | flags_in[4];
    wire sf_ge_max  = (sf >= 11'sd240);
    wire sf_gt_max  = (sf >  11'sd240);
    wire sf_lt_min  = (sf < -11'sd240);
    wire maxpos_ovf = sf_gt_max | (|frac) | sticky;

    //-------------------------------------------------------------------------
    // 4. Direct Datapath Feedthrough & Exception Classification
    //-------------------------------------------------------------------------
    // Feed shifted payload and G/R/S directly to P1 FFs without endpoint MUXes;
    // P2 (posit_pack_finish) selects special encodings via special_sel and merges
    // (guard_bit | round_bit | sticky_bit) into flags[1] on the NORMAL path.
    assign sign_o     = sign;
    assign mag_trunc  = shifted[58:28];
    assign guard_bit  = normal_guard;
    assign round_bit  = normal_round;
    assign sticky_bit = normal_sticky;

    always_comb begin
        special_sel = NORMAL;
        flags_o     = {1'b0, flags_in[3:0]};

        // Priority override: NaR -> ZERO -> MAXPOS -> MINPOS
        if (nar_eff) begin
            special_sel = NAR;
            flags_o     = 5'b10000;
        end else if (is_zero) begin
            special_sel = ZERO;
            flags_o     = {1'b0, flags_in[3:0]};
        end else if (sf_ge_max) begin
            special_sel = MAXPOS;
            flags_o     = {1'b0, (flags_in[3] | maxpos_ovf), flags_in[2], (flags_in[1] | maxpos_ovf), flags_in[0]};
        end else if (sf_lt_min) begin
            special_sel = MINPOS;
            flags_o     = {1'b0, flags_in[3], 1'b1, 1'b1, flags_in[0]};
        end
    end

endmodule
//-----------------------------------------------------------------------------
// End of posit_pack_prepare.sv
//-----------------------------------------------------------------------------
