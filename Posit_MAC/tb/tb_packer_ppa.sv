// File: tb_packer_ppa.sv -- check the added PPA input/output register boundaries.
`timescale 1ns/1ps
module tb_packer_ppa;
    bit clk = 1'b0;
    logic reset_n = 1'b0;
    logic sign = 1'b0;
    logic is_zero = 1'b0;
    logic is_nar = 1'b0;
    logic signed [9:0] sf = '0;
    logic [54:0] frac = '0;
    logic sticky = 1'b0;
    logic [4:0] flags_in = '0;
    wire [1:0] out_valid;
    wire [31:0] d [1:0];
    wire [4:0] flags [1:0];
    wire [31:0] ref_d [1:0];
    wire [4:0] ref_flags [1:0];
    logic [36:0] expected [1:0][3:0];
    logic [31:0] rng = 20261007;
    always #5 clk = ~clk;
    packer_ppa_top #(.ROUND_MODE("RNE")) u0 (
        .clk(clk), .reset_n(reset_n), .sign(sign), .is_zero(is_zero),
        .is_nar(is_nar), .sf(sf), .frac(frac), .sticky(sticky),
        .flags_in(flags_in), .out_valid(out_valid[0]), .d(d[0]), .flags(flags[0])
    );
    posit_pack_comb #(.NB(32), .ES(2), .F_IN(55), .SF_W(10),
                      .ROUND_MODE("RNE")) ref0 (
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar), .sf(sf), .frac(frac),
        .sticky(sticky), .flags_in(flags_in), .d(ref_d[0]), .flags(ref_flags[0])
    );
    packer_ppa_top #(.ROUND_MODE("TRUNC")) u1 (
        .clk(clk), .reset_n(reset_n), .sign(sign), .is_zero(is_zero),
        .is_nar(is_nar), .sf(sf), .frac(frac), .sticky(sticky),
        .flags_in(flags_in), .out_valid(out_valid[1]), .d(d[1]), .flags(flags[1])
    );
    posit_pack_comb #(.NB(32), .ES(2), .F_IN(55), .SF_W(10),
                      .ROUND_MODE("TRUNC")) ref1 (
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar), .sf(sf), .frac(frac),
        .sticky(sticky), .flags_in(flags_in), .d(ref_d[1]), .flags(ref_flags[1])
    );
    function automatic [31:0] next_random(input logic [31:0] x);
        logic [31:0] y;
        y = x ^ (x << 13);
        y = y ^ (y >> 17);
        return y ^ (y << 5);
    endfunction
    initial begin
        repeat (3) @(negedge clk);
        reset_n = 1'b1;
        repeat (8) @(negedge clk);
        for (int i = 0; i < 2000; ++i) begin
            @(negedge clk);
            rng = next_random(rng);
            sign = rng[0];
            sticky = rng[1];
            is_zero = rng[2:0] == 0;
            is_nar = rng[3:0] == 0;
            flags_in = rng[8:4];
            sf = rng[18:9];
            rng = next_random(rng);
            frac[54:23] = rng;
            rng = next_random(rng);
            frac[22:0] = rng[22:0];
            #2;
            for (int mode = 0; mode < 2; ++mode) begin
                for (int j = 3; j > 0; --j) expected[mode][j] = expected[mode][j-1];
                expected[mode][0] = {ref_d[mode], ref_flags[mode]};
            end
            @(posedge clk);
            #2;
            if (i >= 3) begin
                if (!(&out_valid) || {d[0],flags[0]} !== expected[0][3] ||
                    {d[1],flags[1]} !== expected[1][2]) $fatal(1, "PPA boundary latency/data");
            end
        end
        $display("PACKER PPA BOUNDARY PASS checks=3994");
        $finish;
    end
endmodule
