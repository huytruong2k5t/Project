`timescale 1ns/1ps
// One step includes legal and deliberately invalid accumulated scales.
module sac_frontend_checker #(
    parameter int W_X = 12
)(
    output bit done = 1'b0
);
    localparam int S_W = (W_X > 1) ? $clog2(W_X + 1) : 1;
    logic [W_X-1:0] fx;
    logic [S_W-1:0] scale;
    wire term_valid;
    wire [S_W-1:0] sa;
    wire [S_W-1:0] scale_next;
    wire [W_X-1:0] fx_next;
    wire exhausted;
    wire state_error;

    sac_step_comb #(
        .W_X(W_X)
    ) dut (
        .fx(fx),
        .scale(scale),
        .term_valid(term_valid),
        .sa(sa),
        .scale_next(scale_next),
        .fx_next(fx_next),
        .exhausted(exhausted),
        .state_error(state_error)
    );

    initial begin
        string filename;
        int fd;
        int read_count;
        int scale_exp;
        int sa_exp;
        int scale_next_exp;
        int valid_exp;
        int exhausted_exp;
        int error_exp;
        logic [W_X-1:0] fx_exp;
        logic [W_X-1:0] fx_next_exp;
        longint unsigned checks;

        filename = $sformatf("sac_%0d.txt", W_X);
        fd = $fopen(filename, "r");
        if (!fd) $fatal(1, "missing fixture %s", filename);
        checks = 0;
        while (!$feof(fd)) begin
            read_count = $fscanf(fd, "%h %d %d %d %h %d %d %d\n",
                fx_exp, scale_exp, sa_exp, scale_next_exp, fx_next_exp,
                valid_exp, exhausted_exp, error_exp);
            if (read_count != 8) $fatal(1, "malformed SAC fixture W=%0d", W_X);
            fx = fx_exp;
            scale = scale_exp[S_W-1:0];
            #1;
            if (term_valid !== valid_exp[0] || sa !== sa_exp[S_W-1:0] ||
                scale_next !== scale_next_exp[S_W-1:0] || fx_next !== fx_next_exp ||
                exhausted !== exhausted_exp[0] || state_error !== error_exp[0]) begin
                $fatal(1, "WEEK9 SAC FAIL W=%0d row=%0d fx=%h S=%0d sa=%0d/%0d next=%h/%h",
                    W_X, checks, fx, scale, sa, sa_exp, fx_next, fx_next_exp);
            end
            ++checks;
        end
        $fclose(fd);
        if (checks == 0) $fatal(1, "empty SAC fixture");
        $display("WEEK9 SAC PASS W=%0d checks=%0d", W_X, checks);
        done = 1'b1;
    end
endmodule
