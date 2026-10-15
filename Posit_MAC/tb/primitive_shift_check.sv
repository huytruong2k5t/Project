// Independent per-output-bit oracle; baseline and candidate checked together.
`timescale 1ns/1ps
module primitive_shift_check #(
    parameter int N = 26,
    parameter int W = 5
)(output bit done = 0);
    logic [N-1:0] data;
    logic [W-1:0] amount;
    logic fill;
    wire [N-1:0] left_old, left_new;
    wire [N-1:0] right_old, right_new;
    wire [N-1:0] arith_old, arith_new;

    dyn_left_shifter_reference #(.N(N), .SHIFT_W(W)) u_lo (
        .in(data), .b(amount), .out(left_old));
    dyn_left_shifter #(.N(N), .SHIFT_W(W)) u_ln (
        .in(data), .b(amount), .out(left_new));
    dyn_right_shifter_reference #(.N(N), .SHIFT_W(W)) u_ro (
        .in(data), .b(amount), .fill_val(fill), .out(right_old));
    dyn_right_shifter #(.N(N), .SHIFT_W(W)) u_rn (
        .in(data), .b(amount), .fill_val(fill), .out(right_new));
    dyn_right_shifter_reference #(.N(N), .SHIFT_W(W), .ARITH(1'b1)) u_ao (
        .in(data), .b(amount), .fill_val(fill), .out(arith_old));
    dyn_right_shifter #(.N(N), .SHIFT_W(W), .ARITH(1'b1)) u_an (
        .in(data), .b(amount), .fill_val(fill), .out(arith_new));

    function automatic logic [N-1:0] oracle(input bit left, input logic pad);
        logic [N-1:0] value;
        int source_index;
        for (int j = 0; j < N; j++) begin
            source_index = left ? j - int'(amount) : j + int'(amount);
            value[j] = (source_index >= 0 && source_index < N)
                ? data[source_index] : (left ? 1'b0 : pad);
        end
        return value;
    endfunction

    initial begin
        logic [63:0] rng;
        int patterns;
        longint unsigned checks;
        rng = 64'd20261015 + 64'(N*100+W);
        checks = 0;
        patterns = (N <= 8) ? (1 << N) : 500;
        for (int p = 0; p < patterns; p++) begin
            rng = rng ^ (rng << 13);
            rng = rng ^ (rng >> 7);
            rng = rng ^ (rng << 17);
            if (N <= 8) data = N'(p);
            else case (p % 6)
                0: data = '0;
                1: data = '1;
                2: data = N'(64'h1 << (p % N));
                3: data = ~N'(64'h1 << (p % N));
                default: data = N'(rng);
            endcase
            for (int f = 0; f < 2; f++) begin
                for (int sh = 0; sh < (1 << W); sh++) begin
                    fill = 1'(f);
                    amount = W'(sh);
                    #1;
                    if (left_old !== oracle(1, 0) || left_new !== left_old
                        || right_old !== oracle(0, fill) || right_new !== right_old
                        || arith_old !== oracle(0, data[N-1]) || arith_new !== arith_old)
                        $fatal(1, "SHIFT_FAIL N=%0d W=%0d data=%h sh=%0d fill=%b", N, W, data, sh, fill);
                    checks += 6;
                end
            end
        end
        $display("SHIFT_PASS N=%0d W=%0d checks=%0d", N, W, checks);
        done = 1;
    end
endmodule
