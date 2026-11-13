//-----------------------------------------------------------------------------
// File          : posit_parser_mul.sv
// Author(s)     : Dan Huy
// Email         :
// Project       : Posit MAC IP
// Creation Date : 2026-11-04
// Description   : Two-stage elastic Posit(32,3) parser shared by NF/F.
//                 A/B use the upper fraction and tail_cut for multiplication.
//                 C uses both fraction slices for full-precision addition.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: 2026-11-04: Unified P1 + 12-bit P2 fraction + 1-bit tail_cut. $
//-----------------------------------------------------------------------------

`include "posit_mac.vh"

module posit_parser_mul (
    input  logic                    clk,
    input  logic                    reset_n,
    input  logic                    in_valid,
    output wire                     in_ready,
    input  logic [31:0]             p,
    output wire                     out_valid,
    input  logic                    out_ready,
    output wire                     s,
    output wire                     is_zero,
    output wire                     is_nar,
    output wire signed [10:0]       sf,
    output wire [11:0]              frac,
    output wire [13:0]              frac_lo,
    output wire                     tail_cut
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    localparam int NB = 32;
    localparam int ES = 3;
    localparam int FRAC_MAX = 26;
    localparam int FRAC_OUT_W = 12;
    localparam int TAIL_W = FRAC_MAX - FRAC_OUT_W; // 14
    localparam int SF_W = 11;

    localparam int CNT_W = 5; // $clog2(NB - 1)
    localparam int REG_W = 6; // CNT_W + 1

    // Reset synchronizer: no combinational logic before the first FF.
    (* ASYNC_REG = "TRUE" *) logic meta_sync1;
    (* ASYNC_REG = "TRUE" *) logic meta_sync2;
    wire reset_b_sync_clk;

    wire [NB-1:0] magnitude;
    wire [NB-4:0] payload_seed;
    wire first_regime_bit;
    wire [NB-3:0] terminator_bits;
    wire unused_terminator_valid;
    wire [NB-2:0] detector_in;

    logic [CNT_W-1:0] cnt_d;
    wire s_d;
    wire is_zero_d;
    wire is_nar_d;
    wire rest_is_zero_d;

    // P1 registers: metadata must stall together with count and payload seed.
    logic p1_valid_q;
    logic p1_s_q;
    logic p1_is_zero_q;
    logic p1_is_nar_q;
    logic [CNT_W-1:0] p1_cnt_q;
    logic p1_first_regime_bit_q;
    logic [NB-4:0] p1_payload_seed_q;

    wire [NB-4:0] payload;
    wire signed [REG_W-1:0] regime;
    wire signed [7:0] finite_regime;
    wire signed [SF_W-1:0] sf_d;
    wire [FRAC_OUT_W-1:0] frac_d;
    wire [TAIL_W-1:0] frac_lo_d;
    wire tail_cut_d;

    // P2 registers: one output slot, held until downstream handshake.
    // Independent outputs let synthesis trim the fields not consumed by each instance.
    logic p2_valid_q;
    logic p2_s_q;
    logic p2_is_zero_q;
    logic p2_is_nar_q;
    logic signed [SF_W-1:0] p2_sf_q;
    logic [FRAC_OUT_W-1:0] p2_frac_q;
    logic [TAIL_W-1:0] p2_frac_lo_q;
    logic p2_tail_cut_q;

    wire p1_ready;
    wire p2_ready;

    //=========================================================================
    // Reset: asynchronous assertion, synchronous release after two clk edges.
    //=========================================================================
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end

    assign reset_b_sync_clk = meta_sync2;

    //=========================================================================
    // P1 combinational logic: decode magnitude and select regime count.
    //=========================================================================
    assign s_d            = p[NB-1];
    assign rest_is_zero_d = ~(|p[NB-2:0]);
    assign is_zero_d      = !s_d && rest_is_zero_d;
    assign is_nar_d       =  s_d && rest_is_zero_d;

    // Carry magnitude retains Artix-7 dedicated carry resources.
    assign magnitude = (p ^ {NB{s_d}})
                     + {{(NB-1){1'b0}}, s_d};

    assign first_regime_bit = magnitude[NB-2];
    assign payload_seed     = magnitude[NB-4:0];

    // Adjacent XOR marks transitions; the first one is the terminator.
    // The payload path uses the original magnitude, never terminator_bits.
    assign terminator_bits = magnitude[NB-3:0] ^ magnitude[NB-2:1];

    // Sentinel supplies the no-terminator count NB-2.
    assign detector_in = {terminator_bits, 1'b1};

    posit_parser_f_regime_lod u_regime_detector (
        .in  (detector_in),
        .K   (cnt_d),
        .vld (unused_terminator_valid)
    );

    // Empty slots may refill; occupied slots advance only if the next is ready.
    assign p2_ready = !p2_valid_q || out_ready;
    assign p1_ready = !p1_valid_q || p2_ready;
    assign in_ready = reset_b_sync_clk && p1_ready;
    assign out_valid = reset_b_sync_clk && p2_valid_q;

    //=========================================================================
    // P1 register bank, immediately after regime selection.
    //=========================================================================
    always_ff @(posedge clk or negedge reset_b_sync_clk) begin
        if (!reset_b_sync_clk) begin
            p1_valid_q            <= 1'b0;
            p1_s_q                <= 1'b0;
            p1_is_zero_q          <= 1'b0;
            p1_is_nar_q           <= 1'b0;
            p1_cnt_q              <= '0;
            p1_first_regime_bit_q <= 1'b0;
            p1_payload_seed_q     <= '0;
        end else if (p1_ready) begin
            p1_valid_q <= `CK2Q in_valid;

            if (in_valid) begin
                p1_s_q                <= `CK2Q s_d;
                p1_is_zero_q          <= `CK2Q is_zero_d;
                p1_is_nar_q           <= `CK2Q is_nar_d;
                p1_cnt_q              <= `CK2Q cnt_d;
                p1_first_regime_bit_q <= `CK2Q first_regime_bit;
                p1_payload_seed_q     <= `CK2Q payload_seed;
            end
        end
    end

    //=========================================================================
    // P2 combinational logic: reconstruct k in parallel with payload alignment.
    //=========================================================================
    wire special_p1 = p1_is_zero_q | p1_is_nar_q;
    assign regime   = ~({1'b0, p1_cnt_q} ^ {REG_W{p1_first_regime_bit_q}});

    dyn_left_shifter u_align_payload (
        .in  (p1_payload_seed_q),
        .b   (p1_cnt_q),
        .out (payload)
    );

    wire [ES-1:0] exponent;

    assign exponent      = payload[NB-4 -: ES];
    assign finite_regime = {{2{regime[5]}}, regime};

    assign sf_d       = $signed({special_p1 ? 8'd0 : finite_regime, exponent});
    assign frac_d     = payload[FRAC_MAX-1 -: FRAC_OUT_W];
    assign frac_lo_d  = payload[TAIL_W-1:0];
    assign tail_cut_d = |frac_lo_d;

    //=========================================================================
    // P2 register bank, immediately after payload alignment.
    //=========================================================================
    always_ff @(posedge clk or negedge reset_b_sync_clk) begin
        if (!reset_b_sync_clk) begin
            p2_valid_q    <= 1'b0;
            p2_s_q        <= 1'b0;
            p2_is_zero_q  <= 1'b0;
            p2_is_nar_q   <= 1'b0;
            p2_sf_q       <= '0;
            p2_frac_q     <= '0;
            p2_frac_lo_q  <= '0;
            p2_tail_cut_q <= 1'b0;
        end else if (p2_ready) begin
            p2_valid_q <= `CK2Q p1_valid_q;

            if (p1_valid_q) begin
                p2_s_q        <= `CK2Q p1_s_q;
                p2_is_zero_q  <= `CK2Q p1_is_zero_q;
                p2_is_nar_q   <= `CK2Q p1_is_nar_q;
                p2_sf_q       <= `CK2Q sf_d;
                p2_frac_q     <= `CK2Q frac_d;
                p2_frac_lo_q  <= `CK2Q frac_lo_d;
                p2_tail_cut_q <= `CK2Q tail_cut_d;
            end
        end
    end

    assign s        = p2_s_q;
    assign is_zero  = p2_is_zero_q;
    assign is_nar   = p2_is_nar_q;
    assign sf       = p2_sf_q;
    assign frac     = p2_frac_q;
    assign frac_lo  = p2_frac_lo_q;
    assign tail_cut = p2_tail_cut_q;

endmodule

//-----------------------------------------------------------------------------
// End of posit_parser_mul.sv
//-----------------------------------------------------------------------------

