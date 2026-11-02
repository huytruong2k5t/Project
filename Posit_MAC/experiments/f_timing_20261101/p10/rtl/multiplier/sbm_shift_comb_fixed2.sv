//-----------------------------------------------------------------------------
// File          : sbm_shift_comb_fixed2.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : Approximate-only Y alignment and unsigned fraction term shift.
//                 Uses dyn_right_shifter_fixed3 (flattened MUX tree) and
//                 parallel bit-mask reduction for term_tail.
// $Source: $ $Revision: 4.0 $ $Log: Removed cfg_mode; streamlined dataflow. $
//-----------------------------------------------------------------------------
module sbm_shift_comb_fixed2 (
    input  logic [12:0] y_mant,
    input  logic [3:0]  scale,
    input  logic        init_only,
    output logic [15:0] y_base,
    output logic [15:0] term,
    output logic        term_tail
);
    // Fixed posit32/ES3 approximate-12 elaboration; no public parameters.
    localparam int MANT_W = 13;
    localparam int ACC_W  = 16;

    logic [ACC_W-1:0] shifted;
    logic [MANT_W-1:0] discard_mask;
    wire  [MANT_W-1:0] discarded_bits;

    // 1. Align Y base (1 headroom bit + 13-bit mantissa + 2 guard bits)
    assign y_base = {1'b0, y_mant, 2'b00};

    // 2. Extract Y term using modular 16-bit dynamic right shifter
    dyn_right_shifter_fixed3 u_term_shift (
        .in       (y_base),
        .b        (scale),
        .fill_val (1'b0),
        .out      (shifted)
    );

    // 3. Term formation: clear 2 guard LSBs [1:0] (FLOOR grid) and gate with init_only
    assign term = init_only ? 16'd0 : {shifted[15:2], 2'b00};

    // 4. Discarded tail reduction: check if any of the 'scale' lowest bits of y_mant is '1'
    always_comb begin : b_discard_mask
        for (int i = 0; i < MANT_W; i++) begin
            discard_mask[i] = (i[3:0] < scale);
        end
    end

    assign discarded_bits = y_mant & discard_mask;
    assign term_tail      = init_only ? 1'b0 : (|discarded_bits);

endmodule
//-----------------------------------------------------------------------------
// End of sbm_shift_comb_fixed2.sv
//-----------------------------------------------------------------------------
