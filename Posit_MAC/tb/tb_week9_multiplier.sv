`timescale 1ns/1ps
module tb_week9_multiplier;
    wire [15:0] done;
    for(genvar f=0;f<4;f++) begin : g_format
        localparam int NB=(f==0)?8:(f==1)?16:32;
        localparam int ES=(f==0)?0:(f==1)?1:(f==2)?2:3;
        for(genvar s=0;s<2;s++) begin : g_scheme
            for(genvar r=0;r<2;r++) begin : g_round
                multiplier_checker #(.NB(NB),.ES(ES),.SCHEME(s),.ROUNDING(r)) u_check (
                    .done(done[4*f+2*s+r])
                );
            end
        end
    end
    initial begin
        wait(&done);
        $display("WEEK9 MULTIPLIER ALL PASS");
        $finish;
    end
    initial begin
        #(64'd1000000000000);
        $fatal(1,"multiplier suite watchdog");
    end
endmodule
