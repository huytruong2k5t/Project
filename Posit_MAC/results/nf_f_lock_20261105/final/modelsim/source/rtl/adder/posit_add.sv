//-----------------------------------------------------------------------------
// File          : posit_add.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-12
// Description   : Consolidated 5-stage high-frequency elastic Posit(32,3) adder.
//                 Directly encloses S1 Prepare/Swap, S2 Align/Jam, S3 Arith,
//                 S4 Radix-4 LOD, and S5 Normalize/Output (~200 MHz target),
//                 with all pipeline registers and elastic control unified here.
// $Source: $ $Revision: 2.0 $ $Log: Upgraded to balanced 5-stage pipeline; pruned dead logic/FFs. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"

module posit_add (
    input  logic               clk,
    input  logic               reset_n,
    input  logic               in_valid,
    output wire                in_ready,
    output wire                out_valid,
    input  logic               out_ready,
    input  logic               a_sign,
    input  logic               a_is_zero,
    input  logic               a_is_nar,
    input  logic signed [10:0] a_sf,
    input  logic [25:0]        a_frac,
    input  logic               b_sign,
    input  logic               b_is_zero,
    input  logic               b_is_nar,
    input  logic signed [10:0] b_sf,
    input  logic [25:0]        b_frac,
    input  logic [4:0]         flags_in,
    output logic               sign,
    output logic               is_zero,
    output logic               is_nar,
    output logic signed [10:0] sf,
    output wire  [52:0]        frac,
    output logic               sticky,
    output logic [4:0]         flags_out
);
    // 2-Stage Reset Synchronizer
    (* ASYNC_REG = "TRUE" *) logic meta_sync1, meta_sync2;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end

    // Elastic 5-Stage Handshake Control
    logic [4:0] valid_q;
    wire ready4 = !valid_q[4] || out_ready;
    wire ready3 = !valid_q[3] || ready4;
    wire ready2 = !valid_q[2] || ready3;
    wire ready1 = !valid_q[1] || ready2;
    wire ready0 = !valid_q[0] || ready1;

    assign in_ready  = meta_sync2 && ready0;
    assign out_valid = meta_sync2 && valid_q[4];

    //-------------------------------------------------------------------------
    // Stage S1: Prepare & Operand Swap (X >= Y)
    //-------------------------------------------------------------------------
    wire [25:0]        s1_x_frac_d, s1_y_frac_d;
    wire [4:0]         s1_shift_d;
    wire               s1_clamped_d, s1_both_nz_d, s1_sub_d, s1_sign_d;
    wire signed [10:0] s1_sf_d;
    wire               s1_both_zero_d, s1_nar_d;
    wire [3:0]         s1_flags_d;

    logic [25:0]        s1_x_frac_q, s1_y_frac_q;
    logic [4:0]         s1_shift_q;
    logic               s1_clamped_q, s1_both_nz_q, s1_sub_q, s1_sign_q;
    logic signed [10:0] s1_sf_q;
    logic               s1_both_zero_q, s1_nar_q;
    logic [3:0]         s1_flags_q;

    posit_add_prepare_comb u_s1_prepare (
        .a_sign       (a_sign),
        .a_is_zero    (a_is_zero),
        .a_is_nar     (a_is_nar),
        .a_sf         (a_sf),
        .a_frac       (a_frac),
        .b_sign       (b_sign),
        .b_is_zero    (b_is_zero),
        .b_is_nar     (b_is_nar),
        .b_sf         (b_sf),
        .b_frac       (b_frac),
        .flags_in     (flags_in),
        .x_frac       (s1_x_frac_d),
        .y_frac       (s1_y_frac_d),
        .shift_amount (s1_shift_d),
        .clamped      (s1_clamped_d),
        .both_nonzero (s1_both_nz_d),
        .subtract     (s1_sub_d),
        .sign_base    (s1_sign_d),
        .sf_base      (s1_sf_d),
        .both_zero    (s1_both_zero_d),
        .is_nar       (s1_nar_d),
        .flags_lo     (s1_flags_d)
    );

    //-------------------------------------------------------------------------
    // Stage S2: Flattened Right Shift & Thermometer Jam/Sticky
    //-------------------------------------------------------------------------
    wire [30:0] s2_y_d;
    wire        s2_tail_d;

    logic [25:0]        s2_x_frac_q;
    logic [30:0]        s2_y_q;
    logic               s2_tail_q, s2_sub_q, s2_sign_q;
    logic signed [10:0] s2_sf_q;
    logic               s2_both_zero_q, s2_nar_q;
    logic [3:0]         s2_flags_q;

    posit_add_align_comb u_s2_align (
        .y_frac         (s1_y_frac_q),
        .shift_amount   (s1_shift_q),
        .clamped        (s1_clamped_q),
        .both_nonzero   (s1_both_nz_q),
        .y              (s2_y_d),
        .alignment_tail (s2_tail_d)
    );

    //-------------------------------------------------------------------------
    // Stage S3: Unsigned 31-bit Add/Subtract & Parallel Scale Pre-Increment
    //-------------------------------------------------------------------------
    wire [30:0]        s3_mag_d;
    wire signed [10:0] s3_sf_inc_d;

    logic [30:0]        s3_mag_q;
    logic signed [10:0] s3_sf_inc_q;
    logic               s3_tail_q, s3_sign_q;
    logic               s3_both_zero_q, s3_nar_q;
    logic [3:0]         s3_flags_q;

    posit_add_arith_comb u_s3_arith (
        .x_frac    (s2_x_frac_q),
        .y         (s2_y_q),
        .subtract  (s2_sub_q),
        .sf_base   (s2_sf_q),
        .magnitude (s3_mag_d),
        .sf_inc    (s3_sf_inc_d)
    );

    //-------------------------------------------------------------------------
    // Stage S4: Unified 31-bit Radix-4 LOD & Carry-Jam Seed
    //-------------------------------------------------------------------------
    wire [29:0] s4_seed_d;
    wire [4:0]  s4_count_d;
    wire        s4_nz_d;
    wire        s4_sticky_d;

    logic [29:0]        s4_seed_q;
    logic [4:0]         s4_count_q;
    logic               s4_nz_q, s4_sticky_q, s4_sign_q;
    logic signed [10:0] s4_sf_inc_q;
    logic               s4_both_zero_q, s4_nar_q;
    logic [3:0]         s4_flags_q;

    posit_add_lod_comb u_s4_lod (
        .magnitude      (s3_mag_q),
        .alignment_tail (s3_tail_q),
        .norm_seed      (s4_seed_d),
        .leading_count  (s4_count_d),
        .nonzero        (s4_nz_d),
        .sticky_raw     (s4_sticky_d)
    );

    //-------------------------------------------------------------------------
    // Stage S5: Parallel Left Shift, Scale Update, & Unified NaR/Zero Output
    //-------------------------------------------------------------------------
    wire               s5_sign_d, s5_zero_d, s5_nar_d, s5_sticky_d;
    wire signed [10:0] s5_sf_d;
    wire [28:0]        s5_frac_hi_d;
    wire [4:0]         s5_flags_d;

    logic [28:0] frac_hi_q;
    assign frac = {frac_hi_q, 24'b0}; // Pruned 24 constant-zero Flip-Flops

    posit_add_norm_comb u_s5_norm (
        .norm_seed     (s4_seed_q),
        .leading_count (s4_count_q),
        .nonzero       (s4_nz_q),
        .sign_base     (s4_sign_q),
        .sf_inc        (s4_sf_inc_q),
        .sticky_raw    (s4_sticky_q),
        .both_zero     (s4_both_zero_q),
        .is_nar_in     (s4_nar_q),
        .flags_lo      (s4_flags_q),
        .sign          (s5_sign_d),
        .is_zero       (s5_zero_d),
        .is_nar        (s5_nar_d),
        .sf            (s5_sf_d),
        .frac_hi       (s5_frac_hi_d),
        .sticky        (s5_sticky_d),
        .flags_out     (s5_flags_d)
    );

    //-------------------------------------------------------------------------
    // Unified Sequential Pipeline Registers (S1 -> S5)
    //-------------------------------------------------------------------------
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            valid_q        <= 5'b00000;

            // S1 Reset
            s1_x_frac_q    <= '0;
            s1_y_frac_q    <= '0;
            s1_shift_q     <= '0;
            s1_clamped_q   <= 1'b0;
            s1_both_nz_q   <= 1'b0;
            s1_sub_q       <= 1'b0;
            s1_sign_q      <= 1'b0;
            s1_sf_q        <= '0;
            s1_both_zero_q <= 1'b0;
            s1_nar_q       <= 1'b0;
            s1_flags_q     <= '0;

            // S2 Reset
            s2_x_frac_q    <= '0;
            s2_y_q         <= '0;
            s2_tail_q      <= 1'b0;
            s2_sub_q       <= 1'b0;
            s2_sign_q      <= 1'b0;
            s2_sf_q        <= '0;
            s2_both_zero_q <= 1'b0;
            s2_nar_q       <= 1'b0;
            s2_flags_q     <= '0;

            // S3 Reset
            s3_mag_q       <= '0;
            s3_sf_inc_q    <= '0;
            s3_tail_q      <= 1'b0;
            s3_sign_q      <= 1'b0;
            s3_both_zero_q <= 1'b0;
            s3_nar_q       <= 1'b0;
            s3_flags_q     <= '0;

            // S4 Reset
            s4_seed_q      <= '0;
            s4_count_q     <= '0;
            s4_nz_q        <= 1'b0;
            s4_sticky_q    <= 1'b0;
            s4_sf_inc_q    <= '0;
            s4_sign_q      <= 1'b0;
            s4_both_zero_q <= 1'b0;
            s4_nar_q       <= 1'b0;
            s4_flags_q     <= '0;

            // S5 Output Reset
            sign           <= 1'b0;
            is_zero        <= 1'b0;
            is_nar         <= 1'b0;
            sf             <= '0;
            frac_hi_q      <= '0;
            sticky         <= 1'b0;
            flags_out      <= '0;
        end else begin
            // S1 Capture
            if (ready0) begin
                valid_q[0] <= `CK2Q in_valid;
                if (in_valid) begin
                    s1_x_frac_q    <= `CK2Q s1_x_frac_d;
                    s1_y_frac_q    <= `CK2Q s1_y_frac_d;
                    s1_shift_q     <= `CK2Q s1_shift_d;
                    s1_clamped_q   <= `CK2Q s1_clamped_d;
                    s1_both_nz_q   <= `CK2Q s1_both_nz_d;
                    s1_sub_q       <= `CK2Q s1_sub_d;
                    s1_sign_q      <= `CK2Q s1_sign_d;
                    s1_sf_q        <= `CK2Q s1_sf_d;
                    s1_both_zero_q <= `CK2Q s1_both_zero_d;
                    s1_nar_q       <= `CK2Q s1_nar_d;
                    s1_flags_q     <= `CK2Q s1_flags_d;
                end
            end

            // S2 Capture
            if (ready1) begin
                valid_q[1] <= `CK2Q valid_q[0];
                if (valid_q[0]) begin
                    s2_x_frac_q    <= `CK2Q s1_x_frac_q;
                    s2_y_q         <= `CK2Q s2_y_d;
                    s2_tail_q      <= `CK2Q s2_tail_d;
                    s2_sub_q       <= `CK2Q s1_sub_q;
                    s2_sign_q      <= `CK2Q s1_sign_q;
                    s2_sf_q        <= `CK2Q s1_sf_q;
                    s2_both_zero_q <= `CK2Q s1_both_zero_q;
                    s2_nar_q       <= `CK2Q s1_nar_q;
                    s2_flags_q     <= `CK2Q s1_flags_q;
                end
            end

            // S3 Capture
            if (ready2) begin
                valid_q[2] <= `CK2Q valid_q[1];
                if (valid_q[1]) begin
                    s3_mag_q       <= `CK2Q s3_mag_d;
                    s3_sf_inc_q    <= `CK2Q s3_sf_inc_d;
                    s3_tail_q      <= `CK2Q s2_tail_q;
                    s3_sign_q      <= `CK2Q s2_sign_q;
                    s3_both_zero_q <= `CK2Q s2_both_zero_q;
                    s3_nar_q       <= `CK2Q s2_nar_q;
                    s3_flags_q     <= `CK2Q s2_flags_q;
                end
            end

            // S4 Capture
            if (ready3) begin
                valid_q[3] <= `CK2Q valid_q[2];
                if (valid_q[2]) begin
                    s4_seed_q      <= `CK2Q s4_seed_d;
                    s4_count_q     <= `CK2Q s4_count_d;
                    s4_nz_q        <= `CK2Q s4_nz_d;
                    s4_sticky_q    <= `CK2Q s4_sticky_d;
                    s4_sf_inc_q    <= `CK2Q s3_sf_inc_q;
                    s4_sign_q      <= `CK2Q s3_sign_q;
                    s4_both_zero_q <= `CK2Q s3_both_zero_q;
                    s4_nar_q       <= `CK2Q s3_nar_q;
                    s4_flags_q     <= `CK2Q s3_flags_q;
                end
            end

            // S5 Output Capture
            if (ready4) begin
                valid_q[4] <= `CK2Q valid_q[3];
                if (valid_q[3]) begin
                    sign      <= `CK2Q s5_sign_d;
                    is_zero   <= `CK2Q s5_zero_d;
                    is_nar    <= `CK2Q s5_nar_d;
                    sf        <= `CK2Q s5_sf_d;
                    frac_hi_q <= `CK2Q s5_frac_hi_d;
                    sticky    <= `CK2Q s5_sticky_d;
                    flags_out <= `CK2Q s5_flags_d;
                end
            end
        end
    end

endmodule
//-----------------------------------------------------------------------------
// End of posit_add.sv
//-----------------------------------------------------------------------------
