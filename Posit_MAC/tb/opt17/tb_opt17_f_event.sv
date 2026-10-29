//-----------------------------------------------------------------------------
// File          : tb_opt17_f_event.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP, OPT-17
// Creation Date : 2026-10-29
// Description   : CK2Q event replay of independent-oracle-checked stimuli.
// $Source: $ $Revision: 1.0 $ $Log: Compare public handshakes/data before each edge. $
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module tb_opt17_f_event;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic in_valid = 1'b0;
    wire in_ready;
    logic [31:0] a = '0;
    logic [31:0] b = '0;
    logic [31:0] c = '0;
    logic acc_mode = 1'b0;
    logic acc_clr = 1'b0;
    logic cfg_mode = 1'b1;
    logic [3:0] cfg_n = '0;
    logic [1:0] cfg_ops = '0;
    wire out_valid;
    logic out_ready = 1'b0;
    wire [31:0] d;
    wire [4:0] flags;
    logic expected_ready;
    logic expected_valid;
    logic [31:0] expected_d;
    logic [4:0] expected_flags;
    integer fd;
    integer rc;
    integer cycles = 0;
    integer accepted = 0;
    integer completed = 0;
    integer aborted = 0;
    integer outstanding = 0;
    integer stall_cycles = 0;
    reg [4095:0] stimulus;
    opt17_f u_dut (
        .clk (clk),
        .rst_n (rst_n),
        .in_valid (in_valid),
        .in_ready (in_ready),
        .a (a),
        .b (b),
        .c (c),
        .acc_mode (acc_mode),
        .acc_clr (acc_clr),
        .cfg_mode (cfg_mode),
        .cfg_n (cfg_n),
        .cfg_ops (cfg_ops),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .d (d),
        .flags (flags)
    );
    initial begin
        if (!$value$plusargs("STIMULUS=%s",stimulus)) $fatal(1,"Missing STIMULUS");
        fd = $fopen(stimulus,"r");
        if (!fd) $fatal(1,"Cannot open stimulus");
        while (!$feof(fd)) begin
            rc = $fscanf(fd,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h\n",
                         rst_n,in_valid,out_ready,a,b,c,acc_mode,acc_clr,
                         cfg_mode,cfg_n,cfg_ops,expected_ready,expected_valid,expected_d,expected_flags);
            if (rc == 15) begin
                #2;
                cycles = cycles + 1;
                if (in_ready !== expected_ready || out_valid !== expected_valid) begin
                    $display("HANDSHAKE_FAIL cycle=%0d got=%b/%b expected=%b/%b",cycles,in_ready,out_valid,expected_ready,expected_valid);
                    $fatal(1,"CK2Q handshake mismatch");
                end
                if (out_valid && (d !== expected_d || flags !== expected_flags)) begin
                    $display("DATA_FAIL cycle=%0d got=%h/%h expected=%h/%h",cycles,d,flags,expected_d,expected_flags);
                    $fatal(1,"CK2Q data mismatch");
                end
                if (!rst_n) begin
                    aborted = aborted + outstanding;
                    outstanding = 0;
                end else begin
                    accepted = accepted + (in_valid && in_ready);
                    completed = completed + (out_valid && out_ready);
                    outstanding = outstanding + (in_valid && in_ready) - (out_valid && out_ready);
                    stall_cycles = stall_cycles + (out_valid && !out_ready);
                    if (outstanding < 0 || outstanding > 2) $fatal(1,"Credit violation");
                end
                #3;
                clk = 1'b1;
                #5;
                clk = 1'b0;
            end else if (rc != -1) begin
                $fatal(1,"Malformed event vector");
            end
        end
        $fclose(fd);
        if (outstanding != 0 || accepted != completed + aborted) $fatal(1,"Transaction conservation");
        $display("OPT17_EVENT_PASS top=opt17_f completed=%0d reset_aborted=%0d cycles=%0d output_stalls=%0d mismatch=0 CK2Q=1ns",completed,aborted,cycles,stall_cycles);
        $finish;
    end
endmodule
// End of tb_opt17_f_event.sv
