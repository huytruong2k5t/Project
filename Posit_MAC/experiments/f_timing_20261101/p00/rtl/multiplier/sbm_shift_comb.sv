//-----------------------------------------------------------------------------
// File          : sbm_shift_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : Align Y and cut each unsigned fraction term (SPEC 5.6).
// $Source: $ $Revision: 1.0 $ $Log: Initial week9 implementation. $
//-----------------------------------------------------------------------------
module sbm_shift_comb (
    input logic cfg_mode,
    input logic [26:0] y_mant,
    input logic [4:0] scale,
    input logic init_only,
    output logic [53:0] y_base,
    output logic [53:0] term,
    output logic term_tail
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    localparam int FRAC_MAX = 26;
    
    localparam int ROUND_SCHEME = 0;
    
    
    localparam int ACC_W = 54;

    typedef logic [ACC_W-1:0] acc_value_t;
    logic [ACC_W-1:0] shifted;
    integer shift_discard;
    always_comb begin
        y_base = '0;
        y_base = acc_value_t'(y_mant);
        if (cfg_mode) begin
            y_base = y_base << 2;
        end else begin
            y_base = y_base << FRAC_MAX;
        end
        shifted = y_base >> scale;
        term = shifted;
        shift_discard = int'(scale);
        if (cfg_mode && ROUND_SCHEME == 0) begin
            term[1:0] = 2'b00;
            shift_discard = shift_discard + 2;
        end
        term_tail = 1'b0;
        for (int bit_index = 0; bit_index < ACC_W; bit_index++) begin
            if (bit_index < shift_discard) begin
                term_tail = term_tail | y_base[bit_index];
            end
        end
        if (init_only) begin
            term = '0;
            term_tail = 1'b0;
        end
    end
endmodule
// End of sbm_shift_comb.sv
