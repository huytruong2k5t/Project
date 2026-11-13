`timescale 1ns/1ps
module tb_s1_prepare_equiv;
    logic a_sign, a_is_zero, a_is_nar, b_sign, b_is_zero, b_is_nar;
    logic signed [10:0] a_sf, b_sf;
    logic [25:0] a_frac, b_frac;
    logic [4:0] flags_in;

    wire [25:0] dut_x, dut_y, ref_x, ref_y;
    wire [4:0] dut_sh, ref_sh;
    wire dut_cl, dut_bnz, dut_sub, dut_sg, dut_bz, dut_nar;
    wire ref_cl, ref_bnz, ref_sub, ref_sg, ref_bz, ref_nar;
    wire signed [10:0] dut_sfb, ref_sfb;
    wire [3:0] dut_fl, ref_fl;

    posit_add_prepare_comb u_dut (
        .a_sign(a_sign), .a_is_zero(a_is_zero), .a_is_nar(a_is_nar), .a_sf(a_sf), .a_frac(a_frac),
        .b_sign(b_sign), .b_is_zero(b_is_zero), .b_is_nar(b_is_nar), .b_sf(b_sf), .b_frac(b_frac),
        .flags_in(flags_in),
        .x_frac(dut_x), .y_frac(dut_y), .shift_amount(dut_sh), .clamped(dut_cl),
        .both_nonzero(dut_bnz), .subtract(dut_sub), .sign_base(dut_sg), .sf_base(dut_sfb),
        .both_zero(dut_bz), .is_nar(dut_nar), .flags_lo(dut_fl)
    );
    posit_add_prepare_comb_ref u_ref (
        .a_sign(a_sign), .a_is_zero(a_is_zero), .a_is_nar(a_is_nar), .a_sf(a_sf), .a_frac(a_frac),
        .b_sign(b_sign), .b_is_zero(b_is_zero), .b_is_nar(b_is_nar), .b_sf(b_sf), .b_frac(b_frac),
        .flags_in(flags_in),
        .x_frac(ref_x), .y_frac(ref_y), .shift_amount(ref_sh), .clamped(ref_cl),
        .both_nonzero(ref_bnz), .subtract(ref_sub), .sign_base(ref_sg), .sf_base(ref_sfb),
        .both_zero(ref_bz), .is_nar(ref_nar), .flags_lo(ref_fl)
    );

    int checks = 0;
    logic [63:0] rng = 64'h9E37_79B9_7F4A_7C15;
    function automatic void step_rng();
        rng = rng ^ (rng << 13);
        rng = rng ^ (rng >> 7);
        rng = rng ^ (rng << 17);
    endfunction

    task automatic check_one();
        #1;
        checks++;
        if ({dut_x, dut_y, dut_sh, dut_cl, dut_bnz, dut_sub, dut_sg, dut_sfb, dut_bz, dut_nar, dut_fl} !==
            {ref_x, ref_y, ref_sh, ref_cl, ref_bnz, ref_sub, ref_sg, ref_sfb, ref_bz, ref_nar, ref_fl}) begin
            $display("S1_MISMATCH #%0d a=(%b,%b,%b,%0d,%h) b=(%b,%b,%b,%0d,%h)", checks,
                     a_sign, a_is_zero, a_is_nar, a_sf, a_frac,
                     b_sign, b_is_zero, b_is_nar, b_sf, b_frac);
            $fatal(1, "S1 prepare mismatch");
        end
    endtask

    initial begin
        // Boundary & tie cases including extreme signed sf (-1024, +1023)
        logic signed [10:0] sf_vals [0:6] = '{-11'sd1024, -11'sd1023, -11'sd1, 11'sd0, 11'sd1, 11'sd1022, 11'sd1023};
        for (int ia = 0; ia < 7; ia++) begin
            for (int ib = 0; ib < 7; ib++) begin
                for (int za = 0; za < 2; za++) begin
                    for (int zb = 0; zb < 2; zb++) begin
                        for (int fa = 0; fa < 3; fa++) begin
                            for (int fb = 0; fb < 3; fb++) begin
                                a_sign = za[0]; b_sign = zb[0];
                                a_is_zero = (fa == 2); b_is_zero = (fb == 2);
                                a_is_nar = 1'b0; b_is_nar = 1'b0;
                                a_sf = sf_vals[ia]; b_sf = sf_vals[ib];
                                a_frac = (fa == 0) ? 26'h0 : (fa == 1 ? 26'h3FF_FFFF : 26'h200_0001);
                                b_frac = (fb == 0) ? 26'h0 : (fb == 1 ? 26'h3FF_FFFF : 26'h200_0001);
                                flags_in = {za[0], zb[0], ia[1:0], ib[0]};
                                check_one();
                            end
                        end
                    end
                end
            end
        end
        // 200,000 random stress + tied-sf vectors
        for (int i = 0; i < 200000; i++) begin
            step_rng(); a_sign = rng[0]; a_is_zero = (rng[4:1] == 0); a_is_nar = (rng[8:5] == 0);
            a_sf = $signed(rng[19:9]); a_frac = rng[45:20]; flags_in = rng[50:46];
            step_rng(); b_sign = rng[0]; b_is_zero = (rng[4:1] == 0); b_is_nar = (rng[8:5] == 0);
            b_sf = (i[1:0] == 2'b00) ? a_sf : $signed(rng[19:9]);
            b_frac = (i[2:0] == 3'b000) ? a_frac : rng[45:20];
            check_one();
        end
        $display("S1_PREPARE_EQUIV_PASS checks=%0d mismatches=0", checks);
        $finish;
    end
endmodule
