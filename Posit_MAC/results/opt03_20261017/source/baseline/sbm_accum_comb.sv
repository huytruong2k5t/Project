//-----------------------------------------------------------------------------
// File          : sbm_accum_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : One accumulator commit; init_only loads Y, not Y+Y.
// $Source: $ $Revision: 1.0 $ $Log: Initial week9 implementation. $
//-----------------------------------------------------------------------------
module sbm_accum_comb #(
    parameter int ACC_W = 56,
    parameter int ROUND_SCHEME = 0
)(
    input logic cfg_mode,
    input logic first,
    input logic init_only,
    input logic [ACC_W-1:0] y_base,
    input logic [ACC_W-1:0] term,
    input logic term_tail,
    input logic [ACC_W-1:0] acc,
    input logic sticky_acc,
    input logic numerical_tail,
    output logic [ACC_W-1:0] acc_next,
    output logic sticky_next,
    output logic numerical_next,
    output logic carry_error
);
    logic [ACC_W:0] sum;
    always_comb begin
        sum = {1'b0, first ? y_base : acc};
        sticky_next = first ? 1'b0 : sticky_acc;
        numerical_next = first ? 1'b0 : numerical_tail;
        if (!init_only) begin
            sum = sum + {1'b0, term};
            numerical_next = numerical_next | term_tail;
            if (!cfg_mode || ROUND_SCHEME == 1) begin
                sticky_next = sticky_next | term_tail;
            end
        end
        acc_next = sum[ACC_W-1:0];
        carry_error = sum[ACC_W];
    end
endmodule
// End of sbm_accum_comb.sv
