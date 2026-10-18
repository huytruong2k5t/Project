`timescale 1ns/1ps
module tb_opt12_parser;
    wire [12:0] done;
    opt12_parser_checker #(.NB(4), .ES(0)) p4 (.done(done[0]));
    opt12_parser_checker #(.NB(5), .ES(1)) p5 (.done(done[1]));
    opt12_parser_checker #(.NB(7), .ES(0)) p7 (.done(done[2]));
    opt12_parser_checker #(.NB(9), .ES(5)) p9 (.done(done[3]));
    opt12_parser_checker #(.NB(17), .ES(13)) p17 (.done(done[4]));
    opt12_parser_checker #(.NB(31), .ES(27)) p31 (.done(done[5]));
    opt12_parser_checker #(.NB(32), .ES(28)) p32 (.done(done[6]));
    opt12_parser_checker #(.NB(32), .ES(3), .SF_W(9)) p32_min (.done(done[7]));
    opt12_parser_checker #(.NB(32), .ES(2), .SF_W(40)) p32_wide (.done(done[8]));
    opt12_parser_checker #(.NB(8), .ES(0)) p8 (.done(done[9]));
    opt12_parser_checker #(.NB(16), .ES(1)) p16 (.done(done[10]));
    opt12_parser_checker #(.NB(32), .ES(2)) p32e2 (.done(done[11]));
    opt12_parser_checker #(.NB(32), .ES(3)) p32e3 (.done(done[12]));
    initial begin
        wait (&done);
        $display("OPT12 PARSER MATRIX PASS");
        $finish;
    end
    initial begin
        #1000000;
        $fatal(1, "Parameter test watchdog");
    end
endmodule
