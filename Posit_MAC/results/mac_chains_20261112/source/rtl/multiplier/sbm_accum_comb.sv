//-----------------------------------------------------------------------------
// File          : sbm_accum_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Revision      : 2026-11-02 shared approximate12 FULL_TERM26/Q24
// Description   : One unsigned26 accumulator step with explicit overflow check.
//-----------------------------------------------------------------------------

module sbm_accum_comb (
    input  logic        first,
    input  logic [25:0] y_base,
    input  logic [25:0] term,
    input  logic [25:0] acc,
    output wire [25:0] acc_next,
    output wire        carry_error
);
    wire [25:0] base_value;
    wire [26:0] extended_sum;

    assign base_value = first ? y_base : acc;
    assign extended_sum = {1'b0, base_value} + {1'b0, term};
    assign acc_next = extended_sum[25:0];
    assign carry_error = extended_sum[26];
endmodule
// End of sbm_accum_comb.sv
