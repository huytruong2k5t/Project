//-----------------------------------------------------------------------------
// File          : tb_fixed32_3_nf.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-13
// Description   : Four-state NF protocol/flags/reset/accumulator replay.
//-----------------------------------------------------------------------------
// $Source: $ $Revision: 1.0 $ $Log: W11 pilot against independent checked fixture. $
module tb_fixed32_3_nf;
    localparam int NB = 32;
    localparam int ES = 3;
    // Historical fixture stores the original q+10 schedule.
    localparam int EXTRA_PRODUCT_STAGES = 2;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst_n;
    logic in_valid;
    wire in_ready;
    wire out_valid;
    logic out_ready;
    logic [NB-1:0] a;
    logic [NB-1:0] b;
    logic [NB-1:0] c;
    logic cfg_mode;
    logic [3:0] cfg_n;
    logic [1:0] cfg_ops;
    logic acc_mode;
    logic acc_clr;
    wire [NB-1:0] d;
    wire [4:0] flags;
    logic [31:0] a_file, b_file, c_file, expected;
    logic [31:0] flags_file;
    integer mode_file, n_file, ops_file, acc_file, clear_file;
    integer reset_file, abort_delay, latency_file;
    integer file_handle, fields, rows, completed, aborted, stalls;
    integer wait_cycles, cycle_count, accepted_cycle, first_valid_cycle;
    integer phase, reset_test;
    logic [NB-1:0] held_d;
    logic [4:0] held_flags;
    reg [2047:0] fixture_dir;
    reg [2303:0] fixture_name;
    posit_mac_nf dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .a(a),
        .b(b),
        .c(c),
        .cfg_mode(cfg_mode),
        .cfg_n(cfg_n),
        .cfg_ops(cfg_ops),
        .acc_mode(acc_mode),
        .acc_clr(acc_clr),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .d(d),
        .flags(flags)
    );
    always @(posedge clk) cycle_count = cycle_count+1;
    always @(posedge clk) begin
        #2;
        if (rst_n && dut.u_wrapper.meta_sync2 === 1'b1) begin
            if ((^d) === 1'bx || (^flags) === 1'bx || out_valid === 1'bx)
                $fatal(1,"unknown output after startup");
            if (dut.u_wrapper.core_error === 1'b1)
                $fatal(1,"core invariant failed");
        end
    end
    task reset_dut;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            in_valid = 1'b0;
            out_ready = 1'b0;
            repeat (3) begin
                @(posedge clk); #2;
                if (in_ready !== 1'b0 || out_valid !== 1'b0) $fatal(1,"reset gating");
            end
            @(negedge clk); rst_n = 1'b1;
            repeat (8) @(negedge clk);
            if (out_valid !== 1'b0) $fatal(1,"pre-reset output escaped");
        end
    endtask
    initial begin
        cycle_count=0; rows=0; completed=0; aborted=0; stalls=0;
        rst_n=0; in_valid=0; out_ready=0;
        a=0; b=0; c=0; cfg_mode=0; cfg_n=0; cfg_ops=0; acc_mode=0; acc_clr=0;
        if (!$value$plusargs("VECTOR_DIR=%s",fixture_dir)) $fatal(1,"fixture required");
        $sformat(fixture_name,"%0s/mac_%0d_%0d.txt",fixture_dir,NB,ES);
        file_handle=$fopen(fixture_name,"r");
        if (!file_handle) $fatal(1,"missing fixture");
        reset_dut();
        // Invalid OPS/n and clear-without-acc requests must not handshake.
        for (phase=0;phase<4;phase=phase+1) begin
            @(negedge clk);
            in_valid=1;
            cfg_mode=1;
            cfg_ops=(phase<2) ? 2+phase : 0;
            cfg_n=(phase==2) ? 9 : 0;
            acc_clr=(phase==3);
            repeat(3) begin @(posedge clk); #2;
                if(in_ready !== 0) $fatal(1,"invalid config accepted");
            end
        end
        @(negedge clk); in_valid=0; acc_clr=0;
        while (!$feof(file_handle)) begin
            fields=$fscanf(file_handle,"%h %h %h %h %h %d %d %d %d %d %d %d %d\n",
                a_file,b_file,c_file,expected,flags_file,mode_file,n_file,ops_file,
                acc_file,clear_file,reset_file,abort_delay,latency_file);
            if(fields==13) begin
                if(reset_file) reset_dut();
                @(negedge clk);
                a=a_file[NB-1:0]; b=b_file[NB-1:0]; c=c_file[NB-1:0];
                cfg_mode=(mode_file!=0); cfg_n=n_file[3:0]; cfg_ops=ops_file[1:0];
                acc_mode=(acc_file!=0); acc_clr=(clear_file!=0);
                in_valid=1; out_ready=0;
                wait_cycles=0;
                do begin
                    @(posedge clk);
                    wait_cycles=wait_cycles+1;
                    if(wait_cycles>100) $fatal(1,"input deadlock");
                end while(!in_ready);
                #2; accepted_cycle=cycle_count;
                @(negedge clk); in_valid=0;
                // Change external context after handshake; stored transaction must survive.
                a='1; b='0; c='1; cfg_mode=~cfg_mode; cfg_n=8; cfg_ops=1;
                acc_mode=~acc_mode; acc_clr=1;
                if(abort_delay) begin
                    repeat(abort_delay) @(negedge clk);
                    reset_dut(); aborted=aborted+1;
                end else begin
                    wait_cycles=0;
                    while(out_valid !== 1'b1) begin
                        @(negedge clk); wait_cycles=wait_cycles+1;
                        if(wait_cycles>100) $fatal(1,"output deadlock/X");
                    end
                    first_valid_cycle=cycle_count;
                    if(first_valid_cycle-accepted_cycle != latency_file+EXTRA_PRODUCT_STAGES)
                        $fatal(1,"latency row%0d observed%0d expected%0d",rows,first_valid_cycle-accepted_cycle,latency_file);
                    if(d !== expected[NB-1:0] || flags !== flags_file[4:0])
                        $fatal(1,"row%0d got%h flags%h expected%h flags%h",rows,d,flags,expected,flags_file);
                    held_d=d; held_flags=flags;
                    repeat((rows%31==0) ? 96 : rows%4) begin
                        @(negedge clk);
                        if(out_valid !== 1 || d !== held_d || flags !== held_flags)
                            $fatal(1,"output stall changed payload");
                        stalls=stalls+1;
                    end
                    out_ready=1;
                    @(posedge clk);
                    @(negedge clk); out_ready=0;
                    completed=completed+1;
                end
                rows=rows+1;
            end else if(fields!=-1) $fatal(1,"bad fixture line");
        end
        repeat(20) @(negedge clk);
        if(out_valid !== 0) $fatal(1,"duplicate output");
        $display("W11 MODELSIM PASS NB=%0d ES=%0d rows=%0d completed=%0d aborted=%0d stalls=%0d mismatches=0",
                 NB,ES,rows,completed,aborted,stalls);
        $finish;
    end
endmodule
