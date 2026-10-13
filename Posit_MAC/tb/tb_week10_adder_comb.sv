`timescale 1ns/1ps
module tb_week10_adder_comb #(
    parameter int NB = 32,
    parameter int ES = 2
);
    localparam int F = NB - 3 - ES;
    localparam int F_OUT = 2 * F + 1;
    localparam int SF_W = $clog2(4 * (NB - 2) * (1 << ES) + 4) + 1;
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
    posit_add_comb #(.NB(NB), .ES(ES)) dut (
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

    initial begin
        a = '0;
        b = '0;
        flags_in = '0;
        row_count = 0;
        if (!$value$plusargs("VECTOR_DIR=%s", vector_dir)) begin
            $fatal(1, "VECTOR_DIR required");
        end
        filename = $sformatf("%s/add_%0d_%0d.txt", vector_dir, NB, ES);
        file_id = $fopen(filename, "r");
        if (!file_id) begin
            $fatal(1, "Cannot open %s", filename);
        end
        while (!$feof(file_id)) begin
            scan_count = $fscanf(file_id,
                "%h %h %h %h %h %h %h %d %h %h %h %h %h %h %h %h %d %h %h %h %h %h %h %h\n",
                a, b, flags_in, expected_x, expected_y, expected_subtract,
                expected_sign_base, expected_sf_base, expected_tail,
                expected_zero_base, expected_nar_base, expected_flags_base,
                expected_magnitude, expected_sign, expected_zero, expected_nar,
                expected_sf, expected_frac, expected_sticky, expected_flags,
                expected_rne, expected_flags_rne, expected_trunc, expected_flags_trunc);
            if (scan_count != 24) begin
                if ($feof(file_id)) break;
                $fatal(1, "Malformed row %0d count %0d", row_count, scan_count);
            end
            #2;
            if ({dut.x, dut.y, dut.subtract, dut.sign_base, dut.alignment_tail,
                 dut.zero_base, dut.nar_base, dut.flags_base} !==
                {expected_x, expected_y, expected_subtract, expected_sign_base, expected_tail,
                 expected_zero_base, expected_nar_base, expected_flags_base}
                || int'($signed(dut.sf_base)) != expected_sf_base) begin
                $fatal(1, "ALIGN mismatch NB%0d ES%0d row%0d a=%h b=%h", NB, ES, row_count, a, b);
            end
            if (dut.magnitude !== expected_magnitude) begin
                $fatal(1, "ARITH mismatch row%0d", row_count);
            end
            if ({sign,is_zero,is_nar,frac,sticky,flags_out} !==
                {expected_sign,expected_zero,expected_nar,expected_frac,expected_sticky,expected_flags}
                || int'($signed(sf)) != expected_sf) begin
                $fatal(1, "NORMALIZE mismatch NB%0d ES%0d row%0d a=%h b=%h sf%0d/%0d frac%h/%h sticky%b/%b",
                       NB,ES,row_count,a,b,sf,expected_sf,frac,expected_frac,sticky,expected_sticky);
            end
            if ({d_rne,flags_rne,d_trunc,flags_trunc} !==
                {expected_rne,expected_flags_rne,expected_trunc,expected_flags_trunc}) begin
                $fatal(1, "PACK mismatch NB%0d ES%0d row%0d a=%h b=%h rne%h/%h flags%h/%h trunc%h/%h flags%h/%h",
                       NB,ES,row_count,a,b,d_rne,expected_rne,flags_rne,expected_flags_rne,
                       d_trunc,expected_trunc,flags_trunc,expected_flags_trunc);
            end
            row_count = row_count + 1;
        end
        $fclose(file_id);
        if (!row_count) $fatal(1, "Empty fixture");
        $display("W10 COMB PASS NB=%0d ES=%0d rows=%0d mismatches=0", NB, ES, row_count);
        $finish;
    end
    initial begin
        #10000000;
        $fatal(1, "Comb suite timeout");
    end
endmodule
