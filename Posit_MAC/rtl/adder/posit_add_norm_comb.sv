//-----------------------------------------------------------------------------
// File          : posit_add_norm_comb.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-31
// Description   : Stage S5 of 5-stage Posit(32,3) adder: parallel 30-bit left
//                 shift, single-step scale update (sf_inc - count), and
//                 unified NaR/Zero output classification without redundant
//                 datapath clearing (downstream packer handles zero/NaR bypass).
//-----------------------------------------------------------------------------
module posit_add_norm_comb (
    input  logic [29:0]        norm_seed,
    input  logic [4:0]         leading_count,
    input  logic               nonzero,
    input  logic               sign_base,
    input  logic signed [10:0] sf_inc,
    input  logic               sticky_raw,
    input  logic               both_zero,
    input  logic               is_nar_in,
    input  logic [3:0]         flags_lo,
    output logic               sign,
    output logic               is_zero,
    output logic               is_nar,
    output logic signed [10:0] sf,
    output logic [28:0]        frac_hi,
    output logic               sticky,
    output logic [4:0]         flags_out
);
    wire [28:0]        shifted_hi;
    wire               unused_shifted_lsb;
    wire signed [10:0] count_ext = $signed({6'b0, leading_count});
    wire signed [10:0] sf_raw    = sf_inc - count_ext;

    // 1. Parallel 30-bit flattened barrel left shift
    dyn_left_shifter_fixed6 u_left_shift (
        .in  (norm_seed),
        .b   (leading_count),
        .out ({shifted_hi, unused_shifted_lsb})
    );

    // 2. Output classification & flag generation
    // Zero/NaR bypass is performed at packer stage, eliminating 41 redundant clear MUXes.
    wire final_zero = !is_nar_in && (both_zero || !nonzero);

    assign is_nar    = is_nar_in;
    assign is_zero   = final_zero;
    assign sign      = is_nar_in ? 1'b1 : (final_zero ? 1'b0 : sign_base);
    assign sf        = sf_raw;
    assign frac_hi   = shifted_hi;
    assign sticky    = sticky_raw;
    assign flags_out = is_nar_in ? 5'b10000
                                 : {1'b0, flags_lo[3:2], flags_lo[1] | (!final_zero & sticky_raw), flags_lo[0]};

endmodule
//-----------------------------------------------------------------------------
// End of posit_add_norm_comb.sv
//-----------------------------------------------------------------------------
