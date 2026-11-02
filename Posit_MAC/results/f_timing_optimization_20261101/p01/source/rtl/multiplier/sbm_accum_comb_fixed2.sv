//-----------------------------------------------------------------------------
// File          : sbm_accum_comb_fixed2.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : Approximate-only accumulator combinational step;
//                 init_only loads y_base without adding term.
// $Source: $ $Revision: 3.0 $ $Log: Removed sticky_acc/sticky_next ports. $
//-----------------------------------------------------------------------------
module sbm_accum_comb_fixed2 (
    input  logic        first,
    input  logic        init_only,
    input  logic [15:0] y_base,
    input  logic [15:0] term,
    input  logic        term_tail,
    input  logic [15:0] acc,
    input  logic        numerical_tail,
    output logic [15:0] acc_next,
    output logic        numerical_next,
    output logic        carry_error
);
    // Fixed posit32/ES3 approximate-12 elaboration; no public parameters.
    localparam int ACC_W = 16;

    wire [ACC_W-1:0] base_val = first ? y_base : acc;
    wire [ACC_W-1:0] add_term = init_only ? 16'd0 : term;
    wire [ACC_W:0]   sum      = {1'b0, base_val} + {1'b0, add_term};

    assign acc_next       = sum[ACC_W-1:0];
    assign carry_error    = sum[ACC_W];
    assign numerical_next = (first ? 1'b0 : numerical_tail) | (!init_only & term_tail);

endmodule
//-----------------------------------------------------------------------------
// End of sbm_accum_comb_fixed2.sv
//-----------------------------------------------------------------------------
