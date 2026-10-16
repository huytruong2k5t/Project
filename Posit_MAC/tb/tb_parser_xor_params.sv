`timescale 1ns/1ps
module tb_parser_xor_params;
    wire [8:0] done;
    parser_xor_param_checker #(.NB(4), .ES(0)) p4 (.done(done[0]));
    parser_xor_param_checker #(.NB(5), .ES(1)) p5 (.done(done[1]));
    parser_xor_param_checker #(.NB(7), .ES(0)) p7 (.done(done[2]));
    parser_xor_param_checker #(.NB(9), .ES(5)) p9 (.done(done[3]));
    parser_xor_param_checker #(.NB(17), .ES(13)) p17 (.done(done[4]));
    parser_xor_param_checker #(.NB(31), .ES(27)) p31 (.done(done[5]));
    parser_xor_param_checker #(.NB(32), .ES(28)) p32 (.done(done[6]));
    parser_xor_param_checker #(.NB(32), .ES(3), .SF_W(9)) p32_min (.done(done[7]));
    parser_xor_param_checker #(.NB(32), .ES(2), .SF_W(40)) p32_wide (.done(done[8]));
    initial begin
        wait (&done);
        $display("PARSER_XOR_PARAMS ALL PASS");
        $finish;
    end
    initial begin
        #1000000;
        $fatal(1, "Parameter test watchdog");
    end
endmodule
