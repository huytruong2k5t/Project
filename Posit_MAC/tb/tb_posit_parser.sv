//-----------------------------------------------------------------------------
// File          : tb_posit_parser.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-05
// Description   : Four-format parser pipeline acceptance.
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_posit_parser;
    wire [3:0] done;

    parser_pipeline_checker #(
        .NB (8),
        .ES (0)
    ) u_p8 (
        .done (done[0])
    );

    parser_pipeline_checker #(
        .NB (16),
        .ES (1)
    ) u_p16 (
        .done (done[1])
    );

    parser_pipeline_checker #(
        .NB (32),
        .ES (2)
    ) u_p32_es2 (
        .done (done[2])
    );

    parser_pipeline_checker #(
        .NB (32),
        .ES (3)
    ) u_p32_es3 (
        .done (done[3])
    );

    initial begin
        wait (&done);
        $display("PARSER_PIPELINE ALL PASS");
        $finish;
    end

    initial begin
        #100000000;
        $fatal(1, "Parser pipeline watchdog timeout");
    end
endmodule
