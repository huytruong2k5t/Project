//-----------------------------------------------------------------------------
// File          : sbm_shift_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Revision      : 2026-11-02 shared approximate12 FULL_TERM26/Q24
// Description   : Lossless FULL_TERM term shift; four flat MUX levels.
//-----------------------------------------------------------------------------

module sbm_shift_comb (
    input  logic [12:0] y_mant,
    input  logic [3:0]  scale,
    input  logic        init_only,
    output wire [25:0]  y_base,
    output wire [25:0]  term
);
    wire [25:0] stage0;
    wire [25:0] stage1;
    wire [25:0] stage2;
    wire [25:0] stage3;

    // Q24: hidden plus fraction12, followed by twelve exact zero positions.
    assign y_base = {1'b0, y_mant, 12'b0};
    assign stage0 = scale[0] ? {1'b0, y_base[25:1]} : y_base;
    assign stage1 = scale[1] ? {2'b0, stage0[25:2]} : stage0;
    assign stage2 = scale[2] ? {4'b0, stage1[25:4]} : stage1;
    assign stage3 = scale[3] ? {8'b0, stage2[25:8]} : stage2;
    assign term = init_only ? 26'b0 : stage3;
endmodule
// End of sbm_shift_comb.sv
