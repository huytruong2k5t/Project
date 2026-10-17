//-----------------------------------------------------------------------------
// File          : tb_opt02b_align.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Four accepted formats plus fraction/scale-width edge profiles.
// $Source: $ $Revision: 1.0 $ $Log: Parallel alignment candidate verification. $
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module tb_opt02b_align;
    wire [10:0] done;
    opt02b_align_checker #(.NB(8), .ES(0)) c0 (.done(done[0]));
    opt02b_align_checker #(.NB(16), .ES(1)) c1 (.done(done[1]));
    opt02b_align_checker #(.NB(32), .ES(2)) c2 (.done(done[2]));
    opt02b_align_checker #(.NB(32), .ES(3)) c3 (.done(done[3]));
    opt02b_align_checker #(.NB(5), .ES(0)) c4 (.done(done[4]));
    opt02b_align_checker #(.NB(6), .ES(1)) c5 (.done(done[5]));
    opt02b_align_checker #(.NB(7), .ES(1)) c6 (.done(done[6]));
    opt02b_align_checker #(.NB(16), .ES(10)) c7 (.done(done[7]));
    opt02b_align_checker #(.NB(32), .ES(27)) c8 (.done(done[8]));
    opt02b_align_checker #(.NB(32), .ES(3), .SF_W(13)) c9 (.done(done[9]));
    opt02b_align_checker #(.NB(32), .ES(2), .SF_W(12)) c10 (.done(done[10]));
    initial begin
        wait (&done);
        $display("ALIGN MATRIX PASS profiles=11 mismatch=0");
        $finish;
    end
    initial begin
        #200000;
        $fatal(1,"ALIGN timeout");
    end
endmodule
// End of tb_opt02b_align.sv
