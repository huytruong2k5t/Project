//-----------------------------------------------------------------------------
// File          : tb_paper_fig5_pack.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP - separate paper research
// Creation Date : 2026-10-09
// Description   : Shared RTL TRUNC packer vs independent Fig.5 gate reference.
//                 Explicit project clamps are separate from literal raw figure.
// $Source: $ $Revision: 1.0 $ $Log: Source contract audit. $
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module tb_paper_fig5_pack;
    logic sign;
    logic is_zero;
    logic is_nar;
    logic signed [10:0] sf;
    logic [52:0] frac;
    logic sticky;
    logic [4:0] flags_in;
    wire [31:0] d;
    wire [4:0] flags;
    logic [11:0] frac12;
    logic [31:0] expected, raw_figure;
    int fd, rc, sign_e, sf_e, records, raw_boundary_differences;

    posit_pack_comb #(
        .NB(32),
        .ES(3),
        .ROUND_MODE("TRUNC")
    ) dut (
        .sign(sign),
        .is_zero(is_zero),
        .is_nar(is_nar),
        .sf(sf),
        .frac(frac),
        .sticky(sticky),
        .flags_in(flags_in),
        .d(d),
        .flags(flags)
    );

    initial begin
        fd = $fopen("packer.txt", "r");
        if (!fd) $fatal(1, "missing Fig5 fixture");
        records = 0;
        raw_boundary_differences = 0;
        is_zero = 1'b0;
        is_nar = 1'b0;
        sticky = 1'b0;
        flags_in = '0;
        while (!$feof(fd)) begin
            rc = $fscanf(fd, "%d %d %h %h %h\n",
                sign_e, sf_e, frac12, expected, raw_figure);
            if (rc != 5) $fatal(1, "malformed Fig5 fixture");
            sign = sign_e[0];
            sf = sf_e[10:0];
            frac = {frac12, 41'b0};
            #2;
            if (d !== expected)
                $fatal(1, "Fig5 mismatch row=%0d sign=%0d sf=%0d frac=%h d=%h/%h",
                    records, sign, sf, frac12, d, expected);
            // A raw difference is evidence of omitted range policy, not RTL failure.
            if (raw_figure != expected) begin
                if (sf_e >= -240 && sf_e <= 240)
                    $fatal(1, "raw figure differs inside verified finite range");
                raw_boundary_differences++;
            end
            records++;
        end
        $fclose(fd);
        $display("PAPER FIG5 PACK PASS records=%0d raw_boundary_differences=%0d mismatch=0", records, raw_boundary_differences);
        $finish;
    end
endmodule
// End of tb_paper_fig5_pack.sv
