`timescale 1ns/1ps
// Week9 OPS fixture checker; main and disabled-feature instances.
module ops_frontend_checker #(
    parameter int F = 27,
    parameter int FW = 12
)(
    output bit done = 1'b0
);
    localparam int SW = F == 1 ? 5 : F == 5 ? 6 : F == 12 ? 8 : F == 26 ? 11 : 10;
    localparam int WW = (F > 1) ? $clog2(F + 1) : 1;
    logic [F-1:0] frac_a;
    logic [F-1:0] frac_b;
    logic s_a;
    logic s_b;
    logic signed [SW-1:0] sf_a;
    logic signed [SW-1:0] sf_b;
    logic cfg_mode;
    logic [1:0] cfg_ops;
    wire [F-1:0] x_frac;
    wire [F:0] y_mant;
    wire [WW-1:0] active_width;
    wire sign_o;
    wire signed [SW-1:0] sf_o;
    wire swapped;
    wire input_cut;
    wire cfg_error;
    wire [F-1:0] x_frac_disabled;
    wire [F:0] y_mant_disabled;
    wire [WW-1:0] active_width_disabled;
    wire sign_o_disabled;
    wire signed [SW-1:0] sf_o_disabled;
    wire swapped_disabled;
    wire input_cut_disabled;
    wire cfg_error_disabled;

    ops_sel_comb #(
        .FRAC_MAX(F),
        .FRAC_W(FW),
        .SF_W(SW)
    ) dut (
        .frac_a(frac_a),
        .frac_b(frac_b),
        .s_a(s_a),
        .s_b(s_b),
        .sf_a(sf_a),
        .sf_b(sf_b),
        .cfg_mode(cfg_mode),
        .cfg_ops(cfg_ops),
        .x_frac(x_frac),
        .y_mant(y_mant),
        .active_width(active_width),
        .sign_o(sign_o),
        .sf_o(sf_o),
        .swapped(swapped),
        .input_cut(input_cut),
        .cfg_error(cfg_error)
    );

    ops_sel_comb #(
        .FRAC_MAX(F),
        .FRAC_W(FW),
        .SF_W(SW),
        .EXACT_EN(1'b0),
        .OPS_EN(1'b0)
    ) dut_disabled (
        .frac_a(frac_a),
        .frac_b(frac_b),
        .s_a(s_a),
        .s_b(s_b),
        .sf_a(sf_a),
        .sf_b(sf_b),
        .cfg_mode(cfg_mode),
        .cfg_ops(cfg_ops),
        .x_frac(x_frac_disabled),
        .y_mant(y_mant_disabled),
        .active_width(active_width_disabled),
        .sign_o(sign_o_disabled),
        .sf_o(sf_o_disabled),
        .swapped(swapped_disabled),
        .input_cut(input_cut_disabled),
        .cfg_error(cfg_error_disabled)
    );

    initial begin
        string filename;
        int fd;
        int read_count;
        int mode_exp;
        int policy_exp;
        int sign_a_exp;
        int sign_b_exp;
        int sf_a_exp;
        int sf_b_exp;
        int width_exp;
        int sign_exp;
        int sf_exp;
        int swap_exp;
        int cut_exp;
        int error_exp;
        logic [F-1:0] a_exp;
        logic [F-1:0] b_exp;
        logic [F-1:0] x_exp;
        logic [F:0] y_exp;
        logic disabled_error_exp;
        longint unsigned checks;

        filename = $sformatf("ops_%0d.txt", F);
        fd = $fopen(filename, "r");
        if (!fd) $fatal(1, "missing fixture %s", filename);
        checks = 0;
        while (!$feof(fd)) begin
            read_count = $fscanf(fd, "%h %h %d %d %d %d %d %d %h %h %d %d %d %d %d %d\n",
                a_exp, b_exp, mode_exp, policy_exp, sign_a_exp, sign_b_exp,
                sf_a_exp, sf_b_exp, x_exp, y_exp, width_exp,
                sign_exp, sf_exp, swap_exp, cut_exp, error_exp);
            if (read_count != 16) $fatal(1, "malformed OPS fixture F=%0d", F);
            frac_a = a_exp;
            frac_b = b_exp;
            cfg_mode = mode_exp[0];
            cfg_ops = policy_exp[1:0];
            s_a = sign_a_exp[0];
            s_b = sign_b_exp[0];
            sf_a = sf_a_exp[SW-1:0];
            sf_b = sf_b_exp[SW-1:0];
            #1;
            if (x_frac !== x_exp || y_mant !== y_exp || active_width !== width_exp[WW-1:0] ||
                sign_o !== sign_exp[0] || sf_o !== sf_exp[SW-1:0] || swapped !== swap_exp[0] ||
                input_cut !== cut_exp[0] || cfg_error !== error_exp[0]) begin
                $fatal(1, "WEEK9 OPS FAIL F=%0d row=%0d mode=%0d ops=%0d a=%h b=%h x=%h/%h y=%h/%h",
                    F, checks, cfg_mode, cfg_ops, frac_a, frac_b, x_frac, x_exp, y_mant, y_exp);
            end

            disabled_error_exp = !cfg_mode || cfg_ops != 0;
            if (cfg_error_disabled !== disabled_error_exp) $fatal(1, "WEEK9 disabled config error");
            if (disabled_error_exp) begin
                if ({x_frac_disabled, y_mant_disabled, active_width_disabled,
                     sign_o_disabled, sf_o_disabled, swapped_disabled, input_cut_disabled} !== '0)
                    $fatal(1, "WEEK9 invalid config output");
            end else begin
                if ({x_frac_disabled, y_mant_disabled, active_width_disabled,
                     sign_o_disabled, sf_o_disabled, swapped_disabled, input_cut_disabled} !==
                    {x_frac, y_mant, active_width, sign_o, sf_o, swapped, input_cut})
                    $fatal(1, "WEEK9 disabled-feature fixed-A output");
            end
            ++checks;
        end
        $fclose(fd);
        if (checks == 0) $fatal(1, "empty OPS fixture");
        $display("WEEK9 OPS PASS F=%0d FW=%0d checks=%0d", F, FW, checks);
        done = 1'b1;
    end
endmodule
