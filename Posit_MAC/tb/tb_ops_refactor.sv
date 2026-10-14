//-----------------------------------------------------------------------------
// File          : tb_ops_refactor.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-14
// Description   : All 378 legal fraction width pairs and extra control widths.
// $Source: $ $Revision: 1.0 $ $Log: Parameter matrix and before/after compare. $
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module tb_ops_refactor;
    parameter int FULL_TEST = 0;
    wire [381:0] done;
    genvar full;
    genvar narrow;
    generate
        for (full = 1; full <= 27; full++) begin : g_full
            for (narrow = 1; narrow <= full; narrow++) begin : g_narrow
                localparam int INDEX = full*(full-1)/2 + narrow-1;
                if (FULL_TEST == 0 || FULL_TEST == full) begin : g_enabled
                ops_refactor_checker #(
                    .F(full),
                    .FW(narrow)
                ) u_check (
                    .done(done[INDEX])
                );
                end else begin : g_skipped
                    assign done[INDEX] = 1'b1;
                end
            end
        end
    endgenerate
    generate
    if (FULL_TEST == 0 || FULL_TEST == 27) begin : g_extras
    ops_refactor_checker #(.F(1), .FW(1), .SW(2), .WW(4)) u_extra1 (.done(done[378]));
    ops_refactor_checker #(.F(5), .FW(1), .SW(2), .WW(6)) u_extra5 (.done(done[379]));
    ops_refactor_checker #(.F(26), .FW(12), .SW(2), .WW(8)) u_extra26 (.done(done[380]));
    ops_refactor_checker #(.F(27), .FW(27), .SW(2), .WW(8)) u_extra27 (.done(done[381]));
    end else begin : g_no_extras
        assign done[381:378] = '1;
    end
    endgenerate
    initial begin
        wait (&done);
        $display("OPS REFACTOR BATCH PASS F=%0d mismatch=0", FULL_TEST);
        $finish;
    end
    initial begin
        #100000;
        $fatal(1, "OPS refactor timeout");
    end
endmodule
// End of tb_ops_refactor.sv
