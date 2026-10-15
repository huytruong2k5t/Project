//-----------------------------------------------------------------------------
// File          : tb_normalize_refactor.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Eleven profiles for normalization candidate equivalence.
// $Source: $ $Revision: 1.0 $ $Log: Main formats, F=2/3 and wide signed SF. $
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module tb_normalize_refactor;
    wire [10:0] done;
    normalize_refactor_checker #(.NB(8), .ES(0)) c0 (.done(done[0]));
    normalize_refactor_checker #(.NB(16), .ES(1)) c1 (.done(done[1]));
    normalize_refactor_checker #(.NB(32), .ES(2)) c2 (.done(done[2]));
    normalize_refactor_checker #(.NB(32), .ES(3)) c3 (.done(done[3]));
    normalize_refactor_checker #(.NB(5), .ES(0)) c4 (.done(done[4]));
    normalize_refactor_checker #(.NB(6), .ES(1)) c5 (.done(done[5]));
    normalize_refactor_checker #(.NB(7), .ES(1)) c6 (.done(done[6]));
    normalize_refactor_checker #(.NB(16), .ES(10)) c7 (.done(done[7]));
    normalize_refactor_checker #(.NB(32), .ES(27)) c8 (.done(done[8]));
    normalize_refactor_checker #(.NB(32), .ES(3), .SF_W(13)) c9 (.done(done[9]));
    normalize_refactor_checker #(.NB(32), .ES(2), .SF_W(12)) c10 (.done(done[10]));
    initial begin
        wait (&done);
        $display("NORM MATRIX PASS profiles=11 candidates=2 mismatch=0");
        $finish;
    end
    initial begin
        #1000000;
        $fatal(1, "NORM timeout");
    end
endmodule
// End of tb_normalize_refactor.sv
