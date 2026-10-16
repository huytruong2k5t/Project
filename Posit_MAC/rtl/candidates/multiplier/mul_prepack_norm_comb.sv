//-----------------------------------------------------------------------------
// File          : mul_prepack_norm_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-13
// Description   : Preserve raw prepack value when normalizing a carry.
//-----------------------------------------------------------------------------
// $Source: $ $Revision: 1.0 $ $Log: W11-01 independent dyadic oracle verified. $
// 2026-10-16: Constant bit mapping; preserve prepack and stage boundaries.
module mul_prepack_norm_comb #(
    parameter int FRAC_MAX = 26,
    parameter int FRAC_W = 12,
    parameter bit EXACT_EN = 1'b1,
    parameter int ACC_W = EXACT_EN ? ((2*FRAC_MAX+2 > FRAC_W+4) ? 2*FRAC_MAX+2 : FRAC_W+4) : FRAC_W+4,
    parameter int SF_W = 11,
    parameter int F_IN = 2*FRAC_MAX+1
)(
    input logic cfg_mode,
    input logic [ACC_W-1:0] acc,
    input logic signed [SF_W-1:0] sf,
    output logic signed [SF_W-1:0] sf_norm,
    output logic [F_IN-1:0] frac_norm
);
    typedef logic signed [SF_W-1:0] sf_t;
    wire [F_IN-1:0] approx_no_carry;
    wire [F_IN-1:0] approx_carry;
    wire [F_IN-1:0] selected_fraction;
    wire selected_carry;

    generate
        if (FRAC_MAX < 1 || FRAC_W < 1 || FRAC_W > FRAC_MAX ||
            F_IN < 1 || SF_W < 1 || ACC_W < FRAC_W + 4 ||
            (EXACT_EN && ACC_W < 2*FRAC_MAX + 2)) begin : g_invalid
            initial $fatal(1, "mul_prepack_norm_comb: unsupported parameters");
        end

        // Approx grid is acc >> 2. Discard only the two physical padding bits;
        // carry changes the hidden position, without shifting away value bits.
        for (genvar i = 0; i < F_IN; i++) begin : g_approx_bits
            localparam int NO_CARRY_INDEX = i + FRAC_W - F_IN + 2;
            localparam int CARRY_INDEX = i + FRAC_W + 1 - F_IN + 2;

            if (NO_CARRY_INDEX >= 2 && NO_CARRY_INDEX < FRAC_W + 2) begin : g_no_carry
                assign approx_no_carry[i] = acc[NO_CARRY_INDEX];
            end else begin : g_no_carry_zero
                assign approx_no_carry[i] = 1'b0;
            end

            if (CARRY_INDEX >= 2 && CARRY_INDEX < FRAC_W + 3) begin : g_carry
                assign approx_carry[i] = acc[CARRY_INDEX];
            end else begin : g_carry_zero
                assign approx_carry[i] = 1'b0;
            end
        end

        if (EXACT_EN) begin : g_exact_enabled
            wire [F_IN-1:0] exact_no_carry;
            wire [F_IN-1:0] exact_carry;
            wire [F_IN-1:0] exact_fraction;
            wire [F_IN-1:0] approx_fraction;
            wire exact_carry_bit;
            wire approx_carry_bit;

            for (genvar i = 0; i < F_IN; i++) begin : g_exact_bits
                localparam int NO_CARRY_INDEX = i + 2*FRAC_MAX - F_IN;
                localparam int CARRY_INDEX = i + 2*FRAC_MAX + 1 - F_IN;

                if (NO_CARRY_INDEX >= 0 && NO_CARRY_INDEX < 2*FRAC_MAX) begin : g_no_carry
                    assign exact_no_carry[i] = acc[NO_CARRY_INDEX];
                end else begin : g_no_carry_zero
                    assign exact_no_carry[i] = 1'b0;
                end

                if (CARRY_INDEX >= 0 && CARRY_INDEX < 2*FRAC_MAX + 1) begin : g_carry
                    assign exact_carry[i] = acc[CARRY_INDEX];
                end else begin : g_carry_zero
                    assign exact_carry[i] = 1'b0;
                end
            end

            assign exact_carry_bit = acc[2*FRAC_MAX + 1];
            assign approx_carry_bit = acc[FRAC_W + 3];
            assign exact_fraction = exact_carry_bit ? exact_carry : exact_no_carry;
            assign approx_fraction = approx_carry_bit ? approx_carry : approx_no_carry;
            assign selected_fraction = cfg_mode ? approx_fraction : exact_fraction;
            assign selected_carry = cfg_mode ? approx_carry_bit : exact_carry_bit;
        end else begin : g_approx_only
            // cfg_mode=0 is rejected by the parent when EXACT_EN=0.
            // Keep that unsupported request deterministic, with no exact cone.
            assign selected_fraction = cfg_mode
                                     ? (acc[FRAC_W + 3] ? approx_carry : approx_no_carry)
                                     : '0;
            assign selected_carry = cfg_mode && acc[FRAC_W + 3];
        end
    endgenerate

    assign sf_norm = sf + sf_t'(selected_carry);
    assign frac_norm = selected_fraction;
endmodule
// End of mul_prepack_norm_comb.sv
