//-----------------------------------------------------------------------------
// File          : tb_dyn_left_shifter.sv
// Author(s)     : Dan Huy
// Email         : 
// Project       : Posit MAC IP (Approximate & Iterative Posit MAC)
// Creation Date : 2026-10-02
//
// Description   : Comprehensive self-checking unit testbench for dyn_left_shifter.
//                 - Suite 1: Exhaustive verification on N=8, SHIFT_W=4 (4096 vectors)
//                 - Suite 2: Corner & boundary tests on N=32, SHIFT_W=6 (shifts 0..63)
//                 - Suite 3: Non-power-of-2 verification on N=27 (Posit32 mantissa)
//                 - Suite 4: Randomized stress test on N=32 (10,000 vectors)
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_dyn_left_shifter;

    int total_tests = 0;
    int error_count = 0;

    //=========================================================================
    // Test Suite 1: Exhaustive verification for N=8, SHIFT_W=4
    //=========================================================================
    localparam int N1       = 8;
    localparam int SHIFT_W1 = 4;

    logic [N1-1:0]       in_1;
    logic [SHIFT_W1-1:0] b_1;
    logic [N1-1:0]       out_1;

    dyn_left_shifter #(
        .N       (N1),
        .SHIFT_W (SHIFT_W1)
    ) dut_suite1 (
        .in  (in_1),
        .b   (b_1),
        .out (out_1)
    );

    //=========================================================================
    // Test Suite 2 & 4: N=32, SHIFT_W=6 (with overflow b=32..63)
    //=========================================================================
    localparam int N2       = 32;
    localparam int SHIFT_W2 = 6;

    logic [N2-1:0]       in_2;
    logic [SHIFT_W2-1:0] b_2;
    logic [N2-1:0]       out_2;

    dyn_left_shifter #(
        .N       (N2),
        .SHIFT_W (SHIFT_W2)
    ) dut_suite2 (
        .in  (in_2),
        .b   (b_2),
        .out (out_2)
    );

    //=========================================================================
    // Test Suite 3: N=27 (Non-power-of-two, Posit32 mantissa), SHIFT_W=5
    //=========================================================================
    localparam int N3       = 27;
    localparam int SHIFT_W3 = 5;

    logic [N3-1:0]       in_3;
    logic [SHIFT_W3-1:0] b_3;
    logic [N3-1:0]       out_3;

    dyn_left_shifter #(
        .N       (N3),
        .SHIFT_W (SHIFT_W3)
    ) dut_suite3 (
        .in  (in_3),
        .b   (b_3),
        .out (out_3)
    );

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
        $display("   STARTING UNIT TESTBENCH: tb_dyn_left_shifter");
        $display("==================================================================");

        //---------------------------------------------------------------------
        // SUITE 1: Exhaustive test for N=8, SHIFT_W=4 (4096 combinations)
        //---------------------------------------------------------------------
        $display("[Suite 1] Running exhaustive test on N=8, SHIFT_W=4...");
        for (int data = 0; data < (1 << N1); data++) begin
            for (int sh = 0; sh < (1 << SHIFT_W1); sh++) begin
                logic [N1-1:0] exp_1;
                in_1 = data[N1-1:0];
                b_1  = sh[SHIFT_W1-1:0];
                #1;

                // Golden model

                if (sh >= N1) begin
                    exp_1 = '0;
                end else begin
                    exp_1 = (in_1 << sh);
                end

                if (out_1 !== exp_1) begin
                    $error("[Suite 1 FAILED] in=%b, b=%0d | Got=%b, Expected=%b", in_1, b_1, out_1, exp_1);
                    error_count++;
                end
                total_tests++;
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
            test_patterns[4] = 32'h8000_0000; // NaR
            test_patterns[5] = 32'h7FFF_FFFF; // maxpos
            test_patterns[6] = 32'h0000_0001; // minpos
            test_patterns[7] = 32'h1234_5678;
            test_patterns[8] = 32'hDEAD_BEEF;
            test_patterns[9] = 32'hCAFE_BABE;

            for (int p = 0; p < 10; p++) begin
                for (int sh = 0; sh < 64; sh++) begin
                    logic [31:0] exp_2;
                    in_2 = test_patterns[p];
                    b_2  = sh[5:0];
                    #1;


                    if (sh >= 32) begin
                        exp_2 = '0;
                    end else begin
                        exp_2 = (in_2 << sh);
                    end

                    if (out_2 !== exp_2) begin
                        $error("[Suite 2 FAILED] in=%h, b=%0d | Got=%h, Expected=%h", in_2, b_2, out_2, exp_2);
                        error_count++;
                    end
                    total_tests++;
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
                    if (out_2 !== ((sh >= 32) ? 32'h0 : (w1 << sh))) begin
                        $error("[Suite 2 Walking 1 FAILED] in=%h, b=%0d", in_2, b_2);
                        error_count++;
                    end
                    total_tests++;

                    // Test Walking 0
                    in_2 = w0;
                    b_2  = sh[5:0];
                    #1;
                    if (out_2 !== ((sh >= 32) ? 32'h0 : (w0 << sh))) begin
                        $error("[Suite 2 Walking 0 FAILED] in=%h, b=%0d", in_2, b_2);
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

            for (int sh = 0; sh < 32; sh++) begin
                logic [26:0] exp_3;
                in_3 = rand_data;
                b_3  = sh[4:0];
                #1;


                if (sh >= 27) begin
                    exp_3 = '0;
                end else begin
                    exp_3 = (rand_data << sh) & 27'h7FF_FFFF;
                end

                if (out_3 !== exp_3) begin
                    $error("[Suite 3 FAILED] in=%h, b=%0d | Got=%h, Expected=%h", in_3, b_3, out_3, exp_3);
                    error_count++;
                end
                total_tests++;
            end
        end
        $display("[Suite 3] Finished N=27 tests. Cumulative vectors: %0d", total_tests);

        //---------------------------------------------------------------------
        // SUITE 4: Randomized stress testing on N=32, SHIFT_W=6
        //---------------------------------------------------------------------
        $display("[Suite 4] Running 10,000 randomized stress vectors on N=32...");
        for (int i = 0; i < 10000; i++) begin
            logic [31:0] exp_4;
            in_2 = {$urandom, $urandom};
            b_2  = $urandom & 6'h3F; // Shifts 0..63
            #1;


            if (b_2 >= 32) begin
                exp_4 = '0;
            end else begin
                exp_4 = in_2 << b_2;
            end

            if (out_2 !== exp_4) begin
                $error("[Suite 4 FAILED] in=%h, b=%0d | Got=%h, Expected=%h", in_2, b_2, out_2, exp_4);
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
