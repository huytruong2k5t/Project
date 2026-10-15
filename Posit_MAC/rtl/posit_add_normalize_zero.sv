//-----------------------------------------------------------------------------
// File          : posit_add_normalize_zero.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-12
// Description   : Carry/LZD normalization and lossless adapter to the Posit packer.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.1 $
// $Log: Isolated early-zero trial; preserve SPEC 5.8 flags/sticky. $

module posit_add_normalize_zero #(
    parameter int NB = 32,
    parameter int ES = 2,
    parameter int F = NB - 3 - ES,
    parameter int SF_W = $clog2(64'd4 * (longint'(NB) - 64'd2) * (64'd1 << ES) + 64'd4) + 1,
    parameter int F_OUT = 2 * F + 1
)(
    input logic [F+4:0] magnitude,
    input logic sign_base,
    input logic signed [SF_W-1:0] sf_base,
    input logic alignment_tail,
    input logic is_zero_in,
    input logic is_nar_in,
    input logic [4:0] flags_in,
    output logic sign,
    output logic is_zero,
    output logic is_nar,
    output logic signed [SF_W-1:0] sf,
    output logic [F_OUT-1:0] frac,
    output logic sticky,
    output logic [4:0] flags_out
);
    localparam int Q = F + 3;
    localparam int LOD_W = $clog2(Q + 1);
    typedef logic signed [SF_W-1:0] sf_t;
    logic [Q:0] magnitude_low;
    logic [Q-1:0] normalized_left;
    logic [Q-1:0] normalized;
    logic [LOD_W-1:0] left_shift;
    logic leading_valid;
    logic carry;
    logic lost_carry;

    generate
        if (F != NB - 3 - ES || F < 2 || F_OUT != 2 * F + 1
            || SF_W < $clog2(64'd4 * (longint'(NB) - 64'd2) * (64'd1 << ES) + 64'd4) + 1) begin : g_invalid
            initial $fatal(1, "posit_add_normalize_zero: unsupported parameters");
        end
    endgenerate

    assign magnitude_low = magnitude[Q:0];
    assign carry = magnitude[Q+1];
    assign lost_carry = carry && magnitude[0];
    lod_lzd_core #(
        .N (Q + 1),
        .MODE (0),
        .S (LOD_W)
    ) u_lod (
        .in (magnitude_low),
        .K (left_shift),
        .vld (leading_valid)
    );
    dyn_left_shifter #(
        .N (Q),
        .SHIFT_W (LOD_W)
    ) u_left_shift (
        .in (magnitude_low[Q-1:0]),
        .b (left_shift),
        .out (normalized_left)
    );

    always_comb begin
        normalized = normalized_left;
        if (carry) begin
            normalized = magnitude[Q:1];
            normalized[0] = magnitude[1] | magnitude[0];
        end
        sign = sign_base;
        // Detect zero before the normalize shifter; hidden-bit invariant is checked in TB.
        is_zero = is_zero_in || !(leading_valid || carry);
        is_nar = is_nar_in || flags_in[4];
        sf = carry ? sf_base + sf_t'(1) : sf_base - sf_t'(left_shift);
        frac = {normalized[Q-1:0], {(F-2){1'b0}}};
        sticky = alignment_tail || lost_carry;
        flags_out = {1'b0, flags_in[3:0]};
        flags_out[1] = flags_in[1] || sticky;
        if (is_nar) begin
            sign = 1'b1;
            is_zero = 1'b0;
            sf = '0;
            frac = '0;
            sticky = 1'b0;
            flags_out = 5'b10000;
        end else if (is_zero) begin
            sign = 1'b0;
            sf = '0;
            frac = '0;
            sticky = 1'b0;
            flags_out = {1'b0, flags_in[3:0]};
        end
    end
endmodule

//-----------------------------------------------------------------------------
// End of posit_add_normalize_zero.sv
//-----------------------------------------------------------------------------
