// Linear scan oracle, including the invalid K=0 contract and S overrides.
`timescale 1ns/1ps
module primitive_lod_check #(
    parameter int N = 26,
    parameter int S = $clog2(N),
    parameter int MODE = 0
)(output bit done = 0);
    logic [N-1:0] data;
    wire [S-1:0] k_old, k_new;
    wire vld_old, vld_new;
    lod_lzd_core_reference #(.N(N), .S(S), .MODE(MODE)) u_old (
        .in(data), .K(k_old), .vld(vld_old));
    lod_lzd_core #(.N(N), .S(S), .MODE(MODE)) u_new (
        .in(data), .K(k_new), .vld(vld_new));

    task automatic check_one;
        bit found;
        logic [S-1:0] expected;
        found = 0;
        expected = '0;
        for (int j = 0; j < N; j++) begin
            if (!found && (data[N-1-j] == (MODE != 1))) begin
                found = 1;
                expected = S'(j);
            end
        end
        #1;
        if ({vld_old, k_old} !== {found, expected}
            || {vld_new, k_new} !== {vld_old, k_old})
            $fatal(1, "LOD_FAIL N=%0d S=%0d MODE=%0d data=%h old=%b/%0d new=%b/%0d ref=%b/%0d",
                N, S, MODE, data, vld_old, k_old, vld_new, k_new, found, expected);
    endtask

    initial begin
        logic [63:0] rng;
        int patterns;
        rng = 64'd20261015 + 64'(N*100+S*10+MODE);
        patterns = (N <= 12) ? (1 << N) : 10000;
        for (int p = 0; p < patterns; p++) begin
            rng = rng ^ (rng << 13);
            rng = rng ^ (rng >> 7);
            rng = rng ^ (rng << 17);
            data = (N <= 12) ? N'(p) : N'(rng);
            check_one();
        end
        data = '0;
        check_one();
        data = '1;
        check_one();
        for (int p = 0; p < N; p++) begin
            data = N'(64'h1 << p);
            check_one();
            data = ~N'(64'h1 << p);
            check_one();
        end
        $display("LOD_PASS N=%0d S=%0d MODE=%0d checks=%0d", N, S, MODE, 2*(patterns+2+2*N));
        done = 1;
    end
endmodule
