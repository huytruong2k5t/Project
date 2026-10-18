`timescale 1ns/1ps
module tb_week14_protocol;
    parameter bit NF_EX0 = 1'b0;
    logic clk = 1'b0;
    always #4 clk = ~clk;
    logic rst_n = 1'b0;
    logic in_valid = 1'b0;
    wire in_ready;
    logic [31:0] a = 32'h43ffffff;
    logic [31:0] b = 32'h43ffffff;
    logic [31:0] c = '0;
    logic acc_mode = 1'b0;
    logic acc_clr = 1'b0;
    logic cfg_mode = 1'b1;
    logic [3:0] cfg_n = '0;
    logic [1:0] cfg_ops = 2'b01;
    wire out_valid;
    logic out_ready = 1'b1;
    wire [31:0] d;
    wire [4:0] flags;
    generate
        if (NF_EX0) begin : g_nf
            posit_mac_nf #(.NB(32), .ES(3), .FRAC_W(12), .EXACT_EN(1'b0)) u_dut (
                .clk(clk), .rst_n(rst_n), .in_valid(in_valid), .in_ready(in_ready),
                .a(a), .b(b), .c(c), .acc_mode(acc_mode), .acc_clr(acc_clr),
                .cfg_mode(cfg_mode), .cfg_n(cfg_n), .cfg_ops(cfg_ops),
                .out_valid(out_valid), .out_ready(out_ready), .d(d), .flags(flags)
            );
        end else begin : g_f
            posit_mac_f u_dut (
                .clk(clk), .rst_n(rst_n), .in_valid(in_valid), .in_ready(in_ready),
                .a(a), .b(b), .c(c), .acc_mode(acc_mode), .acc_clr(acc_clr),
                .cfg_mode(cfg_mode), .cfg_n(cfg_n), .cfg_ops(cfg_ops),
                .out_valid(out_valid), .out_ready(out_ready), .d(d), .flags(flags)
            );
        end
    endgenerate
    logic [36:0] expected [0:8];
    string vector_path;
    integer cycles, accept_cycle, last_accept, accepted, retired, total, q;
    bit pending, seen;
    task automatic reset_dut;
        @(negedge clk);
        rst_n = 1'b0;
        in_valid = 1'b0;
        repeat (4) begin
            @(posedge clk); #2;
            if (in_ready || out_valid) $fatal(1,"reset gating");
        end
        @(negedge clk); rst_n = 1'b1;
        repeat (8) begin @(posedge clk); #2; end
    endtask
    initial begin
        if (!$value$plusargs("VECTORS=%s",vector_path)) $fatal(1,"missing vectors");
        $readmemh(vector_path,expected);
        total = 0;
        reset_dut();
        for (integer bad=0; bad<5; bad=bad+1) begin
            @(negedge clk);
            in_valid=1'b1;cfg_mode=(bad!=0);cfg_n=(bad==1)?4'd9:4'd0;
            cfg_ops=(bad==2)?2'd2:(bad==3)?2'd3:2'd1;
            acc_clr=(bad==4);
            repeat (3) begin
                @(posedge clk);#2;
                if (in_ready || out_valid) $fatal(1,"invalid request accepted: %0d",bad);
            end
        end
        @(negedge clk);in_valid=1'b0;cfg_mode=1'b1;cfg_ops=2'd1;acc_clr=1'b0;
        for (integer n=0; n<9; n=n+1) begin
            reset_dut();
            @(negedge clk);cfg_n=4'(n);in_valid=1'b1;
            q=(n==0)?1:n;
            cycles=0;accept_cycle=0;last_accept=-1;accepted=0;retired=0;pending=0;seen=0;
            while (retired<16) begin
                @(posedge clk);
                cycles=cycles+1;
                if (in_ready && in_valid) begin
                    if (pending) $fatal(1,"multiple inflight");
                    if (last_accept>=0 && cycles-last_accept != q+13+integer'(NF_EX0))
                        $fatal(1,"II n=%0d got=%0d expected=%0d",n,cycles-last_accept,q+13+integer'(NF_EX0));
                    last_accept=cycles;accept_cycle=cycles;accepted=accepted+1;pending=1;seen=0;
                end
                if (out_valid && out_ready) begin
                    if (!pending || !seen) $fatal(1,"duplicate/early output");
                    if (cycles-accept_cycle != q+12+integer'(NF_EX0)) $fatal(1,"handshake latency");
                    if ({flags,d} !== expected[n]) $fatal(1,"data/flags n=%0d",n);
                    retired=retired+1;pending=0;
                end
                #2;
                if (out_valid && !seen) begin
                    if (cycles-accept_cycle != q+11+integer'(NF_EX0)) $fatal(1,"valid latency");
                    seen=1;
                end
                if (cycles>1000) $fatal(1,"timeout");
            end
            @(negedge clk);in_valid=1'b0;
            if (accepted!=retired) $fatal(1,"accounting");
            total=total+retired;
            $display("W14_PROTOCOL_N_PASS NF_EX0=%0d n=%0d q=%0d L=%0d H=%0d II=%0d completed=%0d",
                NF_EX0,n,q,q+11+integer'(NF_EX0),q+12+integer'(NF_EX0),q+13+integer'(NF_EX0),retired);
        end
        $display("W14_PROTOCOL_PASS NF_EX0=%0d completed=%0d mismatch=0 CK2Q=1ns clock=8ns",NF_EX0,total);
        $finish;
    end
endmodule
