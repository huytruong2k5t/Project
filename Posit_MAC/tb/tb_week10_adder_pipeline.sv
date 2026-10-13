`timescale 1ns/1ps
module tb_week10_adder_pipeline #(
    parameter int NB = 32,
    parameter int ES = 2
);
    localparam int F = NB - 3 - ES;
    localparam int F_OUT = 2 * F + 1;
    localparam int SF_W = $clog2(4 * (NB - 2) * (1 << ES) + 4) + 1;
    logic clk = 1'b0;
    always #5 clk = !clk;
    logic reset_n;
    logic in_valid;
    wire in_ready;
    wire out_valid;
    logic out_ready;
    logic [NB-1:0] a;
    logic [NB-1:0] b;
    logic [4:0] flags_in;
    wire a_sign, a_is_zero, a_is_nar;
    wire b_sign, b_is_zero, b_is_nar;
    wire signed [SF_W-1:0] a_sf, b_sf;
    wire [F-1:0] a_frac, b_frac;
    wire sign, is_zero, is_nar, sticky;
    wire signed [SF_W-1:0] sf;
    wire [F_OUT-1:0] frac;
    wire [4:0] flags_out;
    wire [NB-1:0] d_rne, d_trunc;
    wire [4:0] flags_rne, flags_trunc;

    posit_parser_comb #(.NB(NB), .ES(ES)) u_parser_a (
        .p(a), .s(a_sign), .is_zero(a_is_zero), .is_nar(a_is_nar),
        .sf(a_sf), .frac(a_frac)
    );
    posit_parser_comb #(.NB(NB), .ES(ES)) u_parser_b (
        .p(b), .s(b_sign), .is_zero(b_is_zero), .is_nar(b_is_nar),
        .sf(b_sf), .frac(b_frac)
    );
    posit_add #(.NB(NB), .ES(ES)) dut (
        .clk(clk), .reset_n(reset_n), .in_valid(in_valid), .in_ready(in_ready),
        .out_valid(out_valid), .out_ready(out_ready),
        .a_sign(a_sign), .a_is_zero(a_is_zero), .a_is_nar(a_is_nar),
        .a_sf(a_sf), .a_frac(a_frac),
        .b_sign(b_sign), .b_is_zero(b_is_zero), .b_is_nar(b_is_nar),
        .b_sf(b_sf), .b_frac(b_frac), .flags_in(flags_in),
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar),
        .sf(sf), .frac(frac), .sticky(sticky), .flags_out(flags_out)
    );
    posit_pack_comb #(.NB(NB), .ES(ES), .ROUND_MODE("RNE")) u_pack_rne (
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar), .sf(sf),
        .frac(frac), .sticky(sticky), .flags_in(flags_out), .d(d_rne), .flags(flags_rne)
    );
    posit_pack_comb #(.NB(NB), .ES(ES), .ROUND_MODE("TRUNC")) u_pack_trunc (
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar), .sf(sf),
        .frac(frac), .sticky(sticky), .flags_in(flags_out), .d(d_trunc), .flags(flags_trunc)
    );

    integer file_id, scan_count, row_count;
    string vector_dir, filename;
    logic [F+4:0] expected_x, expected_y, expected_magnitude;
    logic expected_subtract, expected_sign_base, expected_tail;
    logic expected_zero_base, expected_nar_base;
    integer expected_sf_base, expected_sf;
    logic [4:0] expected_flags_base, expected_flags;
    logic expected_sign, expected_zero, expected_nar, expected_sticky;
    logic [F_OUT-1:0] expected_frac;
    logic [NB-1:0] expected_rne, expected_trunc;
    logic [4:0] expected_flags_rne, expected_flags_trunc;


    localparam int PAYLOAD_W = F_OUT + SF_W + 2 * NB + 19;
    typedef logic signed [SF_W-1:0] sf_t;
    logic [PAYLOAD_W-1:0] expected_queue [0:15];
    integer accepted_cycle [0:15];
    integer head, tail, occupancy, cycle_count, accepted, completed, reset_aborts;
    integer stalls, input_stalls, max_occupancy, reset_events, first_accept;
    logic [31:0] lfsr;
    logic loaded, eof_seen, source_stalled;
    logic hold_before;
    logic [PAYLOAD_W-1:0] payload_before;
    wire [PAYLOAD_W-1:0] payload = {
        sign,is_zero,is_nar,sf,frac,sticky,flags_out,
        d_rne,flags_rne,d_trunc,flags_trunc
    };
    wire [PAYLOAD_W-1:0] expected_payload = {
        expected_sign,expected_zero,expected_nar,sf_t'(expected_sf),
        expected_frac,expected_sticky,expected_flags,
        expected_rne,expected_flags_rne,expected_trunc,expected_flags_trunc
    };

    task automatic read_next;
        begin
            scan_count = $fscanf(file_id,
                "%h %h %h %h %h %h %h %d %h %h %h %h %h %h %h %h %d %h %h %h %h %h %h %h\n",
                a, b, flags_in, expected_x, expected_y, expected_subtract,
                expected_sign_base, expected_sf_base, expected_tail,
                expected_zero_base, expected_nar_base, expected_flags_base,
                expected_magnitude, expected_sign, expected_zero, expected_nar,
                expected_sf, expected_frac, expected_sticky, expected_flags,
                expected_rne, expected_flags_rne, expected_trunc, expected_flags_trunc);
            if (scan_count == 24) begin
                loaded = 1'b1;
                row_count = row_count + 1;
            end else if ($feof(file_id)) begin
                eof_seen = 1'b1;
            end else begin
                $fatal(1,"Malformed pipeline fixture");
            end
        end
    endtask

    initial begin
        a = '0;
        b = '0;
        flags_in = '0;
        reset_n = 1'b0;
        in_valid = 1'b0;
        out_ready = 1'b0;
        row_count = 0;
        head = 0;
        tail = 0;
        occupancy = 0;
        cycle_count = 0;
        accepted = 0;
        completed = 0;
        reset_aborts = 0;
        stalls = 0;
        input_stalls = 0;
        max_occupancy = 0;
        reset_events = 0;
        first_accept = -1;
        loaded = 1'b0;
        eof_seen = 1'b0;
        source_stalled = 1'b0;
        lfsr = 32'h20261012;
        if (!$value$plusargs("VECTOR_DIR=%s", vector_dir)) $fatal(1,"VECTOR_DIR required");
        filename = $sformatf("%s/add_%0d_%0d.txt",vector_dir,NB,ES);
        file_id = $fopen(filename,"r");
        if (!file_id) $fatal(1,"Cannot open %s",filename);
        while (!eof_seen || loaded || occupancy || out_valid) begin
            @(negedge clk);
            cycle_count = cycle_count + 1;
            lfsr = {lfsr[30:0],lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
            reset_n = !(cycle_count < 3 || cycle_count % 997 == 0 || cycle_count % 997 == 1);
            if (!loaded && !eof_seen) read_next();
            in_valid = reset_n && loaded &&
                       (source_stalled || cycle_count < 16 || lfsr[0] || lfsr[3]);
            out_ready = reset_n && (cycle_count < 16 ||
                         ((cycle_count % 500 < 80 || cycle_count % 500 >= 160) &&
                          (lfsr[2] || lfsr[7])));
            @(posedge clk);
            hold_before = reset_n && out_valid && !out_ready;
            payload_before = payload;
            if (!reset_n) begin
                reset_aborts = reset_aborts + occupancy;
                reset_events = reset_events + (occupancy != 0);
                occupancy = 0;
                head = 0;
                tail = 0;
                source_stalled = 1'b0;
            end else begin
                if (out_valid && out_ready) begin
                    if (!occupancy || payload !== expected_queue[head]) begin
                        $fatal(1,"PIPE output mismatch NB%0d ES%0d cycle%0d got=%h expected=%h",
                               NB,ES,cycle_count,payload,expected_queue[head]);
                    end
                    if (completed == 0 && cycle_count - accepted_cycle[head] != 3)
                        $fatal(1,"Wrong no-stall latency");
                    head = (head + 1) % 16;
                    occupancy = occupancy - 1;
                    completed = completed + 1;
                end
                if (in_valid && in_ready) begin
                    if (occupancy >= 3) $fatal(1,"Capacity exceeded");
                    expected_queue[tail] = expected_payload;
                    accepted_cycle[tail] = cycle_count;
                    if (first_accept < 0) first_accept = cycle_count;
                    tail = (tail + 1) % 16;
                    occupancy = occupancy + 1;
                    accepted = accepted + 1;
                    loaded = 1'b0;
                end
                source_stalled = in_valid && !in_ready;
                input_stalls = input_stalls + source_stalled;
                max_occupancy = occupancy > max_occupancy ? occupancy : max_occupancy;
                stalls = stalls + hold_before;
            end
            #2;
            if ($isunknown({in_ready,out_valid,payload})) $fatal(1,"X after reset");
            if (!reset_n && (in_ready || out_valid || dut.valid1_q || dut.valid2_q || dut.valid3_q))
                $fatal(1,"Reset did not flush pipeline");
            if (hold_before && (!out_valid || payload !== payload_before))
                $fatal(1,"Output changed while stalled");
            if (first_accept >= 0 && cycle_count == first_accept + 2 && !out_valid)
                $fatal(1,"Output valid did not appear after E2");
        end
        $fclose(file_id);
        if (accepted != row_count || completed + reset_aborts != accepted ||
            !stalls || !input_stalls || max_occupancy != 3 || !reset_events)
            $fatal(1,"Insufficient protocol coverage/accounting");
        $display("W10 PIPE PASS NB=%0d ES=%0d accepted=%0d completed=%0d reset_aborts=%0d stalls=%0d input_stalls=%0d max_occupancy=%0d reset_events=%0d mismatches=0",
                 NB,ES,accepted,completed,reset_aborts,stalls,input_stalls,max_occupancy,reset_events);
        $finish;
    end
    initial begin
        #100000000;
        $fatal(1,"Pipeline suite timeout");
    end
endmodule
