//-----------------------------------------------------------------------------
// File: tb_posit_mac_quire.sv | Posit MAC IP | 2026-11-03
// 4-state ordered-command scoreboard from independent Python bigint fixtures.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module tb_posit_mac_quire;
    logic clk=1'b0;
    logic rst_n=1'b0;
    logic in_valid=1'b0;
    wire in_ready;
    logic [1:0] q_cmd=2'd0;
    logic [31:0] a=32'b0, b=32'b0;
    logic [3:0] cfg_n=4'd12;
    logic [1:0] cfg_ops=2'd1;
    wire out_valid;
    logic out_ready=1'b0;
    wire [1:0] out_cmd;
    wire [31:0] d;
    wire [4:0] flags;
    wire q_overflow;
    integer fd, fields, cmd_i, n_i, ops_i, abort_i;
    integer count_i, nar_i, loss_i, cut_i;
    logic [31:0] a_i,b_i,d_i;
    logic [4:0] flags_i;
    logic [971:0] q_i;
    string vector_path;
    integer accepted=0, completed=0, aborted=0, commits=0, stalls=0;
    integer invalid_checks=0;
    integer min_latency[2:0], max_latency[2:0];

    always #5 clk=~clk;
    posit_mac_quire dut (
        .clk (clk),
        .rst_n (rst_n),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .q_cmd (q_cmd),
        .a (a),
        .b (b),
        .cfg_n (cfg_n),
        .cfg_ops (cfg_ops),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .out_cmd (out_cmd),
        .d (d),
        .flags (flags),
        .q_overflow (q_overflow)
    );

    task automatic reset_epoch;
        begin
            @(negedge clk);
            rst_n=1'b0;in_valid=1'b0;out_ready=1'b0;
            #2;
            if (in_ready !== 1'b0 || out_valid !== 1'b0) $fatal(1,"reset gates");
            repeat(5) @(negedge clk);
            rst_n=1'b1;
            repeat(12) @(negedge clk);
            q_cmd=2'd0;cfg_n=4'd12;cfg_ops=2'd1;
            #2;
            if (in_ready !== 1'b1 || out_valid !== 1'b0 || dut.u_wrapper.q_value !== 972'b0)
                $fatal(1,"startup/Q reset");
        end
    endtask

    task automatic reject(input logic [1:0] command,input logic [3:0] n,input logic [1:0] ops);
        begin
            @(negedge clk);q_cmd=command;cfg_n=n;cfg_ops=ops;in_valid=1'b1;out_ready=1'b1;
            repeat(4) begin
                @(posedge clk);#2;
                if (in_ready !== 1'b0 || out_valid !== 1'b0) $fatal(1,"invalid/capacity accepted");
                invalid_checks=invalid_checks+1;
            end
            @(negedge clk);in_valid=1'b0;q_cmd=2'd3;
        end
    endtask

    task automatic check_commit;
        begin
            if (dut.u_wrapper.bank_done === 1'b1) begin
                if (cmd_i == 2) $fatal(1,"READ committed bank");
                if (dut.u_wrapper.q_value !== q_i || dut.u_wrapper.q_count !== 11'(count_i)
                    || dut.u_wrapper.q_nar !== 1'(nar_i) || dut.u_wrapper.q_loss !== 1'(loss_i)
                    || dut.u_wrapper.q_cut !== 1'(cut_i) || dut.u_wrapper.q_invalid !== 1'b0)
                    $fatal(1,"Q checkpoint row=%0d",accepted);
                commits=commits+1;
            end
        end
    endtask

    task automatic transaction;
        integer timeout, elapsed;
        logic reset_now;
        logic [39:0] held;
        time accepted_at;
        integer latency;
        begin
            @(negedge clk);
            q_cmd=2'(cmd_i);a=a_i;b=b_i;cfg_n=4'(n_i);cfg_ops=2'(ops_i);
            in_valid=1'b1;out_ready=1'b0;
            #2;timeout=0;
            while (in_ready !== 1'b1 && timeout<100) begin
                @(negedge clk);#2;timeout=timeout+1;
            end
            if (in_ready !== 1'b1) $fatal(1,"accept timeout row=%0d",accepted);
            @(posedge clk);#2;accepted=accepted+1;accepted_at=$time;
            in_valid=1'b0;a=~a_i;b=~b_i;cfg_n=4'd15;cfg_ops=2'd3;q_cmd=2'd3;
            elapsed=0;reset_now=1'b0;
            begin : wait_response
                while (out_valid !== 1'b1 && elapsed<160) begin
                    check_commit();
                    if ((abort_i==1 && elapsed==2) || (abort_i==3 && dut.u_wrapper.bank_done===1'b1)) begin
                        reset_now=1'b1;
                        disable wait_response;
                    end
                    @(posedge clk);#2;elapsed=elapsed+1;
                end
                if (out_valid !== 1'b1) $fatal(1,"response timeout row=%0d",accepted);
                latency=32'(($time-accepted_at)/10);
                if (abort_i==0) begin
                    if (latency<min_latency[cmd_i]) min_latency[cmd_i]=latency;
                    if (latency>max_latency[cmd_i]) max_latency[cmd_i]=latency;
                end
                if (d !== d_i || flags !== flags_i || out_cmd !== 2'(cmd_i) || q_overflow !== 1'b0)
                    $fatal(1,"response row=%0d expected=%h/%h actual=%h/%h",accepted,d_i,flags_i,d,flags);
                if (dut.u_wrapper.q_value !== q_i || dut.u_wrapper.q_count !== 11'(count_i))
                    $fatal(1,"READ/ACK changed Q");
                held={out_cmd,d,flags,q_overflow};
                repeat(4) begin
                    @(posedge clk);#2;
                    if (out_valid !== 1'b1 || {out_cmd,d,flags,q_overflow} !== held || in_ready !== 1'b0)
                        $fatal(1,"stall stability/capacity");
                    stalls=stalls+1;
                end
                if (abort_i==2) reset_now=1'b1;
            end
            if (reset_now) begin
                aborted=aborted+1;reset_epoch();
            end else begin
                @(negedge clk);out_ready=1'b1;
                @(posedge clk);#2;completed=completed+1;
                @(negedge clk);out_ready=1'b0;
                if (count_i==1024) reject(2'd1,4'd12,2'd1);
            end
        end
    endtask

    initial begin
        for(integer i=0;i<3;i=i+1) begin min_latency[i]=10000;max_latency[i]=0;end
        if (!$value$plusargs("VECTORS=%s",vector_path)) $fatal(1,"VECTORS required");
        reset_epoch();
        reject(2'd3,4'd12,2'd1);
        reject(2'd1,4'd13,2'd1);reject(2'd1,4'd14,2'd1);reject(2'd1,4'd15,2'd1);
        reject(2'd1,4'd12,2'd2);reject(2'd1,4'd12,2'd3);
        fd=$fopen(vector_path,"r");if (!fd) $fatal(1,"missing vectors");
        while (!$feof(fd)) begin
            fields=$fscanf(fd,"%d %h %h %d %d %d %h %h %h %d %d %d %d\n",
                           cmd_i,a_i,b_i,n_i,ops_i,abort_i,d_i,flags_i,q_i,count_i,nar_i,loss_i,cut_i);
            if (fields==13) transaction();
            else if (fields!=-1) $fatal(1,"malformed fixture");
        end
        $fclose(fd);
        if (accepted != completed+aborted) $fatal(1,"accepted accounting");
        repeat(10) begin @(posedge clk);#2;if(out_valid!==1'b0)$fatal(1,"duplicate response");end
        $display("QUIRE_MODELSIM_PASS accepted=%0d completed=%0d aborted=%0d commits=%0d stalls=%0d invalid_checks=%0d mismatches=0",
                 accepted,completed,aborted,commits,stalls,invalid_checks);
        for(integer i=0;i<3;i=i+1)
            $display("QUIRE_RESPONSE_LATENCY cmd=%0d min=%0d max=%0d cycles; accept to first valid, before imposed hold",
                     i,min_latency[i],max_latency[i]);
        $finish;
    end
    initial begin
        #1000000000;$fatal(1,"quire watchdog");
    end
endmodule
// End of tb_posit_mac_quire.sv
