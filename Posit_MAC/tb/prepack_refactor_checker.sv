// Old RTL, constant-map RTL and an independent mask/shift arithmetic oracle.
`timescale 1ns/1ps
module prepack_refactor_checker #(
    parameter int FRAC_MAX = 5,
    parameter int FRAC_W = 5,
    parameter bit EXACT_EN = 1,
    parameter int ACC_W = EXACT_EN ? ((2*FRAC_MAX+2 > FRAC_W+4) ? 2*FRAC_MAX+2 : FRAC_W+4) : FRAC_W+4,
    parameter int SF_W = 6,
    parameter int F_IN = 2*FRAC_MAX+1
)(
    output bit done = 0
);
    typedef logic [ACC_W-1:0] acc_t;
    typedef logic [F_IN-1:0] frac_t;
    typedef logic signed [SF_W-1:0] sf_t;
    logic cfg_mode;
    acc_t acc;
    sf_t sf;
    wire signed [SF_W-1:0] sf_old, sf_new;
    wire [F_IN-1:0] frac_old, frac_new;
    logic [31:0] rng = 20261016 + FRAC_MAX*100 + FRAC_W + ACC_W + F_IN;
    longint checks = 0;

    mul_prepack_norm_comb #(
        .FRAC_MAX(FRAC_MAX), .FRAC_W(FRAC_W), .EXACT_EN(EXACT_EN),
        .ACC_W(ACC_W), .SF_W(SF_W), .F_IN(F_IN)
    ) u_new (
        .cfg_mode(cfg_mode), .acc(acc), .sf(sf), .sf_norm(sf_new), .frac_norm(frac_new)
    );
    mul_prepack_norm_before #(
        .FRAC_MAX(FRAC_MAX), .FRAC_W(FRAC_W), .EXACT_EN(EXACT_EN),
        .ACC_W(ACC_W), .SF_W(SF_W), .F_IN(F_IN)
    ) u_old (
        .cfg_mode(cfg_mode), .acc(acc), .sf(sf), .sf_norm(sf_old), .frac_norm(frac_old)
    );

    task automatic check_value;
        acc_t grid_value, fraction_part;
        frac_t expected_fraction;
        sf_t expected_sf;
        integer q_value, hidden;
        bit carry_bit;
        #1;
        grid_value = cfg_mode ? acc >> 2 : acc;
        q_value = cfg_mode ? FRAC_W : 2*FRAC_MAX;
        carry_bit = grid_value[q_value+1];
        hidden = q_value + int'(carry_bit);
        fraction_part = grid_value & ((acc_t'(1) << hidden) - acc_t'(1));
        if (hidden > F_IN)
            expected_fraction = frac_t'(fraction_part >> (hidden-F_IN));
        else
            expected_fraction = frac_t'(fraction_part) << (F_IN-hidden);
        expected_sf = sf + sf_t'(carry_bit);
        if ({sf_new,frac_new} !== {sf_old,frac_old} ||
            {sf_new,frac_new} !== {expected_sf,expected_fraction})
            $fatal(1, "PREPACK FAIL F=%0d FW=%0d EN=%0d AW=%0d SW=%0d FIN=%0d mode=%b acc=%h sf=%0d old=%h/%h new=%h/%h expected=%h/%h",
                   FRAC_MAX, FRAC_W, EXACT_EN, ACC_W, SF_W, F_IN,
                   cfg_mode, acc, sf, sf_old, frac_old, sf_new, frac_new, expected_sf, expected_fraction);
        checks++;
    endtask

    initial begin
        // Exhaustive all encoded accumulator/scale values on the small tuples.
        if (ACC_W <= 8 && SF_W <= 4) begin
            for (integer mode_value=EXACT_EN ? 0 : 1; mode_value<2; mode_value++) begin
                cfg_mode = 1'(mode_value);
                for (integer a=0; a<(1<<ACC_W); a++) begin
                    acc = acc_t'(a);
                    for (integer scale=0; scale<(1<<SF_W); scale++) begin
                        sf = sf_t'(scale);
                        check_value();
                    end
                end
            end
        end else begin
            for (integer mode_value=EXACT_EN ? 0 : 1; mode_value<2; mode_value++) begin
                cfg_mode = 1'(mode_value);
                for (integer sample=0; sample<20000; sample++) begin
                    for (integer bit_base=0; bit_base<ACC_W; bit_base+=32) begin
                        rng ^= rng << 13;
                        rng ^= rng >> 17;
                        rng ^= rng << 5;
                        acc = (acc << 32) | acc_t'(rng);
                    end
                    sf = sf_t'(rng);
                    if (sample < 2*ACC_W) begin
                        acc = acc_t'(1) << (sample/2);
                        if (sample%2) acc = ~acc;
                    end
                    case (sample%8)
                        0: sf = '0;
                        1: sf = '1;
                        2: sf = {1'b0, {(SF_W-1){1'b1}}};
                        3: sf = {1'b1, {(SF_W-1){1'b0}}};
                        default: begin end
                    endcase
                    check_value();
                end
            end
        end
        $display("PREPACK PASS F=%0d FW=%0d EN=%0d AW=%0d SW=%0d FIN=%0d checks=%0d",
                 FRAC_MAX, FRAC_W, EXACT_EN, ACC_W, SF_W, F_IN, checks);
        done = 1;
    end
endmodule
