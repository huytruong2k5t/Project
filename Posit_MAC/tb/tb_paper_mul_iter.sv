//-----------------------------------------------------------------------------
// File          : tb_paper_mul_iter.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP - separate research verification
// Creation Date : 2026-10-09
// Description   : Black-box transactions plus passive per-commit observations.
//                 No hierarchical writes, force, or state injection.
// $Source: $ $Revision: 1.0 $ $Log: Autonomous paper top test. $
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module tb_paper_mul_iter;
    logic clk = 1'b0;
    logic reset_n = 1'b0;
    logic in_valid = 1'b0;
    logic out_ready = 1'b0;
    logic [31:0] a = '0;
    logic [31:0] b = '0;
    logic [3:0] n_terms = 4'd3;
    logic force_a = 1'b0;
    wire in_ready, out_valid, state_error, trace_valid;
    wire [31:0] d;
    wire [3:0] iterations, trace_iteration;
    wire [12:0] trace_mantissa, trace_mantissa_next;
    wire signed [7:0] trace_exponent, trace_power, trace_exponent_next;
    wire trace_negative, trace_anchor, trace_tail, trace_negative_next;
    wire [13:0] trace_acc, trace_term, trace_acc_next;
    int transactions_fd, traces_fd;
    int records = 0, commits = 0, specials = 0, fig4 = 0;
    int negative_terms = 0, zero_terms = 0, tail_terms = 0;
    int early_stops = 0, long_stalls = 0, resets = 0;

    always #5 clk = ~clk;
    initial begin
        #20000000;
        $fatal(1, "paper top watchdog");
    end

    paper_mul_iter dut (
        .clk(clk),
        .reset_n(reset_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .a(a),
        .b(b),
        .n_terms(n_terms),
        .force_a(force_a),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .d(d),
        .iterations(iterations),
        .state_error(state_error),
        .trace_valid(trace_valid),
        .trace_iteration(trace_iteration),
        .trace_mantissa(trace_mantissa),
        .trace_exponent(trace_exponent),
        .trace_power(trace_power),
        .trace_negative(trace_negative),
        .trace_anchor(trace_anchor),
        .trace_acc(trace_acc),
        .trace_term(trace_term),
        .trace_tail(trace_tail),
        .trace_mantissa_next(trace_mantissa_next),
        .trace_exponent_next(trace_exponent_next),
        .trace_negative_next(trace_negative_next),
        .trace_acc_next(trace_acc_next)
    );

    task automatic reset_and_wait;
        @(negedge clk);
        reset_n = 1'b0;
        in_valid = 1'b0;
        out_ready = 1'b0;
        #2;
        if (out_valid || trace_valid || in_ready) $fatal(1, "reset gating");
        repeat (2) @(negedge clk);
        reset_n = 1'b1;
        n_terms = 4'd3;
        repeat (3) @(negedge clk);
        if (!in_ready || out_valid || trace_valid) $fatal(1, "reset startup/ghost");
    endtask

    task automatic check_trace;
        int rc, it, ex, power_e, neg, anch, ex_next, neg_next;
        logic [12:0] m, m_next;
        logic [13:0] acc, term, acc_next;
        logic tail;
        rc = $fscanf(traces_fd, "%d %h %d %d %d %d %h %h %h %h %d %d %h\n",
            it, m, ex, power_e, neg, anch, acc, term, tail, m_next,
            ex_next, neg_next, acc_next);
        if (rc != 13) $fatal(1, "missing trace record=%0d commit=%0d", records, commits);
        if (!trace_valid || trace_iteration !== it[3:0] ||
            trace_mantissa !== m || trace_exponent !== ex[7:0] ||
            trace_power !== power_e[7:0] || trace_negative !== neg[0] ||
            trace_anchor !== anch[0] || trace_acc !== acc || trace_term !== term ||
            trace_tail !== tail || trace_mantissa_next !== m_next ||
            trace_exponent_next !== ex_next[7:0] ||
            trace_negative_next !== neg_next[0] || trace_acc_next !== acc_next)
            $fatal(1, "trace mismatch record=%0d iteration=%0d acc=%h/%h power=%0d/%0d",
                records, it, trace_acc_next, acc_next, trace_power, power_e);
        negative_terms += neg;
        zero_terms += term == 0;
        tail_terms += tail;
        commits++;
    endtask

    task automatic run_record(
        input logic [31:0] a_e,
        input logic [31:0] b_e,
        input int n_e,
        input int force_e,
        input int t_e,
        input logic [31:0] d_e
    );
        int hold_cycles;
        @(negedge clk);
        a = a_e;
        b = b_e;
        n_terms = n_e[3:0];
        force_a = force_e[0];
        in_valid = 1'b1;
        out_ready = 1'b0;
        #2;
        if (!in_ready) $fatal(1, "expected input acceptance");
        @(posedge clk);
        #2;
        if (out_valid || in_ready) $fatal(1, "slot ownership at launch");
        @(negedge clk);
        // Competing input/config remains valid while the owned slot is busy.
        a = ~a_e;
        b = ~b_e;
        n_terms = 4'd8;
        force_a = !force_e[0];
        for (int k = 0; k < t_e; k++) begin
            @(posedge clk);
            check_trace();
            #2;
            if (iterations !== k+1 || in_ready || out_valid || state_error)
                $fatal(1, "commit count/ownership/error record=%0d", records);
        end
        @(posedge clk);
        #2;
        if (!out_valid || trace_valid || in_ready || d !== d_e ||
            iterations !== t_e[3:0] || state_error)
            $fatal(1, "output/latency mismatch record=%0d got=%h expected=%h t=%0d/%0d",
                records, d, d_e, iterations, t_e);
        hold_cycles = (records % 97 == 7) ? 96 : records % 5;
        long_stalls += hold_cycles == 96;
        for (int h = 0; h < hold_cycles; h++) begin
            @(posedge clk);
            #2;
            if (!out_valid || d !== d_e || iterations !== t_e[3:0] ||
                in_ready || trace_valid || state_error) $fatal(1, "unstable stalled output");
        end
        @(negedge clk);
        in_valid = 1'b0;
        out_ready = 1'b1;
        @(posedge clk);
        #2;
        if (out_valid || trace_valid || !in_ready) $fatal(1, "retire/duplicate");
        specials += t_e == 0;
        early_stops += t_e > 0 && t_e < n_e;
        if (a_e == 32'h1c900000 && b_e == 32'h3c820000 && force_e && n_e == 3) begin
            if (d_e !== 32'h1ae34000) $fatal(1, "Fig4 fixture incorrect");
            fig4++;
        end
        records++;
    endtask

    initial begin
        int rc, n_e, force_e, t_e;
        logic [31:0] a_e, b_e, d_e;
        reset_and_wait();
        // Reject all out-of-contract encodings, including zero.
        for (int n = 0; n < 16; n++) begin
            if (n == 0 || n > 8) begin
                @(negedge clk);
                n_terms = n[3:0];
                in_valid = 1'b1;
                #2;
                if (in_ready) $fatal(1, "invalid n accepted");
                @(posedge clk);
                #2;
                if (out_valid || trace_valid) $fatal(1, "invalid n produced work");
            end
        end
        reset_and_wait();
        // Abort immediately after capture, mid-loop, at PACK, and in output HOLD.
        for (int phase = 0; phase < 4; phase++) begin
            @(negedge clk);
            a = 32'h1c900000;
            b = 32'h3c820000;
            force_a = 1'b1;
            n_terms = 4'd3;
            in_valid = 1'b1;
            @(posedge clk);
            #2;
            in_valid = 1'b0;
            repeat ((phase == 0) ? 0 : ((phase == 1) ? 1 : phase+1)) begin
                @(posedge clk);
                #2;
            end
            reset_and_wait();
            resets++;
        end
        transactions_fd = $fopen("transactions.txt", "r");
        traces_fd = $fopen("traces.txt", "r");
        if (!transactions_fd || !traces_fd) $fatal(1, "missing fixture files");
        while (!$feof(transactions_fd)) begin
            rc = $fscanf(transactions_fd, "%h %h %d %d %d %h\n",
                a_e, b_e, n_e, force_e, t_e, d_e);
            if (rc != 6) $fatal(1, "malformed transaction");
            run_record(a_e, b_e, n_e, force_e, t_e, d_e);
        end
        if (!$feof(traces_fd)) $fatal(1, "unused expected trace");
        $fclose(transactions_fd);
        $fclose(traces_fd);
        repeat (4) begin
            @(posedge clk);
            #2;
            if (out_valid || trace_valid) $fatal(1, "ghost after final retire");
        end
        if (!fig4 || !negative_terms || !zero_terms || !tail_terms || !early_stops ||
            !specials || !long_stalls || resets != 4) $fatal(1, "missing functional scenarios");
        $display("PAPER TOP PASS records=%0d commits=%0d specials=%0d Fig4=%0d negative=%0d zero_terms=%0d tail=%0d early=%0d long_stalls=%0d resets=%0d mismatch=0",
            records, commits, specials, fig4, negative_terms, zero_terms, tail_terms,
            early_stops, long_stalls, resets);
        $finish;
    end
endmodule
// End of tb_paper_mul_iter.sv
