`timescale 1ns/1ps
// Drives the same standalone transaction into both MAC implementations.
module tb_paired_mac_accuracy;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst_n = 0;
    logic [31:0] a = '0, b = '0, c = '0;
    wire [3:0] cfg_n = 4'd12;
    wire [1:0] cfg_ops = 2'd1;
    wire out_ready = 1'b1;
    logic in_nf = 0, in_f = 0;
    wire ready_nf, ready_f, valid_nf, valid_f;
    wire [31:0] d_nf, d_f;
    wire [4:0] flags_nf, flags_f;

    posit_mac_nf u_nf (
        .clk(clk), .rst_n(rst_n), .in_valid(in_nf), .in_ready(ready_nf),
        .a(a), .b(b), .c(c), .cfg_n(cfg_n), .cfg_ops(cfg_ops),
        .out_valid(valid_nf), .out_ready(out_ready), .d(d_nf), .flags(flags_nf)
    );
    posit_mac_f u_f (
        .clk(clk), .rst_n(rst_n), .in_valid(in_f), .in_ready(ready_f),
        .a(a), .b(b), .c(c), .cfg_n(cfg_n), .cfg_ops(cfg_ops),
        .out_valid(valid_f), .out_ready(out_ready), .d(d_f), .flags(flags_f)
    );

    integer fixtures, observations, fields, id, elapsed;
    integer completed = 0;
    logic accepted_nf, accepted_f, retired_nf, retired_f;
    logic [31:0] observed_nf, observed_f, expected_nf, expected_f;
    logic [4:0] observed_nf_flags, observed_f_flags, expected_nf_flags, expected_f_flags;
    reg [2047:0] fixture_path, observation_path;

    initial begin
        if (!$value$plusargs("FIXTURE=%s", fixture_path) ||
            !$value$plusargs("OBSERVED=%s", observation_path))
            $fatal(1, "FIXTURE and OBSERVED are required");
        fixtures = $fopen(fixture_path, "r");
        observations = $fopen(observation_path, "w");
        if (!fixtures || !observations) $fatal(1, "Cannot open benchmark files");

        repeat (4) @(negedge clk);
        rst_n = 1;
        fields = $fscanf(fixtures, "%d %h %h %h %h %h %h %h\n",
                         id, a, b, c, expected_nf, expected_nf_flags, expected_f, expected_f_flags);
        while (fields == 8) begin
            in_nf = 1;
            in_f = 1;
            accepted_nf = 0;
            accepted_f = 0;
            retired_nf = 0;
            retired_f = 0;
            elapsed = 0;
            while (!(retired_nf && retired_f)) begin
                @(posedge clk);
                elapsed = elapsed + 1;
                if (elapsed > 80 || $isunknown({ready_nf, ready_f, valid_nf, valid_f}))
                    $fatal(1, "Timeout or unknown handshake id=%0d", id);
                if (in_nf && ready_nf) accepted_nf = 1;
                if (in_f && ready_f) accepted_f = 1;
                if (valid_nf) begin
                    if (!accepted_nf || retired_nf || {d_nf, flags_nf} !== {expected_nf, expected_nf_flags})
                        $fatal(1, "NF id=%0d A=%h B=%h C=%h got=%h/%h expected=%h/%h",
                               id, a, b, c, d_nf, flags_nf, expected_nf, expected_nf_flags);
                    observed_nf = d_nf;
                    observed_nf_flags = flags_nf;
                    retired_nf = 1;
                end
                if (valid_f) begin
                    if (!accepted_f || retired_f || {d_f, flags_f} !== {expected_f, expected_f_flags})
                        $fatal(1, "F id=%0d A=%h B=%h C=%h got=%h/%h expected=%h/%h",
                               id, a, b, c, d_f, flags_f, expected_f, expected_f_flags);
                    observed_f = d_f;
                    observed_f_flags = flags_f;
                    retired_f = 1;
                end
                @(negedge clk);
                in_nf = !accepted_nf;
                in_f = !accepted_f;
            end
            $fdisplay(observations, "%0d,%08h,%02h,%08h,%02h",
                      id, observed_nf, observed_nf_flags, observed_f, observed_f_flags);
            completed = completed + 1;
            fields = $fscanf(fixtures, "%d %h %h %h %h %h %h %h\n",
                             id, a, b, c, expected_nf, expected_nf_flags, expected_f, expected_f_flags);
        end
        if (!$feof(fixtures) || fields > 0 || completed == 0)
            $fatal(1, "Malformed or empty fixture");
        repeat (4) begin
            @(posedge clk);
            if ({valid_nf, valid_f} !== 2'b00) $fatal(1, "Unexpected extra response");
        end
        $fclose(fixtures);
        $fclose(observations);
        $display("PAIRED_MAC_PASS completed=%0d", completed);
        $finish;
    end
endmodule
