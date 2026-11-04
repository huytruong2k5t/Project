// Reference only: moved intact from tb_posit_pack_equiv.sv.
module ref_posit_pack_comb (
    input  logic               sign,
    input  logic               is_zero,
    input  logic               is_nar,
    input  logic signed [10:0] sf,
    input  logic        [52:0] frac,
    input  logic               sticky,
    input  logic        [4:0]  flags_in,
    input  logic               product_mode,
    output logic        [31:0] d,
    output logic        [4:0]  flags,
    output logic               sign_o
);
    localparam int NB = 32;
    localparam int ES = 3;
    localparam int SF_MAX = 240;
    localparam int SHIFT_W = 5;
    localparam int PAYLOAD_W = 59;
    localparam int LOW_W = 26;
    localparam int OFFSETS = 32;
    localparam logic [2:0] NORMAL = 3'd0;
    localparam logic [2:0] ZERO   = 3'd1;
    localparam logic [2:0] NAR    = 3'd2;
    localparam logic [2:0] MAXPOS = 3'd3;
    localparam logic [2:0] MINPOS = 3'd4;

    typedef logic [SHIFT_W-1:0] offset_value_t;
    wire [SHIFT_W-1:0] regime = offset_value_t'($signed(sf) >>> ES);
    wire first_regime_bit = !sf[10];
    wire [SHIFT_W-1:0] offset = regime[SHIFT_W-1:0] ^ {SHIFT_W{sf[10]}};
    wire [PAYLOAD_W-1:0] payload = {first_regime_bit, !first_regime_bit, sf[2:0], frac, 1'b0};

    logic [PAYLOAD_W-1:0] shifted;
    always_comb begin
        shifted = payload >> offset;
        for (int k = 0; k < PAYLOAD_W; k++) begin
            if (k >= (PAYLOAD_W - int'(offset)))
                shifted[k] = first_regime_bit;
        end
    end

    logic [OFFSETS-1:0] sticky_lookup;
    always_comb begin
        for (int j = 0; j < OFFSETS; j++) begin
            logic s_acc;
            s_acc = 1'b0;
            for (int b = 0; b < LOW_W + j; b++) begin
                s_acc |= payload[b];
            end
            sticky_lookup[j] = s_acc;
        end
    end

    logic [30:0] mag_trunc;
    logic guard_bit, round_bit, sticky_bit;
    logic [2:0] special_sel;
    logic [4:0] flags_p1;

    always_comb begin
        mag_trunc   = shifted[PAYLOAD_W-1 -: NB-1];
        guard_bit   = shifted[PAYLOAD_W-NB];
        round_bit   = shifted[PAYLOAD_W-NB-1];
        sticky_bit  = sticky | sticky_lookup[offset];
        sign_o      = sign;
        special_sel = NORMAL;
        flags_p1    = {1'b0, flags_in[3:0]};
        flags_p1[1] = flags_in[1] | guard_bit | round_bit | sticky_bit;

        if (is_nar || flags_in[4]) begin
            special_sel = NAR;
            flags_p1    = 5'b10000;
            mag_trunc   = '0;
            guard_bit   = 1'b0;
            round_bit   = 1'b0;
            sticky_bit  = 1'b0;
        end else if (is_zero) begin
            special_sel = ZERO;
            mag_trunc   = '0;
            guard_bit   = 1'b0;
            round_bit   = 1'b0;
            sticky_bit  = 1'b0;
            flags_p1    = {1'b0, flags_in[3:0]};
        end else if (int'($signed(sf)) >= SF_MAX) begin
            special_sel = MAXPOS;
            mag_trunc   = {NB-1{1'b1}};
            guard_bit   = 1'b0;
            round_bit   = 1'b0;
            sticky_bit  = 1'b0;
            flags_p1    = {1'b0, flags_in[3:0]};
            if (int'($signed(sf)) > SF_MAX || (|frac) || sticky) begin
                flags_p1[3] = 1'b1;
                flags_p1[1] = 1'b1;
            end
        end else if (int'($signed(sf)) < -SF_MAX) begin
            special_sel = MINPOS;
            mag_trunc   = {{NB-2{1'b0}}, 1'b1};
            guard_bit   = 1'b0;
            round_bit   = 1'b0;
            sticky_bit  = 1'b0;
            flags_p1    = {1'b0, flags_in[3:0]};
            flags_p1[2] = 1'b1;
            flags_p1[1] = 1'b1;
        end
    end

    wire eff_sign         = product_mode ? 1'b0 : sign;
    wire round_up         = guard_bit & (mag_trunc[0] | round_bit | sticky_bit);
    wire [31:0] signed_base = {1'b0, mag_trunc} ^ {32{eff_sign}};
    wire signed_increment = eff_sign ^ round_up;
    wire [31:0] rounded_signed = signed_base + {31'd0, signed_increment};
    wire magnitude_zero   = ~(|mag_trunc);
    wire magnitude_max    = &mag_trunc;
    wire [31:0] min_encoded = eff_sign ? 32'hFFFF_FFFF : 32'h0000_0001;
    wire [31:0] max_encoded = eff_sign ? 32'h8000_0001 : 32'h7FFF_FFFF;

    always_comb begin
        flags = flags_p1;
        d     = '0;
        unique case (special_sel)
            ZERO:   d = '0;
            NAR: begin
                d     = 32'h8000_0000;
                flags = 5'b10000;
            end
            MAXPOS: d = max_encoded;
            MINPOS: d = min_encoded;
            NORMAL: begin
                if (magnitude_max)       d = max_encoded;
                else if (magnitude_zero) d = min_encoded;
                else                     d = rounded_signed;
            end
            default: begin
                d     = '0;
                flags = '0;
            end
        endcase
    end
endmodule
