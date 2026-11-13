//-----------------------------------------------------------------------------
// File          : tb_multiplier_prepack.sv
// Project       : Posit MAC IP
// Description   : Capture the completed FULL_TERM product in MAC-F with C=0.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module tb_multiplier_prepack;
    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic rst_n = 1'b0;
    logic in_valid = 1'b0;
    logic [31:0] a = '0;
    logic [31:0] b = '0;
    wire [31:0] c = '0;
    logic [3:0] cfg_n = 4'd12;
    wire [1:0] cfg_ops = 2'd1;
    wire out_ready = 1'b1;
    wire in_ready;
    wire out_valid;
    wire [31:0] d;
    wire [4:0] flags;

    posit_mac_f dut (
        .clk (clk),
        .rst_n (rst_n),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .a (a),
        .b (b),
        .c (c),
        .cfg_n (cfg_n),
        .cfg_ops (cfg_ops),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .d (d),
        .flags (flags)
    );

    wire core_done = dut.u_wrapper.u_core.core_done;
    wire core_error = dut.u_wrapper.u_core.state_error;
    wire [25:0] magnitude = dut.u_wrapper.u_core.acc;
    wire signed [10:0] sf_base = dut.u_wrapper.u_core.sf_o;
    wire product_sign = dut.u_wrapper.u_core.sign_o;
    wire [3:0] iterations = dut.u_wrapper.u_core.iterations_done;
    wire input_cut = dut.u_wrapper.u_core.input_cut_o;
    wire iteration_cut = dut.u_wrapper.u_core.approx_cut;

    integer pair_file, observation_file, fields, n, pair_id;
    integer completed = 0;
    integer cycles;
    logic seen_core;
    logic [31:0] next_a, next_b;
    logic [25:0] measured_magnitude;
    logic signed [10:0] measured_sf;
    logic measured_sign, measured_input_cut, measured_iteration_cut;
    logic [3:0] measured_iterations;
    reg [2047:0] pair_path, observation_path;

    initial begin
        if (!$value$plusargs("N=%d", n) || n < 0 || n > 12)
            $fatal(1, "N must be in 0..12");
        if (!$value$plusargs("PAIRS=%s", pair_path) ||
            !$value$plusargs("OBSERVED=%s", observation_path))
            $fatal(1, "PAIRS and OBSERVED are required");
        pair_file = $fopen(pair_path, "r");
        observation_file = $fopen(observation_path, "w");
        if (!pair_file || !observation_file) $fatal(1, "Cannot open benchmark files");
        $fdisplay(observation_file, "pair_id,m_q24,sf_base,sign,iterations,input_cut,iteration_cut,d_hex,flags_hex");

        repeat (4) @(negedge clk);
        rst_n = 1'b1;
        cfg_n = n[3:0];
        fields = $fscanf(pair_file, "%d %h %h\n", pair_id, next_a, next_b);
        while (fields == 3) begin
            if (pair_id != completed + 1)
                $fatal(1, "Unexpected pair_id=%0d after %0d rows", pair_id, completed);
            a = next_a;
            b = next_b;
            in_valid = 1'b1;
            cycles = 0;
            do begin
                @(posedge clk);
                cycles = cycles + 1;
                if (cycles > 64 || out_valid !== 1'b0)
                    $fatal(1, "Input timeout or unexpected response at pair %0d", pair_id);
            end while (in_ready !== 1'b1);
            @(negedge clk);
            in_valid = 1'b0;
            seen_core = 1'b0;
            cycles = 0;
            do begin
                // Read settled payload at the same rising edge that retires it.
                @(posedge clk);
                cycles = cycles + 1;
                if (cycles > 64 || core_error !== 1'b0 || $isunknown({core_done, out_valid}))
                    $fatal(1, "Core/control failure at pair %0d n=%0d", pair_id, n);
                if (core_done) begin
                    if (seen_core || $isunknown({magnitude, sf_base, product_sign, iterations,
                                                input_cut, iteration_cut}))
                        $fatal(1, "Invalid product at pair %0d n=%0d", pair_id, n);
                    seen_core = 1'b1;
                    measured_magnitude = magnitude;
                    measured_sf = sf_base;
                    measured_sign = product_sign;
                    measured_iterations = iterations;
                    measured_input_cut = input_cut;
                    measured_iteration_cut = iteration_cut;
                end
            end while (out_valid !== 1'b1);
            if (!seen_core || $isunknown({d, flags}))
                $fatal(1, "Response without known product/output at pair %0d n=%0d", pair_id, n);
            $fdisplay(observation_file, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%08h,%02h",
                      pair_id, measured_magnitude, measured_sf, measured_sign,
                      measured_iterations, measured_input_cut, measured_iteration_cut, d, flags);
            completed = completed + 1;
            @(negedge clk);
            fields = $fscanf(pair_file, "%d %h %h\n", pair_id, next_a, next_b);
        end
        if (!$feof(pair_file) || fields > 0 || completed == 0)
            $fatal(1, "Malformed or empty pair file after %0d rows", completed);
        repeat (4) begin
            @(posedge clk);
            if (out_valid !== 1'b0 || core_done !== 1'b0)
                $fatal(1, "Extra response after the last pair");
        end
        $fclose(pair_file);
        $fclose(observation_file);
        $display("MULTIPLIER_PREPACK_CAPTURED n=%0d rows=%0d", n, completed);
        $finish;
    end
endmodule
//-----------------------------------------------------------------------------
// End of tb_multiplier_prepack.sv
//-----------------------------------------------------------------------------
