//-----------------------------------------------------------------------------
// File          : packer_ppa_top.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-07
// Description   : Registered boundaries for standalone packer PPA comparison.
//                 Fixed posit32 ES2/F_IN55; continuous stream, no output stall.
//                 This benchmark is not the MAC top or a board pin assignment.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: Initial Quartus resource/timing benchmark. $

module packer_ppa_top #(
    parameter ROUND_MODE = "RNE"
)(
    input logic clk,
    input logic reset_n,
    input logic  sign,
    input logic  is_zero,
    input logic  is_nar,
    input logic signed [9:0] sf,
    input logic [54:0] frac,
    input logic  sticky,
    input logic [4:0] flags_in,
    output wire out_valid,
    output wire [31:0] d,
    output wire [4:0] flags
);
    wire  sign_q;
    wire  is_zero_q;
    wire  is_nar_q;
    wire signed [9:0] sf_q;
    wire [54:0] frac_q;
    wire  sticky_q;
    wire [4:0] flags_in_q;
    wire pack_in_ready;
    wire pack_in_valid;
    wire pack_out_ready;
    wire pack_out_valid;
    wire [31:0] pack_d;
    wire [4:0] pack_flags;
    packer_ppa_boundary u_boundary (
        .clk(clk),
        .reset_n(reset_n),
        .sign_i(sign),
        .is_zero_i(is_zero),
        .is_nar_i(is_nar),
        .sf_i(sf),
        .frac_i(frac),
        .sticky_i(sticky),
        .flags_in_i(flags_in),
        .sign_q(sign_q),
        .is_zero_q(is_zero_q),
        .is_nar_q(is_nar_q),
        .sf_q(sf_q),
        .frac_q(frac_q),
        .sticky_q(sticky_q),
        .flags_in_q(flags_in_q),
        .pack_in_ready(pack_in_ready),
        .pack_in_valid(pack_in_valid),
        .pack_out_ready(pack_out_ready),
        .pack_out_valid(pack_out_valid),
        .pack_d(pack_d),
        .pack_flags(pack_flags),
        .out_valid(out_valid),
        .d(d),
        .flags(flags)
    );
    posit_pack #(.NB(32), .ES(2), .F_IN(55), .SF_W(10),
                 .ROUND_MODE(ROUND_MODE)) u_packer (
        .clk(clk),
        .reset_n(reset_n),
        .in_valid(pack_in_valid),
        .in_ready(pack_in_ready),
        .sign(sign_q),
        .is_zero(is_zero_q),
        .is_nar(is_nar_q),
        .sf(sf_q),
        .frac(frac_q),
        .sticky(sticky_q),
        .flags_in(flags_in_q),
        .out_valid(pack_out_valid),
        .out_ready(pack_out_ready),
        .d(pack_d),
        .flags(pack_flags)
    );
endmodule
