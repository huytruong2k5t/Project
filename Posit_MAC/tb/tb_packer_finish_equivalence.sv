//-----------------------------------------------------------------------------
// File          : tb_packer_finish_equivalence.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-07
// Description   : Top-level P2 equivalence for NB8, NB16 and NB32.
//-----------------------------------------------------------------------------
// $Revision: 1.0 $
// $Log: P2 single-adder equivalence regression. $

`timescale 1ns/1ps
module tb_packer_finish_equivalence;
    wire done8, done16, done32;
    packer_finish_equivalence_checker #(.NB(8)) u8 (.done(done8));
    packer_finish_equivalence_checker #(.NB(16)) u16 (.done(done16));
    packer_finish_equivalence_checker #(.NB(32)) u32 (.done(done32));
    initial begin
        wait (done8 && done16 && done32);
        $display("P2 EQUIVALENCE ALL PASS");
        $finish;
    end
    initial begin
        #1000000;
        $fatal(1, "P2 equivalence timeout");
    end
endmodule
//-----------------------------------------------------------------------------
// End of tb_packer_finish_equivalence.sv
//-----------------------------------------------------------------------------
