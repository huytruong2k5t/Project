`timescale 1ns/1ps
module tb_week9_core;
    wire [9:0] done;
    for(genvar i=0;i<5;i++) begin : g_width
        localparam int F=(i==0)?1:(i==1)?5:(i==2)?12:(i==3)?26:27;
        for(genvar s=0;s<2;s++) begin : g_scheme
            core_checker #(.F(F),.SCHEME(s)) u_check (.done(done[2*i+s]));
        end
    end
    initial begin
        wait(&done);
        $display("WEEK9 CORE ALL PASS");
        $finish;
    end
    initial begin
        #10000000;
        $fatal(1,"core suite timeout");
    end
endmodule
