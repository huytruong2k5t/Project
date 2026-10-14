//-----------------------------------------------------------------------------
// File          : ops_refactor_checker.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-14
// Description   : New/archived RTL and independent binary-input oracle checker.
// $Source: $ $Revision: 1.0 $ $Log: OPS parallel-path verification. $
//-----------------------------------------------------------------------------
module ops_refactor_checker #(
    parameter int F = 27,
    parameter int FW = 12,
    parameter int SW = 11,
    parameter int WW = (F > 1) ? $clog2(F + 1) : 1
)(
    output bit done = 1'b0
);
    typedef logic [F-1:0] frac_value_t;
    typedef logic [SW-1:0] sf_value_t;
    typedef logic [WW-1:0] width_value_t;
    logic [F-1:0] frac_a;
    logic [F-1:0] frac_b;
    logic s_a;
    logic s_b;
    logic signed [SW-1:0] sf_a;
    logic signed [SW-1:0] sf_b;
    logic cfg_mode;
    logic [1:0] cfg_ops;
    wire [F-1:0] x_new [3:0];
    wire [F-1:0] x_old [3:0];
    wire [F:0] y_new [3:0];
    wire [F:0] y_old [3:0];
    wire [WW-1:0] width_new [3:0];
    wire [WW-1:0] width_old [3:0];
    wire signed [SW-1:0] sf_new [3:0];
    wire signed [SW-1:0] sf_old [3:0];
    wire sign_new [3:0];
    wire sign_old [3:0];
    wire swap_new [3:0];
    wire swap_old [3:0];
    wire cut_new [3:0];
    wire cut_old [3:0];
    wire error_new [3:0];
    wire error_old [3:0];
    integer unsigned random_state;
    integer unsigned checks;
    localparam logic [F-1:0] FULL_MASK = {F{1'b1}};

    genvar feature;
    generate
        for (feature = 0; feature < 4; feature++) begin : g_features
            ops_sel_comb #(
                .FRAC_MAX(F),
                .FRAC_W(FW),
                .SF_W(SW),
                .WIDTH_W(WW),
                .EXACT_EN((feature & 1) != 0),
                .OPS_EN((feature & 2) != 0)
            ) dut (
                .frac_a(frac_a),
                .frac_b(frac_b),
                .s_a(s_a),
                .s_b(s_b),
                .sf_a(sf_a),
                .sf_b(sf_b),
                .cfg_mode(cfg_mode),
                .cfg_ops(cfg_ops),
                .x_frac(x_new[feature]),
                .y_mant(y_new[feature]),
                .active_width(width_new[feature]),
                .sign_o(sign_new[feature]),
                .sf_o(sf_new[feature]),
                .swapped(swap_new[feature]),
                .input_cut(cut_new[feature]),
                .cfg_error(error_new[feature])
            );
            ops_sel_before #(
                .FRAC_MAX(F),
                .FRAC_W(FW),
                .SF_W(SW),
                .WIDTH_W(WW),
                .EXACT_EN((feature & 1) != 0),
                .OPS_EN((feature & 2) != 0)
            ) reference_dut (
                .frac_a(frac_a),
                .frac_b(frac_b),
                .s_a(s_a),
                .s_b(s_b),
                .sf_a(sf_a),
                .sf_b(sf_b),
                .cfg_mode(cfg_mode),
                .cfg_ops(cfg_ops),
                .x_frac(x_old[feature]),
                .y_mant(y_old[feature]),
                .active_width(width_old[feature]),
                .sign_o(sign_old[feature]),
                .sf_o(sf_old[feature]),
                .swapped(swap_old[feature]),
                .input_cut(cut_old[feature]),
                .cfg_error(error_old[feature])
            );
        end
    endgenerate

    function automatic integer unsigned random_word;
        begin
            random_state = random_state ^ (random_state << 13);
            random_state = random_state ^ (random_state >> 17);
            random_state = random_state ^ (random_state << 5);
            random_word = random_state;
        end
    endfunction

    task check(input logic [F-1:0] a_value,
               input logic [F-1:0] b_value,
               input integer mode_value,
               input integer policy_value);
        integer unsigned a_eff, b_eff, x_exp, y_exp, width_exp;
        integer unsigned count_a, count_b, low_mask;
        integer sf_exp;
        logic error_exp, swap_exp, cut_exp, sign_exp;
        begin
            frac_a = a_value;
            frac_b = b_value;
            cfg_mode = mode_value[0];
            cfg_ops = policy_value[1:0];
            s_a = checks[3];
            s_b = checks[5];
            // Exercise signed wrap, including min/max signed scale.
            sf_a = sf_value_t'(random_word());
            sf_b = sf_value_t'(random_word());
            #1;
            width_exp = cfg_mode ? FW : F;
            a_eff = int'(frac_a) >> (F - width_exp);
            b_eff = int'(frac_b) >> (F - width_exp);
            count_a = 0;
            count_b = 0;
            for (integer bit_index = 0; bit_index < F; bit_index++) begin
                count_a = count_a + ((a_eff >> bit_index) & 1);
                count_b = count_b + ((b_eff >> bit_index) & 1);
            end
            low_mask = (32'd1 << (F - FW)) - 1;
            for (integer feat = 0; feat < 4; feat++) begin
                if ({x_new[feat], y_new[feat], width_new[feat], sign_new[feat],
                     sf_new[feat], swap_new[feat], cut_new[feat], error_new[feat]} !==
                    {x_old[feat], y_old[feat], width_old[feat], sign_old[feat],
                     sf_old[feat], swap_old[feat], cut_old[feat], error_old[feat]}) begin
                    $fatal(1, "OPS RTL differs F=%0d FW=%0d feature=%0d row=%0d a=%h b=%h mode=%0d ops=%0d",
                        F, FW, feat, checks, frac_a, frac_b, cfg_mode, cfg_ops);
                end
                error_exp = cfg_ops > 1 || (!(feat & 2) && cfg_ops != 0)
                          || (!(feat & 1) && !cfg_mode);
                swap_exp = !error_exp && (feat & 2) != 0 && cfg_ops == 1 && count_b < count_a;
                x_exp = error_exp ? 0 : swap_exp ? b_eff : a_eff;
                y_exp = error_exp ? 0 : (32'd1 << width_exp) | (swap_exp ? a_eff : b_eff);
                sf_exp = error_exp ? 0 : int'($signed(sf_a)) + int'($signed(sf_b));
                sign_exp = !error_exp && (s_a ^ s_b);
                cut_exp = !error_exp && cfg_mode && ((int'(frac_a) | int'(frac_b)) & low_mask) != 0;
                if ({x_new[feat], y_new[feat], width_new[feat], sign_new[feat],
                     sf_new[feat], swap_new[feat], cut_new[feat], error_new[feat]} !==
                    {x_exp[F-1:0], y_exp[F:0], (error_exp ? width_value_t'(0) : width_value_t'(width_exp)),
                     sign_exp, sf_exp[SW-1:0], swap_exp, cut_exp, error_exp}) begin
                    $fatal(1, "OPS oracle differs F=%0d FW=%0d feature=%0d row=%0d", F, FW, feat, checks);
                end
                checks = checks + 1;
            end
        end
    endtask

    initial begin
        checks = 0;
        random_state = 20261014 + F*100 + FW + SW*10000 + WW;
        if (F <= 5) begin
            for (integer a_index = 0; a_index < (1 << F); a_index++) begin
                for (integer b_index = 0; b_index < (1 << F); b_index++) begin
                    for (integer mode_index = 0; mode_index < 2; mode_index++) begin
                        for (integer policy = 0; policy < 4; policy++) begin
                            check(frac_value_t'(a_index), frac_value_t'(b_index), mode_index, policy);
                        end
                    end
                end
            end
        end else begin
            for (integer mode_index = 0; mode_index < 2; mode_index++) begin
                for (integer policy = 0; policy < 4; policy++) begin
                    check('0, '0, mode_index, policy);
                    check(FULL_MASK, FULL_MASK, mode_index, policy);
                    check(FULL_MASK, '0, mode_index, policy);
                    check('0, FULL_MASK, mode_index, policy);
                    check(frac_value_t'(32'haaaaaaaa), frac_value_t'(32'h55555555), mode_index, policy);
                    for (integer position = 0; position < F; position++) begin
                        check(frac_value_t'(32'd1 << position), FULL_MASK, mode_index, policy);
                        check(FULL_MASK, frac_value_t'(32'd1 << position), mode_index, policy);
                        check(frac_value_t'(32'd1 << position), frac_value_t'(32'd1 << position), mode_index, policy);
                    end
                end
            end
            for (integer trial = 0; trial < 256; trial++) begin
                check(frac_value_t'(random_word()), frac_value_t'(random_word()), trial%2, (trial/2)%4);
            end
        end
        $display("OPS REFACTOR PASS F=%0d FW=%0d SW=%0d WW=%0d checks=%0d mismatch=0", F, FW, SW, WW, checks);
        done = 1'b1;
    end
endmodule
// End of ops_refactor_checker.sv
