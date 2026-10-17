// OPT05 independent serial scan oracle, plus original/candidate equivalence.
module opt05_sac_checker #(
    parameter int W = 12,
    parameter int S = $clog2(W+1)
)(output logic done);
    logic [W-1:0] fx;
    logic [S-1:0] scale;
    wire [4:0] valid_o, exhausted_o, error_o;
    wire [S-1:0] sa_o [4:0], scale_o [4:0];
    wire [W-1:0] fx_o [4:0];
    longint unsigned checks;
    int unsigned rng;
    typedef logic [W-1:0] frac_t;
    typedef logic [S-1:0] scale_t;

    sac_step_baseline #(.W_X(W), .S_W(S)) u_ref (
        .fx(fx), .scale(scale), .term_valid(valid_o[0]), .sa(sa_o[0]),
        .scale_next(scale_o[0]), .fx_next(fx_o[0]),
        .exhausted(exhausted_o[0]), .state_error(error_o[0])
    );
    sac_step_a #(.W_X(W), .S_W(S)) u_a (
        .fx(fx), .scale(scale), .term_valid(valid_o[1]), .sa(sa_o[1]),
        .scale_next(scale_o[1]), .fx_next(fx_o[1]),
        .exhausted(exhausted_o[1]), .state_error(error_o[1])
    );
    sac_step_ab #(.W_X(W), .S_W(S)) u_ab (
        .fx(fx), .scale(scale), .term_valid(valid_o[2]), .sa(sa_o[2]),
        .scale_next(scale_o[2]), .fx_next(fx_o[2]),
        .exhausted(exhausted_o[2]), .state_error(error_o[2])
    );
    sac_step_abc_sub #(.W_X(W), .S_W(S)) u_sub (
        .fx(fx), .scale(scale), .term_valid(valid_o[3]), .sa(sa_o[3]),
        .scale_next(scale_o[3]), .fx_next(fx_o[3]),
        .exhausted(exhausted_o[3]), .state_error(error_o[3])
    );
    sac_step_abc_tree #(.W_X(W), .S_W(S)) u_tree (
        .fx(fx), .scale(scale), .term_valid(valid_o[4]), .sa(sa_o[4]),
        .scale_next(scale_o[4]), .fx_next(fx_o[4]),
        .exhausted(exhausted_o[4]), .state_error(error_o[4])
    );

    function automatic int unsigned random_next(input int unsigned value);
        int unsigned next_value;
        next_value = value ^ (value << 13);
        next_value = next_value ^ (next_value >> 17);
        return next_value ^ (next_value << 5);
    endfunction

    task automatic check(input frac_t f, input scale_t s);
        int leading, step_value, total;
        bit found, err, valid_ref, exhausted_ref;
        frac_t fx_ref;
        scale_t sa_ref, next_ref;
        fx = f;
        scale = s;
        #1;
        found = 0;
        leading = 0;
        for (int j = W-1; j >= 0; j--) begin
            if (!found) begin
                if (f[j]) found = 1;
                else leading++;
            end
        end
        step_value = found ? leading+1 : 0;
        total = int'(s) + step_value;
        err = int'(s) > W || (found && total > W);
        valid_ref = found && !err;
        sa_ref = valid_ref ? scale_t'(step_value) : '0;
        next_ref = valid_ref ? scale_t'(total) : s;
        fx_ref = valid_ref ? frac_t'(f << step_value) : f;
        exhausted_ref = !found || (valid_ref && fx_ref == '0);
        for (int variant = 0; variant < 5; variant++) begin
            if ({valid_o[variant], sa_o[variant], scale_o[variant], fx_o[variant],
                 exhausted_o[variant], error_o[variant]} !==
                {valid_ref, sa_ref, next_ref, fx_ref, exhausted_ref, err}) begin
                $fatal(1, "SAC mismatch W=%0d S=%0d variant=%0d fx=%h scale=%d",
                       W, S, variant, f, s);
            end
        end
        checks++;
    endtask

    initial begin
        done = 0;
        checks = 0;
        rng = 20261017 + 100*W + S;
        fx = '0;
        scale = '0;
        // Exhaustive all fx and all representable scales through W=10.
        // W11/12 exhaust fx at six boundaries, then use seeded random.
        if (W <= 10) begin
            for (int f = 0; f < (1 << W); f++) begin
                for (int s = 0; s < (1 << S); s++) check(frac_t'(f), scale_t'(s));
            end
        end else if (W <= 12) begin
            for (int f = 0; f < (1 << W); f++) begin
                check(frac_t'(f), '0);
                check(frac_t'(f), scale_t'(W-1));
                check(frac_t'(f), scale_t'(W));
                check(frac_t'(f), scale_t'(W+1));
                check(frac_t'(f), '1);
            end
        end
        for (int s = 0; s < (1 << S); s++) begin
            check('0, scale_t'(s));
            check('1, scale_t'(s));
            for (int bit_no = 0; bit_no < W; bit_no++) begin
                check(frac_t'(1) << bit_no, scale_t'(s));
                check((frac_t'(1) << bit_no) | frac_t'(1), scale_t'(s));
            end
        end
        for (int i = 0; i < 20000; i++) begin
            rng = random_next(rng);
            fx = frac_t'(rng);
            rng = random_next(rng);
            check(fx, scale_t'(rng));
        end
        $display("SAC PASS W=%0d S=%0d checks=%0d variants=5 mismatches=0", W, S, checks);
        done = 1;
    end
endmodule
