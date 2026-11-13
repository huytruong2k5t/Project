`timescale 1ns/1ps
// One outstanding operation, always-ready response, measured at handshakes.
module tb_mac_chain_benchmark #(parameter integer CORE = 0);
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst_n = 0, in_valid = 0;
    logic [31:0] a = 0, b = 0, c = 0;
    logic [1:0] cmd = 0;
    wire [3:0] cfg_n = 4'd12;
    wire [1:0] cfg_ops = 2'd1;
    wire out_ready = 1'b1;
    wire in_ready, out_valid, overflow;
    wire [1:0] out_cmd;
    wire [31:0] d;
    wire [4:0] flags;
    wire [971:0] q_value;
    wire [10:0] q_count;

    generate
        if (CORE == 0) begin : g_nf
            posit_mac_nf dut (
                .clk(clk), .rst_n(rst_n), .in_valid(in_valid), .in_ready(in_ready),
                .a(a), .b(b), .c(c), .cfg_n(cfg_n), .cfg_ops(cfg_ops),
                .out_valid(out_valid), .out_ready(out_ready), .d(d), .flags(flags)
            );
        end else if (CORE == 1) begin : g_f
            posit_mac_f dut (
                .clk(clk), .rst_n(rst_n), .in_valid(in_valid), .in_ready(in_ready),
                .a(a), .b(b), .c(c), .cfg_n(cfg_n), .cfg_ops(cfg_ops),
                .out_valid(out_valid), .out_ready(out_ready), .d(d), .flags(flags)
            );
        end else begin : g_q
            posit_mac_quire dut (
                .clk(clk), .rst_n(rst_n), .in_valid(in_valid), .in_ready(in_ready),
                .a(a), .b(b), .q_cmd(cmd), .cfg_n(cfg_n), .cfg_ops(cfg_ops),
                .out_valid(out_valid), .out_ready(out_ready), .out_cmd(out_cmd),
                .d(d), .flags(flags), .q_overflow(overflow)
            );
            assign q_value = dut.u_wrapper.q_value;
            assign q_count = dut.u_wrapper.q_count;
        end
    endgenerate

    integer fi, fo, fields, sequence_id, command_id, last, count, waited;
    integer prev_id = 0, completed = 0, sequences = 0;
    logic [31:0] expect_d, feedback;
    logic [4:0] expect_flags;
    logic [971:0] expect_q;
    time first_accept;
    reg [2047:0] fixture_path, results_path;

    initial begin
        if (!$value$plusargs("FIXTURE=%s", fixture_path) ||
            !$value$plusargs("RESULTS=%s", results_path)) $fatal(1, "Paths required");
        fi = $fopen(fixture_path, "r");
        fo = $fopen(results_path, "w");
        if (!fi || !fo) $fatal(1, "Cannot open benchmark files");
        $fdisplay(fo, "sequence_id,cycles,d_hex,flags_hex");
        repeat (4) @(negedge clk);
        rst_n = 1;
        fields = $fscanf(fi, "%d %d %h %h %h %h %h %d %d\n",
                         sequence_id, command_id, a, b, expect_d, expect_flags, expect_q, count, last);
        while (fields == 9) begin
            cmd = command_id[1:0];
            if (sequence_id != prev_id) c = 0;
            in_valid = 1;
            waited = 0;
            do begin
                @(posedge clk);
                waited = waited + 1;
                if (waited > 128 || out_valid !== 1'b0) $fatal(1, "Input timeout or extra response");
            end while (in_ready !== 1'b1);
            if (sequence_id != prev_id) first_accept = $time;
            @(negedge clk);
            in_valid = 0;
            waited = 0;
            do begin
                @(posedge clk);
                waited = waited + 1;
                if (waited > 128) $fatal(1, "Output timeout");
            end while (out_valid !== 1'b1);
            if ({d, flags} !== {expect_d, expect_flags})
                $fatal(1, "core=%0d sequence=%0d cmd=%0d count=%0d got=%h/%h expected=%h/%h",
                       CORE, sequence_id, command_id, count, d, flags, expect_d, expect_flags);
            if (CORE == 2 && ({out_cmd, overflow} !== {cmd, 1'b0} ||
                              q_value !== expect_q || q_count !== count[10:0]))
                $fatal(1, "Quire state/response mismatch at sequence=%0d count=%0d", sequence_id, count);
            feedback = d;
            if (last == 1) begin
                $fdisplay(fo, "%0d,%0d,%08h,%02h", sequence_id, ($time - first_accept)/10+1, d, flags);
                sequences = sequences + 1;
            end
            prev_id = sequence_id;
            completed = completed + 1;
            @(negedge clk);
            if (CORE != 2) c = feedback;
            fields = $fscanf(fi, "%d %d %h %h %h %h %h %d %d\n",
                             sequence_id, command_id, a, b, expect_d, expect_flags, expect_q, count, last);
        end
        if (!$feof(fi) || fields > 0 || completed == 0) $fatal(1, "Malformed fixture");
        repeat (4) begin
            @(posedge clk);
            if (out_valid !== 1'b0) $fatal(1, "Extra response after final result");
        end
        $fclose(fi);
        $fclose(fo);
        $display("MAC_CHAIN_PASS core=%0d commands=%0d sequences=%0d", CORE, completed, sequences);
        $finish;
    end
endmodule
