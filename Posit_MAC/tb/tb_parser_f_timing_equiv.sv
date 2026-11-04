// Historical supplemental bench; replay only with its matching source snapshot.
// posit_parser_f was retired from live RTL on2026-11-05; current NF/F use
// posit_parser and posit_parser_mul. This bench is outside current verification.
// Supplemental checks against the previous measured parser and a serial LOD oracle.
module tb_parser_f_timing_equiv;
    logic clk = 0, clock_enable = 0, reset_n = 0;
    always #5 if (clock_enable) clk = ~clk;
    logic in_valid = 0, out_ready = 0;
    logic [31:0] p = 0, mag_p = 0;
    wire ready_new, ready_old, valid_new, valid_old;
    wire s_new, z_new, n_new, s_old, z_old, n_old;
    wire signed [10:0] sf_new, sf_old;
    wire [25:0] frac_new, frac_old;
    posit_parser_f u_new(.clk(clk), .reset_n(reset_n), .in_valid(in_valid),
        .in_ready(ready_new), .p(p), .out_valid(valid_new), .out_ready(out_ready),
        .s(s_new), .is_zero(z_new), .is_nar(n_new), .sf(sf_new), .frac(frac_new));
    posit_parser_previous u_old(.clk(clk), .reset_n(reset_n), .in_valid(in_valid),
        .in_ready(ready_old), .p(p), .out_valid(valid_old), .out_ready(out_ready),
        .s(s_old), .is_zero(z_old), .is_nar(n_old), .sf(sf_old), .frac(frac_old));
    posit_parser_f u_mag(.clk(clk), .reset_n(reset_n), .in_valid(1'b0),
        .in_ready(), .p(mag_p), .out_valid(), .out_ready(1'b1),
        .s(), .is_zero(), .is_nar(), .sf(), .frac());
    logic [30:0] lod_in = 0;
    wire [4:0] lod_k;
    wire lod_valid;
    posit_parser_f_regime_lod u_lod(.in(lod_in), .K(lod_k), .vld(lod_valid));
    int accepted = 0, completed = 0, aborted = 0, stalls = 0;
    bit held = 0, accepted_edge = 0;
    logic [39:0] held_output;

    task automatic check_lod(input logic [30:0] value);
        int expected;
        bit found;
        expected = 0; found = 0;
        for (int i = 30; i >= 0; i--) begin
            if (!found && value[i]) begin expected = 30-i; found = 1; end
        end
        lod_in = value; #1;
        if (lod_k !== expected[4:0] || lod_valid !== found)
            $fatal(1, "LOD mismatch input=%h K=%d expected=%d", value, lod_k, expected);
    endtask

    always @(posedge clk) begin
        if (reset_n) begin
            accepted_edge = in_valid && ready_new;
            if (ready_new !== ready_old || valid_new !== valid_old)
                $fatal(1, "Parser handshake mismatch");
            if (valid_new && {s_new,z_new,n_new,sf_new,frac_new} !==
                             {s_old,z_old,n_old,sf_old,frac_old})
                $fatal(1, "Parser output mismatch");
            if (held && (!valid_new || {s_new,z_new,n_new,sf_new,frac_new} !== held_output))
                $fatal(1, "Parser output changed under stall");
            held = valid_new && !out_ready;
            held_output = {s_new,z_new,n_new,sf_new,frac_new};
            if (in_valid && ready_new) accepted++;
            if (valid_new && out_ready) completed++;
            if (held) stalls++;
        end else begin held = 0; accepted_edge = 0; end
    end

    initial begin : stimulus
        logic [31:0] expected_mag;
        for (int i = 0; i < 4000000; i++) begin
            if (i < 32) mag_p = 32'h1 << i;
            else if (i < 64) mag_p = (32'h1 << (i-32)) | 32'h80000000;
            else if (i < 96) mag_p = -(32'h1 << (i-64));
            else if (i == 96) mag_p = 0;
            else if (i == 97) mag_p = 32'h80000000;
            else mag_p = $urandom;
            expected_mag = (mag_p ^ {32{mag_p[31]}}) + {31'd0,mag_p[31]};
            #1;
            if (u_mag.magnitude !== expected_mag) $fatal(1, "Magnitude mismatch %h",mag_p);
        end
        $display("PARSER_MAG_DUT_PASS checked=4000000");
        check_lod(0);
        for (int i = 0; i < 31; i++) begin
            check_lod(31'd1 << i);
            check_lod(~(31'd1 << i));
        end
        for (int i = 0; i < 500000; i++) check_lod($urandom);
        $display("LOD_SERIAL_PASS checked=500063");
        clock_enable = 1;
        repeat (5) @(negedge clk);
        reset_n = 1;
        for (int cycle = 0; cycle < 150000; cycle++) begin
            @(negedge clk);
            // Reset at a deterministic cadence, including occupied pipelines.
            if (cycle > 0 && cycle % 10007 == 0) begin
                reset_n = 0; in_valid = 0; out_ready = 0;
                aborted += accepted-completed-aborted;
                repeat (4) @(negedge clk);
                reset_n = 1;
            end
            out_ready = ($urandom_range(0,3) != 0);
            if (!in_valid || accepted_edge) begin
                in_valid = ($urandom_range(0,7) != 0);
                case (cycle % 256)
                    0: p = 0;
                    1: p = 32'h80000000;
                    2: p = 32'h7fffffff;
                    3: p = 32'h80000001;
                    4: p = 1;
                    5: p = 32'hffffffff;
                    default: p = $urandom;
                endcase
            end
        end
        // Finish any held input before deasserting valid.
        out_ready = 1;
        do @(negedge clk); while (in_valid && !accepted_edge);
        in_valid = 0;
        repeat (8) @(negedge clk);
        if (accepted != completed+aborted) $fatal(1,"Parser transaction accounting mismatch");
        $display("PARSER_PREVIOUS_EQUIV_PASS accepted=%0d completed=%0d aborted=%0d stalls=%0d",accepted,completed,aborted,stalls);
        $finish;
    end
    initial begin #20000000; $fatal(1,"Supplement watchdog"); end
endmodule
