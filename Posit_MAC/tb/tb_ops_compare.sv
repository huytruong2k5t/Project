`timescale 1ns/1ps
module tb_ops_compare;
    reg clk=0, rst=1;
    reg [11:0] a=0,b=0;
    wire predict_swap,minpop_swap;
    integer checks=0, i,j,k;
    reg [31:0] state=314159;
    ops_compare_top #(.POLICY(0)) baseline(clk,rst,a,b,predict_swap);
    ops_compare_top #(.POLICY(1)) variant(clk,rst,a,b,minpop_swap);
    always #5 clk=~clk;
    function automatic integer ref_error(input integer f);
        integer m,e,sign,ap,t,step,up;
        begin
            m=128+f;e=0;sign=1;ap=0;
            for(step=0;step<2;step=step+1) if(m!=0) begin
                up=(m>=192);
                ap=ap+sign*(1<<(7+e+up));
                if(up!=0) begin t=255-m;sign=-sign;end
                else t=m-128;
                if(t==0) m=0;
                else begin
                    while(t<128) begin t=t*2;e=e-1;end
                    m=t;
                end
            end
            ref_error=128+f-ap;
            if(ref_error<0) ref_error=-ref_error;
        end
    endfunction
    function automatic integer ref_pop(input integer f);
        integer v;
        begin
            v=f;ref_pop=0;
            while(v>0) begin ref_pop=ref_pop+v%2;v=v/2;end
        end
    endfunction
    task verify(input [11:0] x,input [11:0] y);
        reg expected_p,expected_m;
        begin
            expected_p=ref_error(y>>5)<ref_error(x>>5);
            expected_m=ref_pop(y)<ref_pop(x);
            @(negedge clk);a=x;b=y;
            @(posedge clk);@(posedge clk);#1;
            if(predict_swap!==expected_p || minpop_swap!==expected_m) begin
                $display("FAIL a=%h b=%h predict=%b/%b minpop=%b/%b",x,y,predict_swap,expected_p,minpop_swap,expected_m);
                $fatal(1,"OPS mismatch");
            end
            checks=checks+1;
        end
    endtask
    initial begin
        @(posedge clk);#1;
        if(predict_swap!==0 || minpop_swap!==0) $fatal(1,"reset mismatch");
        @(negedge clk);rst=0;
        for(i=0;i<128;i=i+1) for(j=0;j<128;j=j+1)
            verify((i<<5)|(j%32),(j<<5)|(i%32));
        for(k=0;k<100000;k=k+1) begin
            state=state^(state<<13);state=state^(state>>17);state=state^(state<<5);
            i=state&4095;
            state=state^(state<<13);state=state^(state>>17);state=state^(state<<5);
            verify(i,state&4095);
        end
        $display("OPS_COMPARE PASS checks=%0d seed=314159 generator=xorshift32",checks);
        $finish;
    end
endmodule
