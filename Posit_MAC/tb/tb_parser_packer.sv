// File: tb_parser_packer.sv -- actual parser/packer identity and protocol.
`timescale 1ns/1ps
module tb_parser_packer;
    wire [7:0] done;
    parser_packer_checker #(.NB(8), .ES(0), .ROUND_MODE("RNE")) u0 (.done(done[0]));
    parser_packer_checker #(.NB(8), .ES(0), .ROUND_MODE("TRUNC")) u1 (.done(done[1]));
    parser_packer_checker #(.NB(16), .ES(1), .ROUND_MODE("RNE")) u2 (.done(done[2]));
    parser_packer_checker #(.NB(16), .ES(1), .ROUND_MODE("TRUNC")) u3 (.done(done[3]));
    parser_packer_checker #(.NB(32), .ES(2), .ROUND_MODE("RNE")) u4 (.done(done[4]));
    parser_packer_checker #(.NB(32), .ES(2), .ROUND_MODE("TRUNC")) u5 (.done(done[5]));
    parser_packer_checker #(.NB(32), .ES(3), .ROUND_MODE("RNE")) u6 (.done(done[6]));
    parser_packer_checker #(.NB(32), .ES(3), .ROUND_MODE("TRUNC")) u7 (.done(done[7]));
    initial begin
        wait (&done);
        $display("PARSER PACKER ALL PASS");
        $finish;
    end
endmodule
