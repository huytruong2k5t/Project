`timescale 1ns/1ps
module tb_week9_frontend;
    wire [9:0] done;

    ops_frontend_checker #(.F(1), .FW(1)) ops1 (.done(done[0]));
    ops_frontend_checker #(.F(5), .FW(5)) ops5 (.done(done[1]));
    ops_frontend_checker #(.F(12), .FW(12)) ops12 (.done(done[2]));
    ops_frontend_checker #(.F(26), .FW(12)) ops26 (.done(done[3]));
    ops_frontend_checker #(.F(27), .FW(12)) ops27 (.done(done[4]));
    sac_frontend_checker #(.W_X(1)) sac1 (.done(done[5]));
    sac_frontend_checker #(.W_X(5)) sac5 (.done(done[6]));
    sac_frontend_checker #(.W_X(12)) sac12 (.done(done[7]));
    sac_frontend_checker #(.W_X(26)) sac26 (.done(done[8]));
    sac_frontend_checker #(.W_X(27)) sac27 (.done(done[9]));

    initial begin
        wait (&done);
        $display("WEEK9 FRONTEND ALL PASS");
        $finish;
    end
    initial begin
        #1000000;
        $fatal(1, "week9 frontend timeout");
    end
endmodule
