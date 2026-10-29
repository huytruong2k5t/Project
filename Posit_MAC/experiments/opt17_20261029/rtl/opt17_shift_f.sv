//-----------------------------------------------------------------------------
// File          : opt17_shift_f.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP, OPT-17 FULL_TERM study
// Creation Date : 2026-10-29
// Description   : Exact Q24 term shift on the retained 12-bit significands.
// $Source: $ $Revision: 1.0 $ $Log: No per-term FLOOR, JAM, or RNE. $
//-----------------------------------------------------------------------------
module opt17_shift_f (
    input logic cfg_mode,
    input logic [12:0] y_mant,
    input logic [3:0] scale,
    input logic init_only,
    output wire [25:0] y_base,
    output wire [25:0] term,
    output logic term_tail
);
    wire [25:0] shifted;
    assign y_base = {1'b0, y_mant, 12'b0};
    assign shifted = y_base >> scale;
    assign term = init_only ? 26'b0 : shifted;
    always_comb begin
        term_tail = !cfg_mode;
        for (int bit_index = 0; bit_index < 26; bit_index++) begin
            if (!init_only && bit_index < int'(scale)) begin
                term_tail = term_tail | y_base[bit_index];
            end
        end
    end
endmodule
// End of opt17_shift_f.sv
