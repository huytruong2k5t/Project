`timescale 1ns/1ps
module tb_week13_fused_event;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst_n = 1'b0;
    logic in_valid = 1'b0;
    wire in_ready;
    logic [31:0] a = '0;
    logic [31:0] b = '0;
    logic [31:0] c = '0;
    logic acc_mode = 1'b0;
    logic acc_clr = 1'b0;
    logic cfg_mode = 1'b1;
    logic [3:0] cfg_n = '0;
    logic [1:0] cfg_ops = '0;
    wire out_valid;
    logic out_ready = 1'b0;
    wire [31:0] d;
    wire [4:0] flags;
    posit_mac_f u_dut (
        .clk (clk), .rst_n (rst_n),
        .in_valid (in_valid), .in_ready (in_ready),
        .a (a), .b (b), .c (c),
        .acc_mode (acc_mode), .acc_clr (acc_clr),
        .cfg_mode (cfg_mode), .cfg_n (cfg_n), .cfg_ops (cfg_ops),
        .out_valid (out_valid), .out_ready (out_ready), .d (d), .flags (flags)
    );
    integer fd;
    integer rc;
    integer n_i, ops_i, mode_i, clear_i, reset_i, latency_i;
    integer elapsed, count = 0;
    logic [31:0] expected;
    logic [4:0] expected_flags;
    string vector_path;
    task automatic tick;
        @(posedge clk);
        #2;
    endtask
    task automatic reset_dut;
        @(negedge clk);
        rst_n = 1'b0;
        in_valid = 1'b0;
        out_ready = 1'b0;
        repeat (4) begin
            tick();
            if (out_valid || in_ready) $fatal(1, "reset gate");
        end
        @(negedge clk);
        rst_n = 1'b1;
        repeat (8) tick();
        if (out_valid) $fatal(1, "stale output after reset");
    endtask
    task automatic accept;
        integer guard_cycles;
        guard_cycles = 0;
        #1;
        while (!in_ready) begin
            @(negedge clk);
            #1;
            guard_cycles++;
            if (guard_cycles > 100) $fatal(1, "accept timeout");
        end
        tick();
        @(negedge clk);
        in_valid = 1'b0;
    endtask
    initial begin
        if (!$value$plusargs("VECTORS=%s", vector_path)) $fatal(1, "missing VECTORS");
        reset_dut();
        // Abort at every pipeline age, including a completed but stalled result.
        for (int age = 0; age < 24; age++) begin
            @(negedge clk);
            a = 32'h3fffffff; b = 32'h47ffffff; c = 32'hc0000001;
            cfg_mode = 1'b1; cfg_n = 8; cfg_ops = 1;
            acc_mode = 1'b1; acc_clr = 1'b0; in_valid = 1'b1;
            accept();
            repeat (age) tick();
            reset_dut();
        end
        for (int bad = 0; bad < 4; bad++) begin
            @(negedge clk);
            in_valid = 1'b1;
            cfg_mode = bad != 0; cfg_n = (bad == 1) ? 9 : 0;
            cfg_ops = (bad == 2) ? 2 : 0;
            acc_mode = 1'b0; acc_clr = bad == 3;
            repeat (3) begin
                tick();
                if (in_ready || out_valid) $fatal(1, "invalid accepted");
            end
        end
        reset_dut();
        fd = $fopen(vector_path, "r");
        if (fd == 0) $fatal(1, "cannot open vectors");
        while (!$feof(fd)) begin
            @(negedge clk);
            rc = $fscanf(fd, "%h %h %h %h %h %d %d %d %d %d %d\n",
                         a, b, c, expected, expected_flags,
                         n_i, ops_i, mode_i, clear_i, reset_i, latency_i);
            if (rc != 11) $fatal(1, "bad vector row");
            if (reset_i != 0) reset_dut();
            @(negedge clk);
            cfg_mode = 1'b1; cfg_n = 4'(n_i); cfg_ops = 2'(ops_i);
            acc_mode = 1'(mode_i); acc_clr = 1'(clear_i);
            out_ready = 1'b0; in_valid = 1'b1;
            accept();
            elapsed = 0;
            // Free-running external ports must not replace accepted context.
            a = ~a; b = ~b; c = ~c;
            cfg_n = 15; cfg_ops = 3; cfg_mode = 0;
            acc_mode = ~acc_mode; acc_clr = ~acc_clr;
            while (!out_valid) begin
                tick();
                elapsed++;
                if (elapsed > 100) $fatal(1, "output timeout");
            end
            if (elapsed != latency_i) $fatal(1, "latency %0d != %0d", elapsed, latency_i);
            if (d !== expected || flags !== expected_flags)
                $fatal(1, "row %0d got %h/%h expected %h/%h", count, d, flags, expected, expected_flags);
            repeat ((count % 31 == 0) ? 96 : 3) begin
                tick();
                if (!out_valid || d !== expected || flags !== expected_flags)
                    $fatal(1, "stalled output changed");
            end
            @(negedge clk);
            out_ready = 1'b1;
            tick();
            if (out_valid) $fatal(1, "duplicate output");
            count++;
        end
        $fclose(fd);
        if (count != 8192) $fatal(1, "missing vectors");
        $display("W13_EVENT_PASS completed=%0d reset_aborts=24 mismatch=0 CK2Q=1ns", count);
        $finish;
    end
    initial begin
        #10000000;
        $fatal(1, "watchdog timeout");
    end
endmodule
