//-----------------------------------------------------------------------------
// File          : round_unpacked_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-13
// Description   : Normative parse(pack(u)) reference implementation.
//-----------------------------------------------------------------------------
// $Source: $ $Revision: 1.0 $ $Log: W11 first implementation; STA not claimed. $
module round_unpacked_comb #(
    parameter int NB = 32,
    parameter int ES = 3,
    parameter int F = NB-3-ES,
    parameter int F_IN = 2*F+1,
    parameter int SF_W = $clog2(64'd4*(longint'(NB)-64'd2)*(64'd1<<ES)+64'd4)+1
)(
    input logic sign,
    input logic is_zero,
    input logic is_nar,
    input logic signed [SF_W-1:0] sf,
    input logic [F_IN-1:0] frac,
    input logic [4:0] flags_in,
    output wire sign_o,
    output wire is_zero_o,
    output wire is_nar_o,
    output wire signed [SF_W-1:0] sf_o,
    output wire [F-1:0] frac_o,
    output wire [4:0] flags_o
);
    wire [NB-1:0] packed_value;
    wire numerical_sticky = 1'b0;
    posit_pack_comb #(
        .NB(NB),
        .ES(ES),
        .F_IN(F_IN),
        .SF_W(SF_W)
    ) u_pack (
        .sign(sign),
        .is_zero(is_zero),
        .is_nar(is_nar),
        .sf(sf),
        .frac(frac),
        .sticky(numerical_sticky),
        .flags_in(flags_in),
        .d(packed_value),
        .flags(flags_o)
    );
    posit_parser_comb #(
        .NB(NB),
        .ES(ES),
        .SF_W(SF_W)
    ) u_parse (
        .p(packed_value),
        .s(sign_o),
        .is_zero(is_zero_o),
        .is_nar(is_nar_o),
        .sf(sf_o),
        .frac(frac_o)
    );
endmodule
// End of round_unpacked_comb.sv
