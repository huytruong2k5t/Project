//-----------------------------------------------------------------------------
// File          : posit_pack_finish.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-06
// Description   : P2 combinational rounding, magnitude clamp and sign encoding.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.1 $
// $Log: 2026-10-07: merge rounding/sign into one carry chain. $

module posit_pack_finish #(
    parameter int NB = 32,
    parameter [39:0] ROUND_MODE = "RNE"
)(
    input  logic [NB-2:0] mag_trunc,
    input  logic guard_bit,
    input  logic round_bit,
    input  logic sticky_bit,
    input  logic sign,
    input  logic [2:0] special_sel,
    input  logic [4:0] flags_in,
    output logic [NB-1:0] d,
    output logic [4:0] flags
);
    // TRUNC intentionally ignores G/R/S for increment; keep explicit consumption.
    wire unused_trunc_grs = ^{guard_bit, round_bit, sticky_bit};
    localparam logic [2:0] NORMAL = 3'd0;
    localparam logic [2:0] ZERO = 3'd1;
    localparam logic [2:0] NAR = 3'd2;
    localparam logic [2:0] MAXPOS = 3'd3;
    localparam logic [2:0] MINPOS = 3'd4;
    localparam logic [NB-1:0] MAX_MAG = {1'b0, {NB-1{1'b1}}};

    localparam logic [NB-1:0] MIN_MAG = {{NB-1{1'b0}}, 1'b1};
    localparam logic [NB-1:0] NEG_MAX_MAG = {1'b1, {NB-2{1'b0}}, 1'b1};

    wire round_up;
    wire magnitude_zero;
    wire magnitude_max;
    wire [NB-1:0] signed_base;
    wire signed_increment;
    wire [NB-1:0] rounded_signed;
    wire [NB-1:0] min_encoded;
    wire [NB-1:0] max_encoded;

    generate
        if (ROUND_MODE == "RNE") begin : g_rne
            assign round_up = guard_bit
                            & (mag_trunc[0] | round_bit | sticky_bit);
        end else if (ROUND_MODE == "TRUNC") begin : g_trunc
            assign round_up = 1'b0;
        end else begin : g_invalid
            initial $fatal(1, "posit_pack_finish: ROUND_MODE must be RNE or TRUNC");
        end
    endgenerate

    // Positive: m + r. Negative: -(m + r) = ~m + (1 - r).
    // The sign XOR selects the addend; only one NB-bit carry chain remains.
    assign signed_base = {1'b0, mag_trunc} ^ {NB{sign}};
    assign signed_increment = sign ^ round_up;
    assign rounded_signed = signed_base
                          + {{NB-1{1'b0}}, signed_increment};

    // Detect clamp endpoints before the adder, in parallel with rounding.
    // m == 0 clamps to minpos for both r values; m == max clamps to maxpos.
    assign magnitude_zero = ~(|mag_trunc);
    assign magnitude_max = &mag_trunc;
    assign min_encoded = sign ? {NB{1'b1}} : MIN_MAG;
    assign max_encoded = sign ? NEG_MAX_MAG : MAX_MAG;

    always_comb begin
        flags = flags_in;
        d = '0;

        unique case (special_sel)
            ZERO: begin
                d = '0;
            end
            NAR: begin
                d = {1'b1, {NB-1{1'b0}}};
                flags = 5'b10000;
            end
            MAXPOS: begin
                d = max_encoded;
            end
            MINPOS: begin
                d = min_encoded;
            end
            NORMAL: begin
                if (magnitude_max) begin
                    d = max_encoded;
                end else if (magnitude_zero) begin
                    d = min_encoded;
                end else begin
                    d = rounded_signed;
                end
            end
            default: begin
                d = '0;
                flags = '0;
            end
        endcase
    end

endmodule
//-----------------------------------------------------------------------------
// End of posit_pack_finish.sv
//-----------------------------------------------------------------------------
