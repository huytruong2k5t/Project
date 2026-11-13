module tb_report_detectors;
    timeunit 1ns;
    timeprecision 1ps;
    logic [11:0] in12;
    logic [30:0] in31;
    wire [3:0] k12;
    wire [4:0] ktree, kflat;
    wire v12, vtree, vflat;
    logic [30:0] m;
    int checked31 = 0;
    int transitions = 0;

    lod_lzd_core_fixed4 u_sac (.in(in12), .K(k12), .vld(v12));
    posit_parser_f_regime_lod u_regime (.in(in31), .K(ktree), .vld(vtree));
    lod_lzd_core_fixed2 u_adder_nf (.in(in31), .K(kflat), .vld(vflat));

    task automatic check31(input logic [30:0] data, input int k_expected);
        bit v_expected;
        v_expected = (data != 0);
        in31 = data;
        #1;
        if ({vtree, ktree} !== {v_expected, k_expected[4:0]} ||
            {vflat, kflat} !== {v_expected, k_expected[4:0]})
            $fatal(1, "31-bit scan in=%h expected=%0d v=%b tree=%0d/%b flat=%0d/%b",
                   data, k_expected, v_expected, ktree, vtree, kflat, vflat);
        checked31++;
    endtask

    initial begin
        int expected;
        bit valid_expected;
        in31 = '0;
        for (int x = 0; x < 4096; x++) begin
            in12 = x[11:0];
            valid_expected = x != 0;
            expected = 0;
            for (int v = x; v > 1; v >>= 1) expected++;
            if (valid_expected) expected = 11 - expected;
            #1;
            if ({v12, k12} !== {valid_expected, expected[3:0]})
                $fatal(1, "SAC scan in=%h expected=%0d v=%b got=%0d/%b",
                       in12, expected, valid_expected, k12, v12);
        end
        check31('0, 0);
        check31('1, 0);
        for (int hi = 0; hi <= 30; hi++) begin
            check31(31'd1 << hi, 30-hi);
            for (int lo = 0; lo < hi; lo++)
                check31((31'd1 << hi) | (31'd1 << lo), 30-hi);
        end
        // Magnitude run starts at bit 30. Check both polarities and the sentinel.
        for (int pol = 0; pol <= 1; pol++) begin
            for (int run_length = 1; run_length <= 31; run_length++) begin
                for (int i = 0; i <= 30; i++)
                    m[30-i] = (i < run_length) ? pol[0] : !pol[0];
                check31({m[29:0] ^ m[30:1], 1'b1}, run_length-1);
                transitions++;
            end
        end
        $display("PASS: SAC12 exhaustive=4096; 31-bit vectors=%0d per detector (regime/sentinel=%0d each)", checked31, transitions);
        $finish;
    end
endmodule