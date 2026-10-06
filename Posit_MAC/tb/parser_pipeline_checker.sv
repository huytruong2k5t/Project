//-----------------------------------------------------------------------------
// File          : parser_pipeline_checker.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-05
// Description   : Fixture scoreboard and directed elastic-pipeline checks.
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module parser_pipeline_checker #(
    parameter int NB = 8,
    parameter int ES = 0
)(
    output bit done = 1'b0
);
    localparam int F = NB - 3 - ES;
    localparam int SW = $clog2(64'd4 * (NB - 2) * (64'd1 << ES) + 64'd4) + 1;
    localparam int B = 3 + SW + F;
    localparam int EXPECTED_ROWS = (NB == 8) ? 256
                                : (NB == 16) ? 65536 : 1200010;

    bit clk = 1'b0;
    logic reset_n = 1'b0;
    logic in_valid = 1'b0;
    wire in_ready;
    logic [NB-1:0] p = '0;
    wire out_valid;
    logic out_ready = 1'b0;
    wire s;
    wire is_zero;
    wire is_nar;
    wire signed [SW-1:0] sf;
    wire [F-1:0] frac;
    wire [B-1:0] observed;

    logic [B-1:0] input_expected;
    logic [B-1:0] expected [1:0];
    longint enqueue_cycle [1:0];
    int read_index = 0;
    int write_index = 0;
    int occupancy = 0;
    longint cycles = 0;
    longint accepted = 0;
    longint received = 0;
    longint discarded = 0;
    longint stalled = 0;
    longint full_stalls = 0;
    longint simultaneous = 0;
    longint bubbles = 0;
    longint latency_checks = 0;
    int reset_checks = 0;

    bit last_push = 1'b0;
    bit last_pop = 1'b0;
    bit was_held = 1'b0;
    bit previous_push = 1'b0;
    bit check_latency = 1'b0;
    logic [B-1:0] held_value;
    logic [31:0] random_state = 20261005 + NB * 17 + ES;

    posit_parser #(
        .NB       (NB),
        .ES       (ES),
        .FRAC_MAX (F),
        .SF_W     (SW)
    ) dut (
        .clk       (clk),
        .reset_n   (reset_n),
        .in_valid  (in_valid),
        .in_ready  (in_ready),
        .p         (p),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .s         (s),
        .is_zero   (is_zero),
        .is_nar    (is_nar),
        .sf        (sf),
        .frac      (frac)
    );

    assign observed = {s, is_zero, is_nar, sf, frac};
    always #5 clk = ~clk;

    // Independent sequential decoder for the small directed reset/stall suite.
    // The acceptance stream uses the previously validated L1/field fixtures.
    function automatic [B-1:0] decode(input logic [NB-1:0] word);
        logic sign_bit;
        logic zero_bit;
        logic nar_bit;
        logic regime_bit;
        logic [NB-1:0] magnitude;
        logic signed [SW-1:0] scale;
        logic [F-1:0] fraction;
        int cursor;
        int run_length;
        int k;
        int exponent;

        sign_bit = word[NB-1];
        zero_bit = (word == '0);
        nar_bit = (word == {1'b1, {(NB-1){1'b0}}});
        scale = '0;
        fraction = '0;

        if (!zero_bit && !nar_bit) begin
            magnitude = sign_bit ? (~word + 1'b1) : word;
            cursor = NB - 2;
            regime_bit = magnitude[cursor];
            run_length = 0;

            while (cursor >= 0 && magnitude[cursor] == regime_bit) begin
                run_length++;
                cursor--;
            end

            k = regime_bit ? run_length - 1 : -run_length;

            if (cursor >= 0) begin
                cursor--;
            end

            exponent = 0;

            for (int j = 0; j < ES; j++) begin
                exponent = exponent * 2;

                if (cursor >= 0) begin
                    exponent = exponent + magnitude[cursor];
                    cursor--;
                end
            end

            scale = k * (1 << ES) + exponent;

            for (int j = F - 1; j >= 0; j--) begin
                if (cursor >= 0) begin
                    fraction[j] = magnitude[cursor];
                    cursor--;
                end
            end
        end

        return {sign_bit, zero_bit, nar_bit, scale, fraction};
    endfunction

    function automatic [31:0] next_random(input logic [31:0] state);
        logic [31:0] value;

        value = state ^ (state << 13);
        value = value ^ (value >> 17);
        value = value ^ (value << 5);
        return value;
    endfunction

    // Sample handshakes before NBA/CK2Q updates, then check settled outputs.
    task automatic cycle;
        @(posedge clk);

        if (was_held && (out_valid !== 1'b1 || observed !== held_value)) begin
            $fatal(1, "PIPE HOLD FAIL NB=%0d ES=%0d cycle=%0d", NB, ES, cycles);
        end

        last_push = in_valid && in_ready;
        last_pop = out_valid && out_ready;

        if (last_pop) begin
            if (occupancy == 0 || observed !== expected[read_index]) begin
                $fatal(1, "PIPE DATA FAIL NB=%0d ES=%0d cycle=%0d got=%h expected=%h occupancy=%0d",
                       NB, ES, cycles, observed, expected[read_index], occupancy);
            end

            if (check_latency) begin
                if (cycles - enqueue_cycle[read_index] != 2) begin
                    $fatal(1, "PIPE LATENCY FAIL NB=%0d ES=%0d", NB, ES);
                end

                latency_checks++;
            end

            read_index = read_index ^ 1;
            occupancy--;
            received++;
        end

        if (last_push) begin
            if (occupancy >= 2) begin
                $fatal(1, "PIPE CAPACITY FAIL NB=%0d ES=%0d", NB, ES);
            end

            expected[write_index] = input_expected;
            enqueue_cycle[write_index] = cycles;
            write_index = write_index ^ 1;
            occupancy++;
            accepted++;
        end

        if (last_push && last_pop) begin
            simultaneous++;
        end

        if (!in_valid) begin
            bubbles++;
        end

        was_held = out_valid && !out_ready;
        held_value = observed;

        if (was_held) begin
            stalled++;
        end

        if (occupancy == 2 && !out_ready) begin
            if (in_ready !== 1'b0) begin
                // On the edge which fills the last slot, ready falls after CK2Q.
                if (!last_push) begin
                    $fatal(1, "PIPE FULL READY FAIL NB=%0d ES=%0d", NB, ES);
                end
            end

            full_stalls++;
        end

        #2;

        if ((^{in_ready, out_valid, observed}) === 1'bx) begin
            $fatal(1, "PIPE X FAIL NB=%0d ES=%0d", NB, ES);
        end

        if (check_latency) begin
            if (in_ready !== 1'b1 || out_valid !== previous_push) begin
                $fatal(1, "PIPE II/VALID FAIL NB=%0d ES=%0d cycle=%0d", NB, ES, cycles);
            end
        end

        previous_push = last_push;
        cycles++;
    endtask

    task automatic reset_pipeline;
        // Assert between clk edges: this must flush both stages immediately.
        @(negedge clk);
        in_valid = 1'b0;
        out_ready = 1'b0;
        #2;
        reset_n = 1'b0;
        #2;

        if (in_ready !== 1'b0 || out_valid !== 1'b0 || observed !== '0) begin
            $fatal(1, "PIPE ASYNC RESET FAIL NB=%0d ES=%0d", NB, ES);
        end

        discarded = discarded + occupancy;
        occupancy = 0;
        read_index = 0;
        write_index = 0;
        was_held = 1'b0;
        previous_push = 1'b0;
        last_push = 1'b0;
        check_latency = 1'b0;

        @(negedge clk);
        #2;
        reset_n = 1'b1;

        @(posedge clk);
        #2;

        if (in_ready !== 1'b0 || out_valid !== 1'b0) begin
            $fatal(1, "PIPE EARLY RESET RELEASE NB=%0d ES=%0d", NB, ES);
        end

        @(posedge clk);
        #2;

        if (in_ready !== 1'b1 || out_valid !== 1'b0 || observed !== '0) begin
            $fatal(1, "PIPE RESET RELEASE FAIL NB=%0d ES=%0d", NB, ES);
        end

        reset_checks++;
    endtask

    task automatic send_directed(input logic [NB-1:0] word);
        @(negedge clk);
        p = word;
        input_expected = decode(word);
        in_valid = 1'b1;
        cycle();

        if (!last_push) begin
            $fatal(1, "PIPE DIRECTED INPUT BLOCKED NB=%0d ES=%0d", NB, ES);
        end
    endtask

    initial begin : test_sequence
        string filename;
        int fd;
        int fields_read;
        int sign_expected;
        int zero_expected;
        int nar_expected;
        int scale_expected;
        logic signed [SW-1:0] scale_bits;
        logic [F-1:0] fraction_expected;
        longint rows_read;
        longint received_before_stream;
        longint accepted_before_stream;
        longint stream_cycle;

        reset_pipeline();

        // Reset with exactly one transaction in P1.
        send_directed({NB{1'b1}});
        reset_pipeline();

        // Reset with both slots occupied and output blocked.
        send_directed('0);
        send_directed({1'b1, {(NB-1){1'b0}}});

        repeat (8) begin
            @(negedge clk);
            in_valid = 1'b0;
            cycle();
        end

        reset_pipeline();

        // Long stall, then drain and verify that no transaction is duplicated.
        send_directed({1'b0, {(NB-1){1'b1}}});
        send_directed({{(NB-1){1'b0}}, 1'b1});

        repeat (32) begin
            @(negedge clk);
            in_valid = 1'b0;
            cycle();
        end

        repeat (4) begin
            @(negedge clk);
            in_valid = 1'b0;
            out_ready = 1'b1;
            cycle();
        end

        if (occupancy != 0 || discarded != 3) begin
            $fatal(1, "PIPE RESET/DRAIN ACCOUNTING FAIL NB=%0d ES=%0d", NB, ES);
        end

        filename = $sformatf("../parser_comb/parser_%0d_%0d.txt", NB, ES);
        fd = $fopen(filename, "r");

        if (!fd) begin
            $fatal(1, "Missing parser fixture %s", filename);
        end

        rows_read = 0;
        stream_cycle = 0;
        received_before_stream = received;
        accepted_before_stream = accepted;
        previous_push = 1'b0;
        last_push = 1'b0;

        while (rows_read < EXPECTED_ROWS || in_valid || occupancy != 0) begin
            @(negedge clk);
            random_state = next_random(random_state);

            if (last_push) begin
                in_valid = 1'b0;
            end

            if (stream_cycle < 512) begin
                out_ready = 1'b1;
                check_latency = 1'b1;
            end else if (stream_cycle < 1024) begin
                out_ready = 1'b1;
                check_latency = 1'b0;
            end else if (stream_cycle < 1536) begin
                out_ready = (stream_cycle % 64 >= 32);
            end else begin
                out_ready = (random_state[1:0] != 0);

                if (stream_cycle % 4096 < 128) begin
                    out_ready = 1'b0;
                end
            end

            // A blocked source keeps valid, p and its expected fields unchanged.
            if (!in_valid && rows_read < EXPECTED_ROWS) begin
                if (stream_cycle < 512 ||
                    (stream_cycle < 1024 && stream_cycle % 4 != 0) ||
                    (stream_cycle >= 1024 && random_state[3:2] != 0)) begin
                    fields_read = $fscanf(fd, "%h %d %d %d %d %h\n",
                                          p, sign_expected, zero_expected,
                                          nar_expected, scale_expected, fraction_expected);

                    if (fields_read != 6) begin
                        $fatal(1, "Malformed parser fixture %s row=%0d", filename, rows_read);
                    end

                    scale_bits = scale_expected;
                    input_expected = {sign_expected[0], zero_expected[0],
                                      nar_expected[0], scale_bits, fraction_expected};
                    in_valid = 1'b1;
                    rows_read++;
                end
            end

            cycle();
            stream_cycle++;

            if (last_pop && (received - received_before_stream) % 100000 == 0) begin
                $display("PIPE CHECKPOINT NB=%0d ES=%0d received=%0d",
                         NB, ES, received - received_before_stream);
            end
        end

        fields_read = $fscanf(fd, "%h", p);
        $fclose(fd);

        if (fields_read == 1 || received - received_before_stream != EXPECTED_ROWS ||
            accepted - accepted_before_stream != EXPECTED_ROWS ||
            accepted != received + discarded || latency_checks < 250 ||
            stalled == 0 || full_stalls == 0 || simultaneous == 0 || bubbles == 0 ||
            reset_checks != 3) begin
            $fatal(1, "PIPE COVERAGE/ACCOUNTING FAIL NB=%0d ES=%0d", NB, ES);
        end

        $display("PIPE PASS NB=%0d ES=%0d checks=%0d reset=%0d discarded=%0d stalls=%0d full=%0d simultaneous=%0d bubbles=%0d latency=%0d",
                 NB, ES, received - received_before_stream, reset_checks, discarded,
                 stalled, full_stalls, simultaneous, bubbles, latency_checks);
        done = 1'b1;
    end
endmodule
