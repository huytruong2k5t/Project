//-----------------------------------------------------------------------------
// File          : posit_pack_finish.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-06
// Description   : P2 combinational RNE rounding, magnitude clamp and sign encoding.
//                 Refactored & flattened for posit(32,3):
//                   - Direct RNE rounding without dead TRUNC generate scopes
//                   - Single 32-bit carry chain merging rounding & 2's complement
//                   - Parallel endpoint clamp detection & NORMAL G/R/S flag merge
//-----------------------------------------------------------------------------

module posit_pack_finish (
    input  logic [30:0] mag_trunc,
    input  logic        guard_bit,
    input  logic        round_bit,
    input  logic        sticky_bit,
    input  logic        sign,
    input  logic [2:0]  special_sel,
    input  logic [4:0]  flags_in,
    output logic [31:0] d,
    output logic [4:0]  flags
);
    // Special case encodings from P1 prepare stage
    localparam logic [2:0] NORMAL = 3'd0;
    localparam logic [2:0] ZERO   = 3'd1;
    localparam logic [2:0] NAR    = 3'd2;
    localparam logic [2:0] MAXPOS = 3'd3;
    localparam logic [2:0] MINPOS = 3'd4;

    // Posit(32,3) saturation constants
    localparam logic [31:0] POS_MAX_MAG = 32'h7FFF_FFFF;
    localparam logic [31:0] POS_MIN_MAG = 32'h0000_0001;
    localparam logic [31:0] NEG_MAX_MAG = 32'h8000_0001;
    localparam logic [31:0] NEG_MIN_MAG = 32'hFFFF_FFFF;
    localparam logic [31:0] NAR_PATTERN = 32'h8000_0000;

    //-------------------------------------------------------------------------
    // 1. Round-to-Nearest-Even (RNE) & Merged Sign/Rounding Carry Chain
    //-------------------------------------------------------------------------
    // Positive (sign=0):  (m + r) = {1'b0, mag_trunc} + round_up
    // Negative (sign=1): -(m + r) = ~{1'b0, mag_trunc} + (1 - round_up)
    wire        round_up         = guard_bit & (mag_trunc[0] | round_bit | sticky_bit);
    wire [31:0] signed_base      = {1'b0, mag_trunc} ^ {32{sign}};
    wire        signed_increment = sign ^ round_up;
    wire [31:0] rounded_signed   = signed_base + {31'd0, signed_increment};

    //-------------------------------------------------------------------------
    // 2. Parallel Endpoint Clamp Detection
    //-------------------------------------------------------------------------
    wire        magnitude_zero = ~(|mag_trunc);
    wire        magnitude_max  = &mag_trunc;
    wire [31:0] min_encoded    = sign ? NEG_MIN_MAG : POS_MIN_MAG;
    wire [31:0] max_encoded    = sign ? NEG_MAX_MAG : POS_MAX_MAG;

    //-------------------------------------------------------------------------
    // 3. Final Output & Flag Selection
    //-------------------------------------------------------------------------
    always_comb begin
        flags = flags_in;
        unique case (special_sel)
            ZERO:   d = 32'h0000_0000;
            NAR: begin
                d     = NAR_PATTERN;
                flags = 5'b10000;
            end
            MAXPOS: d = max_encoded;
            MINPOS: d = min_encoded;
            NORMAL: begin
                flags[1] = flags_in[1] | guard_bit | round_bit | sticky_bit;
                if (magnitude_max)       d = max_encoded;
                else if (magnitude_zero) d = min_encoded;
                else                     d = rounded_signed;
            end
            default: begin
                d     = 32'h0000_0000;
                flags = 5'b00000;
            end
        endcase
    end

endmodule
//-----------------------------------------------------------------------------
// End of posit_pack_finish.sv
//-----------------------------------------------------------------------------
