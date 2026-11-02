`timescale 1ns/1ps
// Transaction replay of current NF/F. No historical fixed-cycle latency assumption.
module tb_refactored_mac;
    parameter bit FUSED=0;
    logic clk=0; always #5 clk=~clk;
    logic rst_n=0,in_valid=0,out_ready=0;
    wire in_ready,out_valid;
    logic [31:0] a=0,b=0,c=0;
    logic acc_mode=0,acc_clr=0,cfg_mode=1;
    logic [3:0] cfg_n=0;
    logic [1:0] cfg_ops=0;
    wire [31:0] d;
    wire [4:0] flags;
    generate if (FUSED) begin:g_f
        posit_mac_f dut(.*);
    end else begin:g_nf
        posit_mac_nf dut(.*);
    end endgenerate
    integer rows=0,accepted=0,completed=0,aborted=0,stalls=0,latency_min=10000,latency_max=0;
    integer fd,fields,n,ops,mode,clear,abort_kind,timeout,latency;
    reg [31:0] av,bv,cv,expected;
    reg [4:0] expected_flags;
    reg [2047:0] vector_path;
    logic held=0;
    logic [36:0] held_payload=0;
    always @(posedge clk) begin
        if (!rst_n) held=0;
        else begin
            if (held) begin
                if (out_valid !== 1'b1 || {d,flags} !== held_payload)
                    $fatal(1,"output hold violation row=%0d",rows);
                stalls=stalls+1;
            end
            held=(out_valid && !out_ready);
            held_payload={d,flags};
            if (out_valid && $isunknown({d,flags})) $fatal(1,"X in valid output");
        end
    end
    task automatic reset_dut;
        @(negedge clk);rst_n=0;in_valid=0;out_ready=0;
        cfg_mode=1;cfg_n=0;cfg_ops=0;acc_mode=0;acc_clr=0;
        repeat(4) @(negedge clk);
        rst_n=1;
        timeout=0;
        while(in_ready !== 1) begin
            @(negedge clk);timeout=timeout+1;
            if(out_valid !== 0 || timeout>30) $fatal(1,"reset/startup failure");
        end
    endtask
    task automatic invalid_request(input logic [3:0] nn,input logic [1:0] oo,input logic mm,input logic cc);
        @(negedge clk);in_valid=1;cfg_n=nn;cfg_ops=oo;acc_mode=mm;acc_clr=cc;
        repeat(6) begin
            @(posedge clk);
            if(in_ready !== 0 || out_valid !== 0) $fatal(1,"invalid configuration accepted");
        end
        @(negedge clk);in_valid=0;cfg_n=0;cfg_ops=0;acc_mode=0;acc_clr=0;
    endtask
    initial begin
        if(!$value$plusargs("VECTORS=%s",vector_path)) $fatal(1,"VECTORS required");
        fd=$fopen(vector_path,"r");if(!fd) $fatal(1,"missing fixture");
        reset_dut();
        invalid_request(15,0,0,0);
        invalid_request(0,3,0,0);
        invalid_request(0,0,0,1);
        if(!FUSED) invalid_request(9,0,0,0);
        while(!$feof(fd)) begin
            fields=$fscanf(fd,"%h %h %h %d %d %d %d %h %h %d\n",av,bv,cv,n,ops,mode,clear,expected,expected_flags,abort_kind);
            if(fields==10) begin
                @(negedge clk);
                a=av;b=bv;c=cv;cfg_mode=1;cfg_n=n;cfg_ops=ops;acc_mode=mode;acc_clr=clear;in_valid=1;out_ready=0;
                timeout=0;
                do begin
                    @(posedge clk);timeout=timeout+1;
                    if(timeout>200) $fatal(1,"input timeout row=%0d",rows);
                end while(in_ready !== 1);
                accepted=accepted+1;
                @(negedge clk);in_valid=0;
                // Change live ports after accept; only stored context may affect this result.
                a=~av;b=~bv;c=~cv;cfg_n=15;cfg_ops=3;cfg_mode=0;acc_mode=~mode;acc_clr=1;
                if(abort_kind==1) begin
                    reset_dut();aborted=aborted+1;
                end else begin
                    latency=0;
                    while(out_valid !== 1) begin
                        @(negedge clk);latency=latency+1;
                        if(latency>200) $fatal(1,"output timeout row=%0d",rows);
                    end
                    if(d !== expected || flags !== expected_flags)
                        $fatal(1,"F=%0d row=%0d n=%0d ops=%0d got=%h/%h expected=%h/%h",FUSED,rows,n,ops,d,flags,expected,expected_flags);
                    if(latency<latency_min)latency_min=latency;
                    if(latency>latency_max)latency_max=latency;
                    repeat(rows%11==0 ? 25 : rows%4) @(negedge clk);
                    if(abort_kind==2) begin
                        reset_dut();aborted=aborted+1;
                    end else begin
                        out_ready=1;
                        @(posedge clk);
                        @(negedge clk);out_ready=0;completed=completed+1;
                        repeat(2) begin
                            @(negedge clk);
                            if(out_valid !== 0) $fatal(1,"duplicate output");
                        end
                    end
                end
                rows=rows+1;
                cfg_mode=1;cfg_n=0;cfg_ops=0;acc_mode=0;acc_clr=0;
            end else if(fields!=-1) $fatal(1,"malformed fixture");
        end
        $fclose(fd);
        if(rows<1000 || completed+aborted!=accepted || stalls==0 || aborted==0) $fatal(1,"incomplete suite/counts");
        $display("MAC_REFACTOR_PASS F=%0d rows=%0d accepted=%0d completed=%0d aborted=%0d stalls=%0d latency_observed=%0d..%0d",FUSED,rows,accepted,completed,aborted,stalls,latency_min,latency_max);
        $finish;
    end
    initial begin #100000000;$fatal(1,"MAC watchdog");end
endmodule
