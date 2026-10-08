`timescale 1ns/1ps
module core_checker #(
    parameter int F=27,
    parameter int FW=(F<12)?F:12,
    parameter int SCHEME=0
)(
    output bit done=1'b0
);
    localparam int AW=(2*F+2>FW+4)?2*F+2:FW+4;
    localparam int IW=$clog2(((F>8)?F:8)+1);
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0,valid=0,release_result=0,mode=0,sign_i=0,input_cut=0;
    logic [F-1:0] x;
    logic [F:0] y;
    logic [3:0] n;
    logic signed [10:0] sf_i;
    wire ready,run_ready,core_done,sticky,numerical,cut,sign_o,cut_o,mode_o,error;
    wire [AW-1:0] acc;
    wire [IW-1:0] iterations;
    wire signed [10:0] sf_o;
    mul_iter_core #(.FRAC_MAX(F),.FRAC_W(FW),.ROUND_SCHEME(SCHEME)) dut (
        .clk(clk),.reset_n(reset_n),.launch_valid(valid),.launch_ready(ready),
        .release_result(release_result),.x_frac(x),.y_mant(y),.cfg_mode(mode),.cfg_n(n),
        .sign_i(sign_i),.sf_i(sf_i),.input_cut_i(input_cut),.run_ready(run_ready),
        .core_done(core_done),.acc(acc),.sticky_acc(sticky),.numerical_tail(numerical),
        .iterations_done(iterations),.approx_cut(cut),.sign_o(sign_o),.sf_o(sf_o),
        .input_cut_o(cut_o),.mode_o(mode_o),.state_error(error)
    );
    task automatic reset_core;
        @(negedge clk);
        reset_n=0;
        valid=0;
        release_result=0;
        #2;
        if(ready || core_done) $fatal(1,"core reset not flushing");
        repeat(2) @(negedge clk);
        reset_n=1;
        repeat(2) begin
            @(posedge clk);
            if(ready) $fatal(1,"core startup too early");
        end
        @(negedge clk);
        wait(ready);
    endtask
    initial begin
        int fd,rc,sf_e,sign_e,cut_e,cycles,resets;
        longint unsigned v[8:0];
        int rows;
        rows=0; resets=0;
        reset_core();
        fd=$fopen($sformatf("core_%0d_%0d.txt",F,SCHEME),"r");
        if(!fd) $fatal(1,"missing core fixture");
        while(!$feof(fd)) begin
            rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h %d %d %d\n",
                v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7],v[8],sf_e,sign_e,cut_e);
            if(rc!=12) $fatal(1,"malformed core fixture");
            @(negedge clk);
            wait(ready);
            mode=v[0][0]; x=v[1][F-1:0]; y=v[2][F:0]; n=v[3][3:0];
            sf_i=sf_e[10:0]; sign_i=sign_e[0]; input_cut=cut_e[0]; valid=1;
            @(posedge clk);
            #2;
            cycles=0;
            // Attempt another launch and mutate every context field while busy.
            @(negedge clk);
            mode=~mode; x=~x; y=~y; n=~n; sf_i=~sf_i; sign_i=~sign_i; input_cut=~input_cut;
            if(rows%97==0) begin
                repeat(rows%3) @(negedge clk);
                reset_core();
                // Reset aborts this transaction, with no old output after startup.
                repeat(F+5) begin
                    @(posedge clk); #2;
                    if(core_done) $fatal(1,"core ghost after reset");
                end
                resets++;
            end else begin
                while(!core_done) begin
                    @(posedge clk); #2;
                    cycles++;
                    if(ready || error) $fatal(1,"core context/control error F=%0d row=%0d",F,rows);
                    if(cycles>F+5) $fatal(1,"core timeout");
                end
                if(cycles != ((v[7]==0)?3:v[7]+2) || acc!==v[4][AW-1:0] ||
                    sticky!==v[5][0] || numerical!==v[6][0] || iterations!==v[7][IW-1:0] ||
                    cut!==v[8][0] || sf_o!==sf_e[10:0] || sign_o!==sign_e[0] ||
                    cut_o!==cut_e[0] || mode_o!==v[0][0])
                    $fatal(1,"CORE FAIL F=%0d scheme=%0d row=%0d cycles=%0d acc=%h/%h it=%0d/%0d",
                        F,SCHEME,rows,cycles,acc,v[4],iterations,v[7]);
                @(negedge clk); valid=0;
                repeat(3) begin
                    @(posedge clk); #2;
                    if(ready || core_done || acc!==v[4][AW-1:0]) $fatal(1,"core result not retained");
                end
                @(negedge clk); release_result=1;
                @(negedge clk); release_result=0;
            end
            rows++;
        end
        $fclose(fd);
        $display("CORE PASS F=%0d scheme=%0d transactions=%0d resets=%0d",F,SCHEME,rows,resets);
        done=1;
    end
endmodule
