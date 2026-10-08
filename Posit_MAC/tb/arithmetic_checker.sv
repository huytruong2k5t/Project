`timescale 1ns/1ps
module arithmetic_checker #(
    parameter int F = 27,
    parameter int FW = (F < 12) ? F : 12,
    parameter int SCHEME = 0
)(
    output bit done = 1'b0
);
    localparam int AW = (2*F+2 > FW+4) ? 2*F+2 : FW+4;
    localparam int SW = (F > 1) ? $clog2(F+1) : 1;
    localparam int FIN = 2*F+1;
    logic mode, init_only, first, sticky_acc, numerical_tail;
    logic [F:0] y;
    logic [SW-1:0] scale;
    logic [AW-1:0] acc;
    logic signed [10:0] sf;
    wire [AW-1:0] base, term, acc_next;
    wire tail, sticky_next, numerical_next, carry_error;
    wire signed [10:0] sf_norm;
    wire [FIN-1:0] frac_norm;
    wire sticky_norm;
    sbm_shift_comb #(.FRAC_MAX(F), .FRAC_W(FW), .ROUND_SCHEME(SCHEME)) u_shift (
        .cfg_mode(mode), .y_mant(y), .scale(scale), .init_only(init_only),
        .y_base(base), .term(term), .term_tail(tail)
    );
    sbm_accum_comb #(.ACC_W(AW), .ROUND_SCHEME(SCHEME)) u_acc (
        .cfg_mode(mode), .first(first), .init_only(init_only), .y_base(base),
        .term(term), .term_tail(tail), .acc(acc), .sticky_acc(sticky_acc),
        .numerical_tail(numerical_tail), .acc_next(acc_next),
        .sticky_next(sticky_next), .numerical_next(numerical_next), .carry_error(carry_error)
    );
    mul_norm_comb #(.FRAC_MAX(F), .FRAC_W(FW), .ROUND_SCHEME(SCHEME)) u_norm (
        .cfg_mode(mode), .acc(acc_next), .sticky_acc(sticky_next), .sf(sf),
        .sf_norm(sf_norm), .frac_norm(frac_norm), .sticky_norm(sticky_norm)
    );
    initial begin
        int fd, rc, sf_i, sf_e;
        longint unsigned v[17:0];
        longint unsigned rows;
        fd = $fopen($sformatf("arithmetic_%0d_%0d.txt", F, SCHEME), "r");
        if (!fd) $fatal(1,"missing arithmetic fixture");
        rows = 0;
        while (!$feof(fd)) begin
            rc = $fscanf(fd,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %d %d %h %h\n",
                v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7],v[8],v[9],v[10],
                v[11],v[12],v[13],sf_i,sf_e,v[16],v[17]);
            if (rc != 18) $fatal(1,"malformed arithmetic fixture");
            mode=v[0][0]; y=v[1][F:0]; scale=v[2][SW-1:0]; init_only=v[3][0];
            first=v[4][0]; acc=v[5][AW-1:0]; sticky_acc=v[6][0]; numerical_tail=v[7][0];
            sf=sf_i[10:0];
            #2;
            if (base !== v[8][AW-1:0] || term !== v[9][AW-1:0] || tail !== v[10][0] ||
                acc_next !== v[11][AW-1:0] || sticky_next !== v[12][0] ||
                numerical_next !== v[13][0] || carry_error !== 0 ||
                sf_norm !== sf_e[10:0] || frac_norm !== v[16][FIN-1:0] || sticky_norm !== v[17][0])
                $fatal(1,"ARITHMETIC FAIL F=%0d scheme=%0d row=%0d mode=%b acc=%h/%h frac=%h/%h",
                    F,SCHEME,rows,mode,acc_next,v[11],frac_norm,v[16]);
            rows++;
        end
        $fclose(fd);
        $display("ARITHMETIC PASS F=%0d scheme=%0d rows=%0d",F,SCHEME,rows);
        done=1'b1;
    end
endmodule
