//-----------------------------------------------------------------------------
// File          : tb_posit_add_5stage_equiv.sv
// Author(s)     : Verification Suite
// Project       : Posit MAC IP
// Description   : Bit-exact equivalence & elastic protocol checker comparing
//                 consolidated 5-stage posit_add against golden posit_add_comb.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module tb_posit_add_5stage_equiv;
    logic               clk = 1'b0;
    logic               reset_n = 1'b0;
    logic               in_valid = 1'b0;
    wire                in_ready;
    wire                out_valid;
    logic               out_ready = 1'b0;

    logic               a_sign = 1'b0, a_is_zero = 1'b0, a_is_nar = 1'b0;
    logic signed [10:0] a_sf = 11'sd0;
    logic [25:0]        a_frac = 26'd0;
    logic               b_sign = 1'b0, b_is_zero = 1'b0, b_is_nar = 1'b0;
    logic signed [10:0] b_sf = 11'sd0;
    logic [25:0]        b_frac = 26'd0;
    logic [4:0]         flags_in = 5'd0;

    // DUT outputs
    wire                dut_sign, dut_zero, dut_nar, dut_sticky;
    wire signed [10:0]  dut_sf;
    wire [52:0]         dut_frac;
    wire [4:0]          dut_flags;

    // Golden combinational reference outputs
    wire                ref_sign, ref_zero, ref_nar, ref_sticky;
    wire signed [10:0]  ref_sf;
    wire [52:0]         ref_frac;
    wire [4:0]          ref_flags;

    always #5 clk = ~clk;

    posit_add dut (
        .clk       (clk),
        .reset_n   (reset_n),
        .in_valid  (in_valid),
        .in_ready  (in_ready),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .a_sign    (a_sign),
        .a_is_zero (a_is_zero),
        .a_is_nar  (a_is_nar),
        .a_sf      (a_sf),
        .a_frac    (a_frac),
        .b_sign    (b_sign),
        .b_is_zero (b_is_zero),
        .b_is_nar  (b_is_nar),
        .b_sf      (b_sf),
        .b_frac    (b_frac),
        .flags_in  (flags_in),
        .sign      (dut_sign),
        .is_zero   (dut_zero),
        .is_nar    (dut_nar),
        .sf        (dut_sf),
        .frac      (dut_frac),
        .sticky    (dut_sticky),
        .flags_out (dut_flags)
    );

    posit_add_comb u_golden (
        .a_sign    (a_sign),
        .a_is_zero (a_is_zero),
        .a_is_nar  (a_is_nar),
        .a_sf      (a_sf),
        .a_frac    (a_frac),
        .b_sign    (b_sign),
        .b_is_zero (b_is_zero),
        .b_is_nar  (b_is_nar),
        .b_sf      (b_sf),
        .b_frac    (b_frac),
        .flags_in  (flags_in),
        .sign      (ref_sign),
        .is_zero   (ref_zero),
        .is_nar    (ref_nar),
        .sf        (ref_sf),
        .frac      (ref_frac),
        .sticky    (ref_sticky),
        .flags_out (ref_flags)
    );

    localparam int PAYLOAD_W = 1 + 1 + 1 + 11 + 53 + 1 + 5; // 73 bits
    logic [PAYLOAD_W-1:0] exp_fifo [0:31];
    int wr_ptr = 0, rd_ptr = 0, fifo_cnt = 0;
    int accepted = 0, completed = 0, aborted = 0, errors = 0, stall_checks = 0;

    wire [PAYLOAD_W-1:0] ref_bundle = {ref_sign, ref_zero, ref_nar, ref_sf, ref_frac, ref_sticky, ref_flags};
    wire [PAYLOAD_W-1:0] dut_bundle = {dut_sign, dut_zero, dut_nar, dut_sf, dut_frac, dut_sticky, dut_flags};

    logic                 prev_stalled = 1'b0;
    logic [PAYLOAD_W-1:0] prev_dut_bundle = '0;

    // Scoreboard & elastic stability monitor
    always @(posedge clk) begin
        if (!reset_n) begin
            aborted = aborted + fifo_cnt;
            wr_ptr       <= 0;
            rd_ptr       <= 0;
            fifo_cnt     <= 0;
            prev_stalled <= 1'b0;
        end else begin
            if (prev_stalled) begin
                stall_checks <= stall_checks + 1;
                if (!out_valid || (dut_bundle !== prev_dut_bundle)) begin
                    $display("[ERROR] Elastic stall violation at time %0t!", $time);
                    errors <= errors + 1;
                end
            end

            prev_stalled    <= (out_valid && !out_ready);
            prev_dut_bundle <= dut_bundle;

            if (in_valid && in_ready) begin
                if (fifo_cnt >= 32) $fatal(1,"scoreboard overflow");
                exp_fifo[wr_ptr] <= ref_bundle;
                wr_ptr           <= (wr_ptr + 1) & 31;
                accepted         <= accepted + 1;
            end

            if (out_valid && out_ready) begin
                if (fifo_cnt == 0) $fatal(1,"unexpected/duplicate output");
                if (dut_bundle !== exp_fifo[rd_ptr]) begin
                    $display("[MISMATCH] #%0d: got=%h exp=%h", completed, dut_bundle, exp_fifo[rd_ptr]);
                    $display("  DUT: sign=%b zero=%b nar=%b sf=%0d frac=%h sticky=%b flags=%b",
                             dut_sign, dut_zero, dut_nar, dut_sf, dut_frac, dut_sticky, dut_flags);
                    $fatal(1,"adder data/metadata mismatch");
                end
                rd_ptr    <= (rd_ptr + 1) & 31;
                completed <= completed + 1;
            end

            case ({in_valid && in_ready, out_valid && out_ready})
                2'b10: fifo_cnt <= fifo_cnt + 1;
                2'b01: fifo_cnt <= fifo_cnt - 1;
                default: ;
            endcase
        end
    end

    logic [31:0] rng = 32'hCAFE_BABE;
    function automatic logic [31:0] next_rng();
        rng = {rng[30:0], rng[31] ^ rng[21] ^ rng[1] ^ rng[0]};
        return rng;
    endfunction

    task automatic push_vec(
        input logic as, az, an, input logic signed [10:0] asf, input logic [25:0] af,
        input logic bs, bz, bn, input logic signed [10:0] bsf, input logic [25:0] bf,
        input logic [4:0] flg, input logic rdy
    );
        @(negedge clk);
        in_valid  = 1'b1;
        out_ready = rdy;
        a_sign    = as; a_is_zero = az; a_is_nar = an; a_sf = asf; a_frac = af;
        b_sign    = bs; b_is_zero = bz; b_is_nar = bn; b_sf = bsf; b_frac = bf;
        flags_in  = flg;
        @(posedge clk);
        while (!in_ready) begin
            @(negedge clk);
            out_ready = 1'b1;
            @(posedge clk);
        end
    endtask

    initial begin
        reset_n   = 1'b0;
        in_valid  = 1'b0;
        out_ready = 1'b1;
        #25;
        @(negedge clk);
        reset_n = 1'b1;
        repeat (4) @(posedge clk);

        // 1. Directed Corner Cases: All shifts s = 0..32, carry/jam, cancellation, NaR/Zero
        for (int s = 0; s <= 32; s++) begin
            // Same sign (addition, carry/jam boundary)
            push_vec(1'b0, 1'b0, 1'b0, 11'sd20, 26'h3FF_FFFF,
                     1'b0, 1'b0, 1'b0, 11'sd20 - s[10:0], 26'h3FF_FFFF, 5'b00001, 1'b1);
            // Opposite sign (subtraction, borrow/LZD cancellation boundary)
            push_vec(1'b0, 1'b0, 1'b0, 11'sd20, 26'h200_0001,
                     1'b1, 1'b0, 1'b0, 11'sd20 - s[10:0], 26'h3FF_FFFF, 5'b00010, 1'b1);
            // Swapped order (A < B)
            push_vec(1'b1, 1'b0, 1'b0, -11'sd15 - s[10:0], 26'h155_5555,
                     1'b0, 1'b0, 1'b0, -11'sd15, 26'h2AA_AAAA, 5'b01100, 1'b1);
        end

        // Exact & single-bit cancellation across all 26 bit positions
        for (int b = 0; b < 26; b++) begin
            push_vec(1'b0, 1'b0, 1'b0, 11'sd5, (26'd1 << b),
                     1'b1, 1'b0, 1'b0, 11'sd5, 26'd0, 5'b00000, 1'b1);
            push_vec(1'b1, 1'b0, 1'b0, -11'sd5, (26'd1 << b),
                     1'b0, 1'b0, 1'b0, -11'sd5, (26'd1 << b), 5'b00011, 1'b1);
        end

        // Special cases: NaR, flags_in[4], Zero combinations
        for (int f = 0; f < 32; f++) begin
            push_vec(1'b0, 1'b1, 1'b0, 11'sd0, 26'd0,
                     1'b1, 1'b1, 1'b0, 11'sd0, 26'd0, f[4:0], 1'b1);
            push_vec(1'b0, 1'b0, 1'b1, 11'sd10, 26'h123456,
                     1'b0, 1'b0, 1'b0, 11'sd5,  26'h654321, f[4:0], 1'b1);
            push_vec(1'b1, 1'b1, 1'b0, 11'sd0,  26'd0,
                     1'b1, 1'b0, 1'b0, -11'sd40, 26'h3ABCDE, f[4:0], 1'b1);
        end

        // 2. 50,000 Random Stress Transactions with Random Elastic Backpressure & Bubbles
        for (int i = 0; i < 50000; i++) begin
            logic [31:0] r0, r1, r2, r3;
            r0 = next_rng();
            r1 = next_rng();
            r2 = next_rng();
            r3 = next_rng();

            @(negedge clk);
            in_valid  = (r0[1:0] != 2'b00); // 75% valid, 25% bubbles
            out_ready = (r0[3:2] != 2'b00); // 75% ready, 25% backpressure stalls

            a_sign    = r0[4];
            a_is_zero = (r0[8:5] == 4'd0);
            a_is_nar  = (!a_is_zero) && (r0[13:9] == 5'd0);
            a_sf      = a_is_zero || a_is_nar ? 11'sd0
                      : (r0[14] ? $signed(r1[8:0]) : $signed({{6{r1[4]}}, r1[4:0]}));
            a_frac    = (a_is_zero || a_is_nar) ? 26'd0 : r1[25:0];

            b_sign    = r0[15];
            b_is_zero = (r0[19:16] == 4'd0);
            b_is_nar  = (!b_is_zero) && (r0[24:20] == 5'd0);
            b_sf      = b_is_zero || b_is_nar ? 11'sd0
                      : (r0[25] ? $signed(r2[8:0]) : (a_sf + $signed({{6{r2[4]}}, r2[4:0]})));
            b_frac    = (b_is_zero || b_is_nar) ? 26'd0 : r2[25:0];
            flags_in  = (r3[7:5] == 3'b111) ? r3[4:0] : {1'b0, r3[3:0]};

            @(posedge clk);
            // Hold stimulus stable if valid && !in_ready (AXI-Stream rule)
            while (in_valid && !in_ready) begin
                r3 = next_rng();
                @(negedge clk);
                out_ready = (r3[0] == 1'b1);
                @(posedge clk);
            end
        end

        // Drain pipeline
        @(negedge clk);
        in_valid  = 1'b0;
        out_ready = 1'b1;
        repeat (15) @(posedge clk);

        // 3. Mid-flight async reset recovery test
        push_vec(1'b0, 1'b0, 1'b0, 11'sd3, 26'h111111,
                 1'b0, 1'b0, 1'b0, 11'sd2, 26'h222222, 5'b00000, 1'b0);
        @(negedge clk);
        in_valid = 1'b0;
        reset_n  = 1'b0;
        #17;
        @(negedge clk);
        reset_n   = 1'b1;
        out_ready = 1'b1;
        repeat (4) @(posedge clk);
        push_vec(1'b0, 1'b0, 1'b0, 11'sd12, 26'h100_0000,
                 1'b0, 1'b0, 1'b0, 11'sd12, 26'h100_0000, 5'b00000, 1'b1);
        @(negedge clk);
        in_valid = 1'b0;
        repeat (10) @(posedge clk);

        if (fifo_cnt != 0) begin
            $display("[ERROR] Drain incomplete: fifo_cnt = %0d", fifo_cnt);
            errors = errors + 1;
        end

        $display("=============================================================");
        $display("  5-Stage Posit Adder Equivalence Summary:");
        $display("  Accepted: %0d | Completed: %0d | Stall Checks: %0d | Errors: %0d",
                 accepted, completed, stall_checks, errors);
        if (errors == 0 && completed > 35000 && accepted == completed + aborted && stall_checks > 0) begin
            $display("ADDER_REFACTOR_PASS accepted=%0d completed=%0d aborted=%0d stalls=%0d",accepted,completed,aborted,stall_checks);
            $display("  STATUS: PASS (100%% Bit-Exact & Elastic Protocol Verified!)");
        end else begin
            $fatal(1,"adder acceptance/count/protocol failure");
        end
        $display("=============================================================");
        $finish;
    end
    initial begin
        #10000000;
        $fatal(1,"adder watchdog timeout");
    end
endmodule

