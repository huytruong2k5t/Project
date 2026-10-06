//-----------------------------------------------------------------------------
// File          : tb_dyn_right_shifter.sv
// Author(s)     : Dan Huy
// Email         : 
// Project       : Posit MAC IP (Approximate & Iterative Posit MAC)
// Creation Date : 2026-10-02
//
// Description   : Comprehensive self-checking unit testbench for dyn_right_shifter.
//                 - Suite 1: Exhaustive verification on N=8 (Logical & Arithmetic)
//                 - Suite 2: Corner & boundary tests on N=32 (shifts 0..63)
//                 - Suite 3: Non-power-of-2 verification on N=27 (Posit32 mantissa)
//                 - Suite 4: Randomized stress tests (20,000 vectors)
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_dyn_right_shifter;

    int total_tests = 0;
    int error_count = 0;

    //=========================================================================
    // Test Suite 1: Exhaustive verification for N=8, SHIFT_W=4
    //=========================================================================
    localparam int N1       = 8;
    localparam int SHIFT_W1 = 4;

    logic [N1-1:0]       in_1;
    logic [SHIFT_W1-1:0] b_1;
    logic                fill_val_1;

    logic [N1-1:0]       out_1_logical;
    logic [N1-1:0]       out_1_arith;
    logic [N1-1:0]       out_1_custom;

    // Instance 1A: Logical right shift (fill 0)
    dyn_right_shifter #(
        .N       (N1),
        .SHIFT_W (SHIFT_W1),
        .ARITH   (1'b0)
    ) dut_1_logical (
        .in       (in_1),
        .b        (b_1),
        .fill_val (1'b0),
        .out      (out_1_logical)
    );

    // Instance 1B: Arithmetic right shift (sign extension)
    dyn_right_shifter #(
        .N       (N1),
        .SHIFT_W (SHIFT_W1),
        .ARITH   (1'b1)
    ) dut_1_arith (
        .in       (in_1),
        .b        (b_1),
        .fill_val (1'b0),
        .out      (out_1_arith)
    );

    // Instance 1C: Custom fill right shift (fill_val = 1)
    dyn_right_shifter #(
        .N       (N1),
        .SHIFT_W (SHIFT_W1),
        .ARITH   (1'b0)
    ) dut_1_custom (
        .in       (in_1),
        .b        (b_1),
        .fill_val (fill_val_1),
        .out      (out_1_custom)
    );

    //=========================================================================
    // Test Suite 2 & 4: N=32, SHIFT_W=6
    //=========================================================================
    localparam int N2       = 32;
    localparam int SHIFT_W2 = 6;

    logic [N2-1:0]       in_2;
    logic [SHIFT_W2-1:0] b_2;
    logic                fill_val_2;

    logic [N2-1:0]       out_2_logical;
    logic [N2-1:0]       out_2_arith;
    logic [N2-1:0]       out_2_custom;

    dyn_right_shifter #(
        .N       (N2),
        .SHIFT_W (SHIFT_W2),
        .ARITH   (1'b0)
    ) dut_2_logical (
        .in       (in_2),
        .b        (b_2),
        .fill_val (1'b0),
        .out      (out_2_logical)
    );

    dyn_right_shifter #(
        .N       (N2),
        .SHIFT_W (SHIFT_W2),
        .ARITH   (1'b1)
    ) dut_2_arith (
        .in       (in_2),
        .b        (b_2),
        .fill_val (1'b0),
        .out      (out_2_arith)
    );

    dyn_right_shifter #(
        .N       (N2),
        .SHIFT_W (SHIFT_W2),
        .ARITH   (1'b0)
    ) dut_2_custom (
        .in       (in_2),
        .b        (b_2),
        .fill_val (fill_val_2),
        .out      (out_2_custom)
    );

    //=========================================================================
    // Test Suite 3: N=27 (Posit32 mantissa), SHIFT_W=5
    //=========================================================================
    localparam int N3       = 27;
    localparam int SHIFT_W3 = 5;

    logic [N3-1:0]       in_3;
    logic [SHIFT_W3-1:0] b_3;
    logic                fill_val_3;
    logic [N3-1:0]       out_3;

    dyn_right_shifter #(
        .N       (N3),
        .SHIFT_W (SHIFT_W3),
        .ARITH   (1'b0)
    ) dut_3 (
        .in       (in_3),
        .b        (b_3),
        .fill_val (fill_val_3),
        .out      (out_3)
    );

    //=========================================================================
    // Helper function for Golden Model
    //=========================================================================
    function automatic [31:0] calc_exp_right_shift(
        input [31:0] val,
        input int    shift_amt,
        input int    width,
        input logic  fill_bit
    );
        logic [31:0] res;
        logic [31:0] mask;
        mask = (width == 32) ? 32'hFFFF_FFFF : ((1 << width) - 1);

        if (shift_amt >= width) begin
            res = fill_bit ? mask : 32'h0;
        end else begin
            logic [31:0] shifted;
            logic [31:0] fill_extension;
            shifted = (val & mask) >> shift_amt;
            if (fill_bit && (shift_amt > 0)) begin
                fill_extension = (((1 << shift_amt) - 1) << (width - shift_amt)) & mask;
            end else begin
                fill_extension = 32'h0;
            end
            res = (shifted | fill_extension) & mask;
        end
        return res;
    endfunction

    //=========================================================================
    // Main Test Sequence
    //=========================================================================
    initial begin
        int seed;
        int seeded;
        if (!$value$plusargs("SEED=%d", seed)) seed = 20261004;
        $display("PRNG seed=%0d", seed);
        seeded = $urandom(seed);
        $display("==================================================================");
        $display("   STARTING UNIT TESTBENCH: tb_dyn_right_shifter");
        $display("==================================================================");

        //---------------------------------------------------------------------
        // SUITE 1: Exhaustive test on N=8, SHIFT_W=4 (Logical, Arith, Custom fill)
        //---------------------------------------------------------------------
        $display("[Suite 1] Running exhaustive test on N=8 (Logical, Arith, Custom)...");
        for (int data = 0; data < (1 << N1); data++) begin
            for (int sh = 0; sh < (1 << SHIFT_W1); sh++) begin
                in_1       = data[N1-1:0];
                b_1        = sh[SHIFT_W1-1:0];
                fill_val_1 = 1'b1;
                #1;

                // 1. Check Logical (fill = 0)
                begin
                    logic [N1-1:0] exp_log;
                    exp_log = calc_exp_right_shift(in_1, sh, N1, 1'b0);
                    if (out_1_logical !== exp_log) begin
                        $error("[Suite 1 Logical FAIL] in=%h, b=%0d | Got=%h, Exp=%h", in_1, b_1, out_1_logical, exp_log);
                        error_count++;
                    end
                    total_tests++;
                end

                // 2. Check Arithmetic (fill = in_1[7])
                begin
                    logic [N1-1:0] exp_ari;
                    exp_ari = calc_exp_right_shift(in_1, sh, N1, in_1[N1-1]);
                    if (out_1_arith !== exp_ari) begin
                        $error("[Suite 1 Arith FAIL] in=%h, b=%0d | Got=%h, Exp=%h", in_1, b_1, out_1_arith, exp_ari);
                        error_count++;
                    end
                    total_tests++;
                end

                // 3. Check Custom Fill (fill_val = 1)
                begin
                    logic [N1-1:0] exp_cus;
                    exp_cus = calc_exp_right_shift(in_1, sh, N1, 1'b1);
                    if (out_1_custom !== exp_cus) begin
                        $error("[Suite 1 Custom FAIL] in=%h, b=%0d | Got=%h, Exp=%h", in_1, b_1, out_1_custom, exp_cus);
                        error_count++;
                    end
                    total_tests++;
                end
            end
        end
        $display("[Suite 1] Finished %0d vectors.", total_tests);

        //---------------------------------------------------------------------
        // SUITE 2: Boundary & Corner cases for N=32, SHIFT_W=6
        //---------------------------------------------------------------------
        $display("[Suite 2] Running boundary and corner patterns on N=32, SHIFT_W=6...");
        begin
            logic [31:0] test_patterns [10];
            test_patterns[0] = 32'h0000_0000;
            test_patterns[1] = 32'hFFFF_FFFF;
            test_patterns[2] = 32'hAAAA_AAAA;
            test_patterns[3] = 32'h5555_5555;
            test_patterns[4] = 32'h8000_0000; // MSB=1, NaR
            test_patterns[5] = 32'h7FFF_FFFF; // MSB=0, maxpos
            test_patterns[6] = 32'h8000_0001; // MSB=1, -maxpos
            test_patterns[7] = 32'h0000_0001; // minpos
            test_patterns[8] = 32'hF0F0_F0F0;
            test_patterns[9] = 32'hDEAD_BEEF;

            for (int p = 0; p < 10; p++) begin
                for (int sh = 0; sh < 64; sh++) begin
                    in_2       = test_patterns[p];
                    b_2        = sh[5:0];
                    fill_val_2 = 1'b1;
                    #1;

                    // Check Logical
                    begin
                        logic [31:0] exp_log;
                        exp_log = calc_exp_right_shift(in_2, sh, 32, 1'b0);
                        if (out_2_logical !== exp_log) begin
                            $error("[Suite 2 Logical FAIL] in=%h, b=%0d | Got=%h, Exp=%h", in_2, b_2, out_2_logical, exp_log);
                            error_count++;
                        end
                        total_tests++;
                    end

                    // Check Arithmetic
                    begin
                        logic [31:0] exp_ari;
                        exp_ari = calc_exp_right_shift(in_2, sh, 32, in_2[31]);
                        if (out_2_arith !== exp_ari) begin
                            $error("[Suite 2 Arith FAIL] in=%h, b=%0d | Got=%h, Exp=%h", in_2, b_2, out_2_arith, exp_ari);
                            error_count++;
                        end
                        total_tests++;
                    end

                    // Check Custom (fill=1)
                    begin
                        logic [31:0] exp_cus;
                        exp_cus = calc_exp_right_shift(in_2, sh, 32, 1'b1);
                        if (out_2_custom !== exp_cus) begin
                            $error("[Suite 2 Custom FAIL] in=%h, b=%0d | Got=%h, Exp=%h", in_2, b_2, out_2_custom, exp_cus);
                            error_count++;
                        end
                        total_tests++;
                    end
                end
            end

            // Walking 1s & Walking 0s across all shifts 0..63
            for (int bit_idx = 0; bit_idx < 32; bit_idx++) begin
                logic [31:0] w1, w0;
                w1 = (32'h1 << bit_idx);
                w0 = ~(32'h1 << bit_idx);

                for (int sh = 0; sh < 64; sh++) begin
                    // Test Walking 1
                    in_2 = w1;
                    b_2  = sh[5:0];
                    #1;
                    if (out_2_logical !== calc_exp_right_shift(w1, sh, 32, 1'b0)) begin
                        $error("[Suite 2 Walking 1 FAIL] in=%h, b=%0d", in_2, b_2);
                        error_count++;
                    end
                    total_tests++;

                    // Test Walking 0
                    in_2 = w0;
                    b_2  = sh[5:0];
                    #1;
                    if (out_2_logical !== calc_exp_right_shift(w0, sh, 32, 1'b0)) begin
                        $error("[Suite 2 Walking 0 FAIL] in=%h, b=%0d", in_2, b_2);
                        error_count++;
                    end
                    total_tests++;
                end
            end
        end
        $display("[Suite 2] Finished corner tests. Cumulative vectors: %0d", total_tests);

        //---------------------------------------------------------------------
        // SUITE 3: Non-power-of-two (N=27, Posit32 mantissa), SHIFT_W=5
        //---------------------------------------------------------------------
        $display("[Suite 3] Running non-power-of-two verification on N=27...");
        for (int rep = 0; rep < 500; rep++) begin
            logic [26:0] rand_data;
            rand_data = $urandom & 27'h7FF_FFFF;

            for (int f = 0; f < 2; f++) begin
                fill_val_3 = f[0];
                for (int sh = 0; sh < 32; sh++) begin
                    logic [26:0] exp_3;
                    in_3 = rand_data;
                    b_3  = sh[4:0];
                    #1;


                    exp_3 = calc_exp_right_shift(rand_data, sh, 27, fill_val_3);

                    if (out_3 !== exp_3) begin
                        $error("[Suite 3 FAIL] in=%h, b=%0d, fill=%b | Got=%h, Exp=%h", in_3, b_3, fill_val_3, out_3, exp_3);
                        error_count++;
                    end
                    total_tests++;
                end
            end
        end
        $display("[Suite 3] Finished N=27 tests. Cumulative vectors: %0d", total_tests);

        //---------------------------------------------------------------------
        // SUITE 4: Randomized stress testing on N=32, SHIFT_W=6 (20,000 vectors)
        //---------------------------------------------------------------------
        $display("[Suite 4] Running 20,000 randomized stress vectors on N=32...");
        for (int i = 0; i < 20000; i++) begin
            in_2       = {$urandom, $urandom};
            b_2        = $urandom & 6'h3F; // Shifts 0..63
            fill_val_2 = $urandom & 1'b1;
            #1;

            // Check Logical
            if (out_2_logical !== calc_exp_right_shift(in_2, b_2, 32, 1'b0)) begin
                $error("[Suite 4 Logical FAIL] in=%h, b=%0d", in_2, b_2);
                error_count++;
            end
            total_tests++;

            // Check Arithmetic
            if (out_2_arith !== calc_exp_right_shift(in_2, b_2, 32, in_2[31])) begin
                $error("[Suite 4 Arith FAIL] in=%h, b=%0d", in_2, b_2);
                error_count++;
            end
            total_tests++;

            // Check Custom Fill
            if (out_2_custom !== calc_exp_right_shift(in_2, b_2, 32, fill_val_2)) begin
                $error("[Suite 4 Custom FAIL] in=%h, b=%0d", in_2, b_2);
                error_count++;
            end
            total_tests++;
        end
        $display("[Suite 4] Finished randomized stress tests.");

        //---------------------------------------------------------------------
        // Final Summary
        //---------------------------------------------------------------------
        $display("==================================================================");
        if (error_count == 0) begin
            $display("   TEST RESULT: ALL %0d VECTORS PASSED 100%% (0 MISMATCHES)!", total_tests);
        end else begin
            $fatal(1, "TEST RESULT: FAILED WITH %0d ERRORS OUT OF %0d TESTS!", error_count, total_tests);
        end
        $display("==================================================================");
        $finish;
    end

endmodule
