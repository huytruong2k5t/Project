// Timing and payload trace for the frozen 07/11 MAC-F report.
`timescale 1ns/1ps
module tb_report_mac_f_trace;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst_n = 0, in_valid = 0, out_ready = 0;
    logic [3:0] cfg_n = 12;
    logic [31:0] a = 32'h1c900000, b = 32'h3c820000;
    wire in_ready, out_valid;
    wire [31:0] d;
    wire [4:0] flags;
    posit_mac_f dut (
        .clk(clk), .rst_n(rst_n), .in_valid(in_valid), .in_ready(in_ready),
        .a(a), .b(b), .c(32'd0), .cfg_n(cfg_n), .cfg_ops(2'd1),
        .out_valid(out_valid), .out_ready(out_ready), .d(d), .flags(flags)
    );
    integer trace_file, cycle = 0, seq_id = 0, retired = 0;
    always @(posedge clk) begin
        cycle = cycle + 1;
        if (seq_id != 0)
            $fdisplay(trace_file, "%0d,%0d,%b,%b,%b,%b,%b,%b,%b,%0d,%b,%0d,%0d,%b,%b,%b,%08h,%02h",
                seq_id, cycle, rst_n, in_valid, in_ready,
                dut.u_wrapper.valid_a, dut.u_wrapper.valid_b, dut.u_wrapper.pair_retire,
                dut.u_wrapper.u_core.t2_valid, dut.u_wrapper.u_core.t2_iteration,
                dut.u_wrapper.core_done, dut.u_wrapper.acc, $signed(dut.u_wrapper.core_sf),
                dut.u_wrapper.add_valid, out_valid, out_ready, d, flags);
        if (rst_n && out_valid && out_ready) retired = retired + 1;
    end

    task automatic send(input integer id, input logic [3:0] n);
        integer tries;
        seq_id = id;
        cfg_n = n;
        in_valid = 1;
        tries = 0;
        do begin
            @(posedge clk);
            tries = tries + 1;
            if (tries > 40) $fatal(1, "Input timeout");
        end while (in_ready !== 1'b1);
        @(negedge clk);
        in_valid = 0;
    endtask

    task automatic finish_case(input logic [31:0] expected_d,
                               input logic [4:0] expected_flags, input integer stall);
        integer tries;
        tries = 0;
        while (out_valid !== 1'b1) begin
            @(negedge clk);
            tries = tries + 1;
            if (tries > 40) $fatal(1, "Output timeout");
        end
        repeat (stall) begin
            @(posedge clk);
            if ({out_valid, d, flags} !== {1'b1, expected_d, expected_flags})
                $fatal(1, "Held response mismatch");
        end
        @(negedge clk);
        out_ready = 1;
        @(posedge clk);
        if ({out_valid, d, flags} !== {1'b1, expected_d, expected_flags})
            $fatal(1, "Retired response mismatch");
        @(negedge clk);
        out_ready = 0;
    endtask

    initial begin
        trace_file = $fopen("trace.csv", "w");
        if (!trace_file) $fatal(1, "Cannot open trace file");
        $fdisplay(trace_file,
            "case,cycle,rst_n,in_valid,in_ready,valid_a,valid_b,pair_retire,t2_valid,t2_iteration,core_done,m,sf,add_valid,out_valid,out_ready,d,flags");
        repeat (5) @(negedge clk);
        rst_n = 1;
        send(1, 12);
        finish_case(32'h1ae34800, 5'h00, 3);
        send(2, 0);
        finish_case(32'h1a410000, 5'h03, 0);
        send(3, 12);
        repeat (3) @(negedge clk);
        rst_n = 0;
        repeat (5) @(negedge clk);
        rst_n = 1;
        out_ready = 1;
        repeat (30) begin
            @(posedge clk);
            if (out_valid !== 1'b0) $fatal(1, "Aborted transaction returned");
        end
        @(negedge clk);
        out_ready = 0;
        send(4, 12);
        finish_case(32'h1ae34800, 5'h00, 0);
        if (retired != 3) $fatal(1, "Expected three responses");
        $fclose(trace_file);
        $display("REPORT_TRACE_PASS accepted=4 retired=3 aborted=1");
        $finish;
    end
endmodule
