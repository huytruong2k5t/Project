//-----------------------------------------------------------------------------
// File          : tb_lod_lzd_core.sv
// Author(s)     : Dan Huy
// Email         : 
// Project       : Posit MAC IP
// Creation Date : 2026-10-01
//
// Description   : Unit testbench for lod_lzd_core module.
//                 Exhaustive N=8; directed, stratified and random N=31/32.
//                 20,512 vectors; checks both MODEs and invalid K=0.
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_lod_lzd_core;
    wire [2:0] done;
    wire [31:0] errors [0:2];
    wire [31:0] vectors [0:2];

    lod_lzd_test_case #(.N(8), .EXHAUSTIVE(1)) u_n8
        (.done(done[0]), .errors(errors[0]), .vectors(vectors[0]));
    lod_lzd_test_case #(.N(31), .SEED(32'h31c0ffee)) u_n31
        (.done(done[1]), .errors(errors[1]), .vectors(vectors[1]));
    lod_lzd_test_case #(.N(32), .SEED(32'h32c0ffee)) u_n32
        (.done(done[2]), .errors(errors[2]), .vectors(vectors[2]));

    initial begin
        wait (&done);
        if ((errors[0] + errors[1] + errors[2]) != 0)
            $fatal(1, "LOD/LZD FAILED: %0d mismatches", errors[0] + errors[1] + errors[2]);
        $display("LOD/LZD PASSED: %0d vectors, %0d checks, 0 mismatches",
                 vectors[0] + vectors[1] + vectors[2],
                 2 * (vectors[0] + vectors[1] + vectors[2]));
        $finish;
    end
    initial begin
        #100000;
        $fatal(1, "LOD/LZD test timeout");
    end
endmodule

// Independent linear-scan oracle; DUT uses a binary tree.
module lod_lzd_test_case #(
    parameter int N = 8,
    parameter bit EXHAUSTIVE = 0,
    parameter int RANDOM_VECTORS = 10000,
    parameter logic [31:0] SEED = 32'h1
)(
    output logic done,
    output int unsigned errors,
    output int unsigned vectors
);

    localparam int S = $clog2(N);

    logic [N-1:0] in;
    logic [S-1:0] lod_k, lzd_k;
    logic         lod_vld, lzd_vld;

    // Instantiate LOD (MODE=0)
    lod_lzd_core #(.N(N), .MODE(0)) u_lod (
        .in (in),
        .K  (lod_k),
        .vld(lod_vld)
    );

    // Instantiate LZD (MODE=1)
    lod_lzd_core #(.N(N), .MODE(1)) u_lzd (
        .in (in),
        .K  (lzd_k),
        .vld(lzd_vld)
    );

    logic [31:0] rng_state;
    logic [N-1:0] pattern, tail_mask;
    bit [N-1:0] seen_lod, seen_lzd;
    bit seen_lod_invalid, seen_lzd_invalid;

    // Local deterministic PRNG, independent of simulator random seeding.
    function automatic logic [31:0] next_random(input logic [31:0] state);
        logic [31:0] x;
        begin
            x = state ^ (state << 13);
            x = x ^ (x >> 17);
            next_random = x ^ (x << 5);
        end
    endfunction

    task automatic check_vector(input logic [N-1:0] value);
        logic exp_lod_vld, exp_lzd_vld;
        logic [S-1:0] exp_lod_k, exp_lzd_k;
        begin
            in = value;
            #1;
            exp_lod_vld = 0;
            exp_lzd_vld = 0;
            exp_lod_k = '0;
            exp_lzd_k = '0;
            for (int b = 0; b < N; b++) begin
                if (!exp_lod_vld && value[N-1-b] == 1'b1) begin
                    exp_lod_vld = 1;
                    exp_lod_k = b[S-1:0];
                end
                if (!exp_lzd_vld && value[N-1-b] == 1'b0) begin
                    exp_lzd_vld = 1;
                    exp_lzd_k = b[S-1:0];
                end
            end
            // Check K even when invalid: RTL contract requires K=0.
            if (lod_vld !== exp_lod_vld || lod_k !== exp_lod_k) begin
                $display("LOD FAIL N=%0d in=%h expected=(%b,%0d) got=(%b,%0d)",
                         N, value, exp_lod_vld, exp_lod_k, lod_vld, lod_k);
                errors++;
            end
            if (lzd_vld !== exp_lzd_vld || lzd_k !== exp_lzd_k) begin
                $display("LZD FAIL N=%0d in=%h expected=(%b,%0d) got=(%b,%0d)",
                         N, value, exp_lzd_vld, exp_lzd_k, lzd_vld, lzd_k);
                errors++;
            end
            if (exp_lod_vld) seen_lod[exp_lod_k] = 1;
            else seen_lod_invalid = 1;
            if (exp_lzd_vld) seen_lzd[exp_lzd_k] = 1;
            else seen_lzd_invalid = 1;
            vectors++;
        end
    endtask

    initial begin
        done = 0;
        errors = 0;
        vectors = 0;
        in = '0;
        seen_lod = '0;
        seen_lzd = '0;
        seen_lod_invalid = 0;
        seen_lzd_invalid = 0;
        rng_state = SEED;

        // Exhaustive test for N=8 (256 vectors)
        if (EXHAUSTIVE) begin
            for (int v = 0; v < (1 << N); v++) check_vector(v[N-1:0]);
        end else begin
            check_vector('0);
            check_vector('1);
            for (int b = 0; b < N; b++) begin
                pattern = '0;
                pattern[b] = 1;
                check_vector(pattern);
                check_vector(~pattern);
            end
            // Force every leading position, including long runs and last leaf.
            for (int b = 0; b < N; b++) begin
                rng_state = next_random(rng_state);
                tail_mask = {N{1'b1}} >> (N - b);
                pattern = rng_state[N-1:0] & tail_mask;
                pattern[b] = 1'b1;
                check_vector(pattern);
                check_vector(~pattern);
            end
            for (int v = 0; v < RANDOM_VECTORS; v++) begin
                rng_state = next_random(rng_state);
                check_vector(rng_state[N-1:0]);
            end
        end
        if (!(&seen_lod) || !(&seen_lzd) || !seen_lod_invalid || !seen_lzd_invalid) begin
            $display("COVERAGE FAIL N=%0d: missing index or invalid case", N);
            errors++;
        end
        $display("N=%0d seed=%h: %0d vectors, %0d mismatches; index coverage LOD=%b LZD=%b",
                 N, SEED, vectors, errors, seen_lod, seen_lzd);
        done = 1;
    end

endmodule
