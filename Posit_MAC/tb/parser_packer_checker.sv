//-----------------------------------------------------------------------------
// File          : parser_packer_checker.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-07
// Description   : Actual parser -> widened fraction adapter -> packer identity.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module parser_packer_checker #(
    parameter int NB = 8,
    parameter int ES = 0,
    parameter ROUND_MODE = "RNE"
)(
    output bit done = 1'b0
);
    localparam int F = NB - 3 - ES;
    localparam int FI = 2 * F + 1;
    localparam int SW = $clog2(64'd4 * (NB - 2) * (64'd1 << ES) + 64'd4) + 1;
    localparam int H = 2 + ((ROUND_MODE == "RNE") ? 2 : 1);
    bit clk = 1'b0;
    logic reset_n = 1'b0;
    logic in_valid = 1'b0;
    wire in_ready;
    logic [NB-1:0] p = '0;
    wire parsed_valid;
    wire parsed_ready;
    wire sign;
    wire is_zero;
    wire is_nar;
    wire signed [SW-1:0] sf;
    wire [F-1:0] parsed_frac;
    wire [FI-1:0] frac;
    wire sticky;
    wire [4:0] flags_in;
    wire out_valid;
    logic out_ready = 1'b0;
    wire [NB-1:0] d;
    wire [4:0] flags;
    logic [NB-1:0] queue [7:0];
    longint age [7:0];
    int rd = 0, wr = 0, count = 0;
    longint cycles = 0, accepted = 0, received = 0, rows = 0;
    longint discarded = 0, held_checks = 0, latency_checks = 0;
    int reset_checks = 0;
    bit held = 1'b0;
    bit free_stream = 1'b0;
    logic [NB+4:0] last_output;
    logic [31:0] rng = 20261006 + NB + ES;

    assign frac = {parsed_frac, {FI-F{1'b0}}};
    assign sticky = 1'b0;
    assign flags_in = 5'b00000;
    always #5 clk = ~clk;

    posit_parser #(.NB(NB), .ES(ES), .FRAC_MAX(F), .SF_W(SW)) parser (
        .clk(clk), .reset_n(reset_n), .in_valid(in_valid), .in_ready(in_ready),
        .p(p), .out_valid(parsed_valid), .out_ready(parsed_ready),
        .s(sign), .is_zero(is_zero), .is_nar(is_nar), .sf(sf), .frac(parsed_frac)
    );
    posit_pack #(.NB(NB), .ES(ES), .F_IN(FI), .SF_W(SW),
                 .ROUND_MODE(ROUND_MODE)) packer (
        .clk(clk), .reset_n(reset_n), .in_valid(parsed_valid), .in_ready(parsed_ready),
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar), .sf(sf), .frac(frac),
        .sticky(sticky), .flags_in(flags_in), .out_valid(out_valid),
        .out_ready(out_ready), .d(d), .flags(flags)
    );
    function automatic [31:0] random_next(input logic [31:0] x);
        logic [31:0] y;
        y = x ^ (x << 13);
        y = y ^ (y >> 17);
        return y ^ (y << 5);
    endfunction

    always @(posedge clk) begin
        if (!reset_n) begin
            discarded = discarded + count;
            count = 0;
            rd = 0;
            wr = 0;
            held = 1'b0;
        end else begin
            cycles = cycles + 1;
            if (held && (!out_valid || {d,flags} !== last_output))
                $fatal(1, "CHAIN stalled output changed");
            if (out_valid && out_ready) begin
                if (!count || d !== queue[rd])
                    $fatal(1, "CHAIN identity NB=%0d ES=%0d mode=%s got=%h want=%h", NB, ES, ROUND_MODE, d, queue[rd]);
                if (flags !== ((d == {1'b1,{NB-1{1'b0}}}) ? 5'b10000 : 5'b00000))
                    $fatal(1, "CHAIN flags");
                if (free_stream) begin
                    if (cycles - age[rd] != H) $fatal(1, "CHAIN latency");
                    latency_checks = latency_checks + 1;
                end
                rd = (rd + 1) % 8;
                count = count - 1;
                received = received + 1;
            end
            if (in_valid && in_ready) begin
                queue[wr] = p;
                age[wr] = cycles;
                wr = (wr + 1) % 8;
                count = count + 1;
                accepted = accepted + 1;
            end
            if (count > H) $fatal(1, "CHAIN capacity");
            held = out_valid && !out_ready;
            if (held) begin
                held_checks = held_checks + 1;
                last_output = {d,flags};
            end
        end
    end
    task automatic restart;
        @(negedge clk);
        reset_n = 1'b0;
        in_valid = 1'b0;
        #2;
        if (out_valid || in_ready || d !== '0 || flags !== '0)
            $fatal(1, "CHAIN reset flush");
        repeat (2) @(negedge clk);
        reset_n = 1'b1;
        repeat (3) @(negedge clk);
        if (!in_ready || out_valid) $fatal(1, "CHAIN startup");
        reset_checks = reset_checks + 1;
    endtask
    task automatic send(input logic [NB-1:0] word);
        @(negedge clk);
        p = word;
        in_valid = 1'b1;
        do @(posedge clk); while (!in_ready);
        #2;
        @(negedge clk);
        in_valid = 1'b0;
    endtask
    initial begin : run
        int fd, rc;
        logic [NB-1:0] word;
        int unused_sign, unused_zero, unused_nar, unused_sf;
        logic [F-1:0] unused_frac;
        bit pushed;
        string name;
        restart();
        send(1);
        restart();
        for (int j = 0; j < H; ++j) send(j + 1);
        repeat (32) @(negedge clk);
        if (in_ready) $fatal(1, "CHAIN full must block");
        restart();
        out_ready = 1'b1;
        free_stream = 1'b1;
        name = $sformatf("../parser_comb/parser_%0d_%0d.txt", NB, ES);
        fd = $fopen(name, "r");
        if (!fd) $fatal(1, "CHAIN fixtures missing");
        while (!$feof(fd)) begin
            rc = $fscanf(fd, "%h %d %d %d %d %h\n", word,
                         unused_sign, unused_zero, unused_nar, unused_sf, unused_frac);
            if (rc != 6) $fatal(1, "CHAIN malformed fixture");
            rows = rows + 1;
            pushed = 1'b0;
            while (!pushed) begin
                @(negedge clk);
                rng = random_next(rng);
                if (!in_valid && (free_stream || rng[0])) begin
                    p = word;
                    in_valid = 1'b1;
                end
                rng = random_next(rng);
                if (free_stream) out_ready = 1'b1;
                else if (cycles % 257 < 32) out_ready = 1'b0;
                else out_ready = rng[1] || rng[2];
                @(posedge clk);
                pushed = in_valid && in_ready;
                if (pushed) begin
                    #2;
                    in_valid = 1'b0;
                end
            end
            if (rows == 128) begin
                @(negedge clk);
                in_valid = 1'b0;
                while (count) @(negedge clk);
                free_stream = 1'b0;
            end
        end
        $fclose(fd);
        @(negedge clk);
        in_valid = 1'b0;
        out_ready = 1'b1;
        while (count) @(negedge clk);
        if (accepted != received + discarded || received != rows ||
            discarded != H + 1 || latency_checks != 128 || !held_checks || reset_checks != 3)
            $fatal(1, "CHAIN coverage a=%0d r=%0d lost=%0d", accepted,received,discarded);
        $display("CHAIN PASS NB=%0d ES=%0d MODE=%s rows=%0d discarded=%0d resets=%0d stall=%0d latency=%0d",
                 NB, ES, ROUND_MODE, rows, discarded, reset_checks, held_checks, latency_checks);
        done = 1'b1;
    end
    initial begin
        #200000000;
        if (!done) $fatal(1, "CHAIN timeout");
    end
endmodule
