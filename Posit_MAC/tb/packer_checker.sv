//-----------------------------------------------------------------------------
// File          : packer_checker.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-07
// Description   : L1/serial fixtures, combinational and elastic packer checks.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module packer_checker #(
    parameter int NB = 8,
    parameter int ES = 0,
    parameter ROUND_MODE = "RNE"
)(
    output bit done = 1'b0
);
    localparam int F = NB - 3 - ES;
    localparam int FI = 2 * F + 1;
    localparam int SW = $clog2(64'd4 * (NB - 2) * (64'd1 << ES) + 64'd4) + 1;
    localparam int H = (ROUND_MODE == "RNE") ? 2 : 1;
    bit clk = 1'b0;
    logic reset_n = 1'b0;
    logic in_valid = 1'b0;
    wire in_ready;
    logic sign = 1'b0;
    logic is_zero = 1'b0;
    logic is_nar = 1'b0;
    logic signed [SW-1:0] sf = '0;
    logic [FI-1:0] frac = '0;
    logic sticky = 1'b0;
    logic [4:0] flags_in = '0;
    wire out_valid;
    logic out_ready = 1'b0;
    wire [NB-1:0] d;
    wire [4:0] flags;
    wire [NB-1:0] comb_d;
    wire [4:0] comb_flags;
    logic [NB+4:0] current_expected;
    logic [NB+4:0] fifo [7:0];
    longint age [7:0];
    int rd = 0;
    int wr = 0;
    int count = 0;
    longint cycles = 0;
    longint rows = 0;
    longint accepted = 0;
    longint received = 0;
    longint discarded = 0;
    longint stall_checks = 0;
    longint full_checks = 0;
    longint simultaneous = 0;
    longint latency_checks = 0;
    longint comb_checks = 0;
    int reset_checks = 0;
    bit held = 1'b0;
    logic [NB+4:0] held_value;
    bit free_stream = 1'b0;
    logic [31:0] rng = 20261006 + NB * 17 + ES;

    posit_pack #(
        .NB(NB), .ES(ES), .F_IN(FI), .SF_W(SW), .ROUND_MODE(ROUND_MODE)
    ) dut (
        .clk(clk), .reset_n(reset_n), .in_valid(in_valid), .in_ready(in_ready),
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar), .sf(sf), .frac(frac),
        .sticky(sticky), .flags_in(flags_in), .out_valid(out_valid),
        .out_ready(out_ready), .d(d), .flags(flags)
    );
    posit_pack_comb #(
        .NB(NB), .ES(ES), .F_IN(FI), .SF_W(SW), .ROUND_MODE(ROUND_MODE)
    ) comb (
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar), .sf(sf), .frac(frac),
        .sticky(sticky), .flags_in(flags_in), .d(comb_d), .flags(comb_flags)
    );
    always #5 clk = ~clk;

    function automatic [31:0] random_next(input logic [31:0] x);
        logic [31:0] y;
        y = x ^ (x << 13);
        y = y ^ (y >> 17);
        return y ^ (y << 5);
    endfunction

    always @(posedge clk) begin
        if (!reset_n) begin
            discarded = discarded + count;
            rd = 0;
            wr = 0;
            count = 0;
            held = 1'b0;
        end else begin
            cycles = cycles + 1;
            if (held && (!out_valid || {d, flags} !== held_value))
                $fatal(1, "PACK held output changed NB=%0d ES=%0d mode=%s", NB, ES, ROUND_MODE);
            if (out_valid && out_ready) begin
                if (!count || {d, flags} !== fifo[rd])
                    $fatal(1, "PACK scoreboard NB=%0d ES=%0d mode=%s got=%h want=%h count=%0d", NB, ES, ROUND_MODE, {d,flags}, fifo[rd], count);
                if (free_stream) begin
                    if (cycles - age[rd] != H) $fatal(1, "PACK latency");
                    latency_checks = latency_checks + 1;
                end
                rd = (rd + 1) % 8;
                count = count - 1;
                received = received + 1;
                if (in_valid && in_ready) simultaneous = simultaneous + 1;
            end
            if (in_valid && in_ready) begin
                if ({comb_d, comb_flags} !== current_expected)
                    $fatal(1, "PACK comb NB=%0d ES=%0d mode=%s sf=%0d frac=%h got=%h want=%h", NB, ES, ROUND_MODE, sf, frac, {comb_d,comb_flags}, current_expected);
                comb_checks = comb_checks + 1;
                fifo[wr] = current_expected;
                age[wr] = cycles;
                wr = (wr + 1) % 8;
                count = count + 1;
                accepted = accepted + 1;
            end
            if (count > H) $fatal(1, "PACK exceeded slot capacity");
            if (in_valid && !in_ready) full_checks = full_checks + 1;
            held = out_valid && !out_ready;
            if (held) begin
                held_value = {d, flags};
                stall_checks = stall_checks + 1;
            end
        end
    end

    task automatic restart;
        @(negedge clk);
        reset_n = 1'b0;
        in_valid = 1'b0;
        #2;
        if (out_valid || in_ready || d !== '0 || flags !== '0)
            $fatal(1, "PACK async reset did not flush");
        repeat (2) @(negedge clk);
        reset_n = 1'b1;
        @(posedge clk);
        #2;
        if (in_ready || out_valid) $fatal(1, "PACK startup edge1");
        @(posedge clk);
        #2;
        if (!in_ready || out_valid) $fatal(1, "PACK startup edge2");
        reset_checks = reset_checks + 1;
    endtask

    task automatic send_one;
        @(negedge clk);
        sign = 1'b0;
        is_zero = 1'b0;
        is_nar = 1'b0;
        sf = '0;
        frac = '0;
        sticky = 1'b0;
        flags_in = '0;
        current_expected = {{2'b01, {NB-2{1'b0}}}, 5'b00000};
        in_valid = 1'b1;
        do @(posedge clk); while (!in_ready);
        #2;
        if (H == 1 && (!out_valid || {d,flags} !== current_expected))
            $fatal(1, "PACK TRUNC valid after E0");
        if (H == 2 && count == 1 && out_valid)
            $fatal(1, "PACK RNE valid too early");
        @(negedge clk);
        in_valid = 1'b0;
    endtask

    initial begin : run
        int fd;
        int rc;
        int si, ze, na, scale, st;
        logic [FI-1:0] f;
        logic [4:0] previous;
        logic [NB-1:0] rne_d, trunc_d;
        logic [4:0] rne_flags, trunc_flags;
        bit pushed;
        string file_name;
        restart();
        send_one();
        if (H == 2) begin
            @(posedge clk);
            #2;
            if (!out_valid || {d,flags} !== current_expected)
                $fatal(1, "PACK valid after E1");
        end
        repeat (32) @(negedge clk);
        restart();
        send_one();
        if (H == 2) begin
            send_one();
            repeat (3) @(negedge clk);
            if (in_ready) $fatal(1, "PACK full slot did not block");
        end
        restart();
        out_ready = 1'b1;
        free_stream = 1'b1;
        file_name = $sformatf("packer_%0d_%0d.txt", NB, ES);
        fd = $fopen(file_name, "r");
        if (!fd) $fatal(1, "PACK fixture missing");
        while (!$feof(fd)) begin
            rc = $fscanf(fd, "%d %d %d %d %h %d %h %h %h %h %h\n",
                         si, ze, na, scale, f, st, previous,
                         rne_d, rne_flags, trunc_d, trunc_flags);
            if (rc != 11) $fatal(1, "PACK malformed fixture");
            rows = rows + 1;
            pushed = 1'b0;
            while (!pushed) begin
                @(negedge clk);
                if (!in_valid) begin
                    rng = random_next(rng);
                    if (free_stream || rng[0]) begin
                        sign = si;
                        is_zero = ze;
                        is_nar = na;
                        sf = scale;
                        frac = f;
                        sticky = st;
                        flags_in = previous;
                        current_expected = (ROUND_MODE == "RNE")
                                         ? {rne_d, rne_flags} : {trunc_d, trunc_flags};
                        in_valid = 1'b1;
                    end
                end
                rng = random_next(rng);
                if (free_stream) out_ready = 1'b1;
                else if ((cycles % 257) < 32) out_ready = 1'b0;
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
        if (accepted != received + discarded || latency_checks < 128 ||
            reset_checks != 3 || !stall_checks || !simultaneous ||
            discarded != 1 + H || received != rows)
            $fatal(1, "PACK incomplete coverage a=%0d r=%0d discard=%0d", accepted, received, discarded);
        $display("PACK PASS NB=%0d ES=%0d MODE=%s rows=%0d comb=%0d received=%0d resets=%0d discarded=%0d stall=%0d full=%0d simultaneous=%0d latency=%0d",
                 NB, ES, ROUND_MODE, rows, comb_checks, received, reset_checks,
                 discarded, stall_checks, full_checks, simultaneous, latency_checks);
        done = 1'b1;
    end
    initial begin
        #200000000;
        if (!done) $fatal(1, "PACK timeout");
    end
endmodule
