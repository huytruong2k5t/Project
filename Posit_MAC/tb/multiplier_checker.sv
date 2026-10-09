`timescale 1ns/1ps
module multiplier_checker #(
    parameter int NB=32,
    parameter int ES=2,
    parameter int SCHEME=0,
    parameter int ROUNDING=0,
    parameter int CLOCK_PERIOD=10,
    parameter VECTOR_DIR="."
)(
    output bit done=1'b0
);
    logic clk=0;
    always #(CLOCK_PERIOD/2) clk=~clk;
    logic rst_n=0,in_valid=0,out_ready=0,mode=0;
    logic [NB-1:0] a=0,b=0;
    logic [3:0] n=0;
    logic [1:0] ops=0;
    wire in_ready,out_valid;
    wire [NB-1:0] d;
    wire [4:0] flags;
    posit_mul_iter #(.NB(NB),.ES(ES),.ROUND_SCHEME(SCHEME),
        .ROUND_MODE(ROUNDING?"TRUNC":"RNE")) dut (
        .clk(clk),.rst_n(rst_n),.in_valid(in_valid),.in_ready(in_ready),
        .a(a),.b(b),.cfg_mode(mode),.cfg_n(n),.cfg_ops(ops),
        .out_valid(out_valid),.out_ready(out_ready),.d(d),.flags(flags)
    );
    task automatic reset_top;
        @(negedge clk);
        rst_n=0; in_valid=0; out_ready=1;
        repeat(2) begin
            @(posedge clk); #2;
            if(in_ready || out_valid) $fatal(1,"top reset flush failed");
        end
        @(negedge clk); rst_n=1; out_ready=0;
        repeat(3) begin
            @(posedge clk);
            if(in_ready || out_valid) $fatal(1,"top startup too early");
        end
        @(negedge clk);
        wait(in_ready);
    endtask
    initial begin
        int fd,rc,rows,aborts,completed,cycles,expected_latency,stall_cycles,long_stalls;
        longint unsigned v[7:0];
        logic [NB-1:0] held_d;
        logic [4:0] held_flags;
        string fixture_directory;
        rows=0; aborts=0; completed=0; long_stalls=0;
        reset_top();
        // Invalid/reserved configs must not enter either parser.
        @(negedge clk); ops=2; in_valid=1;
        repeat(3) begin @(posedge clk); if(in_ready) $fatal(1,"reserved accepted"); end
        @(negedge clk); ops=0; mode=1; n=9;
        repeat(3) begin @(posedge clk); if(in_ready) $fatal(1,"invalid n accepted"); end
        @(negedge clk); mode=0; n=0; in_valid=0;
        fixture_directory=VECTOR_DIR;
        rc=$value$plusargs("VECTOR_DIR=%s",fixture_directory);
        fd=$fopen($sformatf("%s/mul_%0d_%0d_%0d_%0d.txt",fixture_directory,NB,ES,SCHEME,ROUNDING),"r");
        if(!fd) $fatal(1,"missing multiplier fixture");
        while(!$feof(fd)) begin
            rc=$fscanf(fd,"%h %h %h %h %h %h %h %h\n",v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7]);
            if(rc!=8) $fatal(1,"malformed multiplier fixture");
            @(negedge clk);
            a=v[0][NB-1:0]; b=v[1][NB-1:0]; mode=v[2][0]; n=v[3][3:0]; ops=v[4][1:0];
            wait(in_ready);
            in_valid=1; out_ready=0;
            @(posedge clk); #2;
            cycles=0;
            @(negedge clk);
            // A held competing transaction must not enter the occupied slot.
            a=~a; b=~b; mode=~mode; n=~n; ops=0;
            if(rows%211==100) begin
                // Rotate reset across parser/core/drain/output-stall phases.
                repeat(rows%31) @(negedge clk);
                mode=0; n=0; ops=0;
                reset_top();
                repeat(40) begin @(posedge clk); #2; if(out_valid) $fatal(1,"ghost after reset"); end
                aborts++;
            end else begin
                while(!out_valid) begin
                    @(posedge clk); #2; cycles++;
                    if(in_ready) $fatal(1,"slot overwrite");
                    if(cycles>50) $fatal(1,"multiplier timeout");
                    if(dut.u_wrapper.core_error) $fatal(1,"core error in wrapper");
                end
                expected_latency=((v[7]==0)?1:v[7])+6+(ROUNDING?0:1);
                if(cycles!=expected_latency || d!==v[5][NB-1:0] || flags!==v[6][4:0])
                    $fatal(1,"MULTIPLIER FAIL NB=%0d ES=%0d scheme=%0d rounding=%0d row=%0d a=%h b=%h cycles=%0d/%0d d=%h/%h flags=%h/%h",
                        NB,ES,SCHEME,ROUNDING,rows,v[0],v[1],cycles,expected_latency,d,v[5],flags,v[6]);
                held_d=d; held_flags=flags;
                stall_cycles=(rows%97==7)?96:rows%5;
                if(stall_cycles==96) long_stalls++;
                repeat(stall_cycles) begin
                    @(posedge clk); #2;
                    if(!out_valid || d!==held_d || flags!==held_flags || in_ready) $fatal(1,"output stall instability");
                end
                @(negedge clk); in_valid=0; out_ready=1;
                @(posedge clk); #2;
                if(out_valid) $fatal(1,"duplicated output");
                completed++;
            end
            rows++;
            if(rows%100000==0) $display("MUL PROGRESS NB=%0d ES=%0d scheme=%0d rounding=%0d rows=%0d",NB,ES,SCHEME,ROUNDING,rows);
        end
        $fclose(fd);
        $display("MULTIPLIER PASS NB=%0d ES=%0d scheme=%0d rounding=%0d rows=%0d completed=%0d reset_aborts=%0d long_stalls=%0d",NB,ES,SCHEME,ROUNDING,rows,completed,aborts,long_stalls);
        done=1;
    end
endmodule
