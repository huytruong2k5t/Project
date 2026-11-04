//-----------------------------------------------------------------------------
// File          : posit_add_align_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-31
// Description   : Stage S2 of 5-stage Posit(32,3) adder: flattened 31-bit
//                 right shift and parallel thermometer-mask jam/sticky logic.
//-----------------------------------------------------------------------------
module posit_add_align_comb (
    input  logic [25:0] y_frac,
    input  logic [4:0]  shift_amount,
    input  logic        clamped,
    input  logic        both_nonzero,
    output logic [30:0] y,
    output logic        alignment_tail
);
    wire [30:0] y_seed = {1'b0, 1'b1, y_frac, 3'b000};
    wire [30:0] shifted_full;
    wire [24:0] discard_mask;

    // 1. Flattened 31-bit barrel right shift
    dyn_right_shifter_fixed4 u_right_shift (
        .in  (y_seed),
        .b   (shift_amount),
        .out (shifted_full)
    );

    // 2. Parallel thermometer mask for bits shifted strictly below bit 0
    genvar j;
    generate
        for (j = 0; j < 25; j = j + 1) begin : g_mask
            localparam [4:0] BIT_POS = j + 3;
            assign discard_mask[j] = (BIT_POS < shift_amount);
        end
    endgenerate

    wire raw_tail = |(y_frac[24:0] & discard_mask);

    // 3. Final aligned Y and tail formation
    assign y[30:1]        = (both_nonzero && !clamped) ? shifted_full[30:1] : 30'd0;
    assign y[0]           = both_nonzero && (clamped || shifted_full[0] || raw_tail);
    assign alignment_tail = both_nonzero && (clamped || raw_tail);

endmodule
//-----------------------------------------------------------------------------
// End of posit_add_align_comb.sv
//-----------------------------------------------------------------------------

