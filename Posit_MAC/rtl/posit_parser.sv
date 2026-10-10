//-----------------------------------------------------------------------------
// File          : posit_parser.sv
// Author(s)     : Dan Huy
// Email         :
// Project       : Posit MAC IP
// Creation Date : 2026-10-05
// Description   : Two-stage elastic Posit parser.
//                 P1: magnitude, regime detectors and selected count.
//                 P2: signed regime, payload alignment and field extraction.
//                 reset_n asserts asynchronously and releases through two FFs.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.1 $
// $Log: 2026-10-06: register cnt/FRB, reconstruct regime in P2 (Fig.5a). $

`include "posit_mac.vh"

module posit_parser #(
    parameter int NB       = 32,
    parameter int ES       = 2,
    parameter int FRAC_MAX = NB - 3 - ES,
    parameter int SF_W     = $clog2(64'd4 * (longint'(NB) - 64'd2) * (64'd1 << ES) + 64'd4) + 1
)(
    input  logic                    clk,
    input  logic                    reset_n,
    input  logic                    in_valid,
    output wire                     in_ready,
    input  logic [NB-1:0]           p,
    output wire                     out_valid,
    input  logic                    out_ready,
    output wire                     s,
    output wire                     is_zero,
    output wire                     is_nar,
    output wire signed [SF_W-1:0]   sf,
    output wire [FRAC_MAX-1:0]      frac
);

    localparam int CNT_W = $clog2(NB - 1);
    localparam int REG_W = CNT_W + 1;
    typedef logic [CNT_W-1:0] count_value_t;
    localparam logic [CNT_W-1:0] MAX_COUNT = count_value_t'(NB-2);

    // Reset synchronizer: no combinational logic before the first FF.
    (* ASYNC_REG = "TRUE" *) logic meta_sync1;
    (* ASYNC_REG = "TRUE" *) logic meta_sync2;
    typedef logic signed [SF_W-1:0] sf_value_t;
    wire reset_b_sync_clk;

    wire [NB-1:0] magnitude;
    wire [NB-3:0] regime_tail;
    wire [NB-4:0] payload_seed;
    wire first_regime_bit;
    wire [CNT_W-1:0] lod_count;
    wire [CNT_W-1:0] lzd_count;
    wire lod_valid;
    wire lzd_valid;

    logic [CNT_W-1:0] cnt_d;
    wire s_d;
    wire is_zero_d;
    wire is_nar_d;

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
    wire signed [SF_W-1:0] finite_sf;
    wire signed [SF_W-1:0] sf_d;
    wire [FRAC_MAX-1:0] frac_d;

    // P2 registers: one output slot, held until downstream handshake.
    logic p2_valid_q;
    logic p2_s_q;
    logic p2_is_zero_q;
    logic p2_is_nar_q;
    logic signed [SF_W-1:0] p2_sf_q;
    logic [FRAC_MAX-1:0] p2_frac_q;

    wire p1_ready;
    wire p2_ready;

    generate
        if (NB < 4 || NB > 32 || ES < 0 || ES > NB - 4 ||
            FRAC_MAX != NB - 3 - ES || SF_W < REG_W + ES) begin : g_invalid
            initial $fatal(1, "posit_parser: unsupported parameters");
        end
    endgenerate

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
    assign s_d       = p[NB-1];
    assign is_zero_d = (p == {NB{1'b0}});
    assign is_nar_d  = (p == {1'b1, {(NB-1){1'b0}}});

    assign magnitude = s_d
                     ? (~p + {{(NB-1){1'b0}}, 1'b1})
                     : p;

    assign first_regime_bit = magnitude[NB-2];
    assign regime_tail      = magnitude[NB-3:0];
    assign payload_seed     = magnitude[NB-4:0];

    lod_lzd_core #(
        .N    (NB - 2),
        .MODE (0),
        .S    (CNT_W)
    ) u_lod (
        .in  (regime_tail),
        .K   (lod_count),
        .vld (lod_valid)
    );

    lod_lzd_core #(
        .N    (NB - 2),
        .MODE (1),
        .S    (CNT_W)
    ) u_lzd (
        .in  (regime_tail),
        .K   (lzd_count),
        .vld (lzd_valid)
    );

    always_comb begin
        // Invalid selected detector means the entire tail matches the regime.
        cnt_d = MAX_COUNT;

        if (first_regime_bit) begin
            if (lzd_valid) begin
                cnt_d = lzd_count;
            end
        end else begin
            if (lod_valid) begin
                cnt_d = lod_count;
            end
        end
    end

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
            p1_valid_q        <= 1'b0;
            p1_s_q            <= 1'b0;
            p1_is_zero_q      <= 1'b0;
            p1_is_nar_q       <= 1'b0;
            p1_cnt_q          <= '0;
            p1_first_regime_bit_q <= 1'b0;
            p1_payload_seed_q <= '0;
        end else if (p1_ready) begin
            p1_valid_q <= `CK2Q in_valid;

            if (in_valid) begin
                p1_s_q            <= `CK2Q s_d;
                p1_is_zero_q      <= `CK2Q is_zero_d;
                p1_is_nar_q       <= `CK2Q is_nar_d;
                p1_cnt_q          <= `CK2Q cnt_d;
                p1_first_regime_bit_q <= `CK2Q first_regime_bit;
                p1_payload_seed_q <= `CK2Q payload_seed;
            end
        end
    end

    //=========================================================================
    // P2 combinational logic: reconstruct k in parallel with payload alignment.
    //=========================================================================
    // r=1: k=cnt. r=0: k=-(cnt+1). Keep k signed for sign extension.
    // Registering FRB instead of REG_W-bit k saves CNT_W register bits in P1.
    assign regime = ~({1'b0, p1_cnt_q} ^ {REG_W{p1_first_regime_bit_q}});

    dyn_left_shifter #(
        .N       (NB - 3),
        .SHIFT_W (CNT_W)
    ) u_align_payload (
        .in  (p1_payload_seed_q),
        .b   (p1_cnt_q),
        .out (payload)
    );

    generate
        if (ES == 0) begin : g_es0
            assign finite_sf = sf_value_t'(regime);
        end else begin : g_exponent
            wire [ES-1:0] exponent;

            assign exponent  = payload[NB-4 -: ES];
            assign finite_sf = sf_value_t'($signed({regime, exponent}));
        end
    endgenerate

    assign sf_d = (p1_is_zero_q || p1_is_nar_q)
                ? {SF_W{1'b0}}
                : finite_sf;

    assign frac_d = (p1_is_zero_q || p1_is_nar_q)
                  ? {FRAC_MAX{1'b0}}
                  : payload[FRAC_MAX-1:0];

    //=========================================================================
    // P2 register bank, immediately after payload alignment.
    //=========================================================================
    always_ff @(posedge clk or negedge reset_b_sync_clk) begin
        if (!reset_b_sync_clk) begin
            p2_valid_q   <= 1'b0;
            p2_s_q       <= 1'b0;
            p2_is_zero_q <= 1'b0;
            p2_is_nar_q  <= 1'b0;
            p2_sf_q      <= '0;
            p2_frac_q    <= '0;
        end else if (p2_ready) begin
            p2_valid_q <= `CK2Q p1_valid_q;

            if (p1_valid_q) begin
                p2_s_q       <= `CK2Q p1_s_q;
                p2_is_zero_q <= `CK2Q p1_is_zero_q;
                p2_is_nar_q  <= `CK2Q p1_is_nar_q;
                p2_sf_q      <= `CK2Q sf_d;
                p2_frac_q    <= `CK2Q frac_d;
            end
        end
    end

    assign s       = p2_s_q;
    assign is_zero = p2_is_zero_q;
    assign is_nar  = p2_is_nar_q;
    assign sf      = p2_sf_q;
    assign frac    = p2_frac_q;

endmodule

//-----------------------------------------------------------------------------
// End of posit_parser.sv
//-----------------------------------------------------------------------------
