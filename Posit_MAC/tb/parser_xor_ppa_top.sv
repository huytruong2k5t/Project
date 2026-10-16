// Registered input boundary for matched parser P1/P2 measurements.
module parser_xor_ppa_top #(
    parameter int ES = 2,
    parameter int F = 32 - 3 - ES,
    parameter int SF_W = $clog2(64'd4 * 30 * (64'd1 << ES) + 4) + 1
)(
    input logic clk,
    input logic reset_n,
    input logic [31:0] p,
    input logic in_valid,
    input logic out_ready,
    output wire in_ready,
    output wire out_valid,
    output wire s,
    output wire is_zero,
    output wire is_nar,
    output wire signed [SF_W-1:0] sf,
    output wire [F-1:0] frac
);
    logic [31:0] p_q;
    logic in_valid_q;
    logic out_ready_q;
    // Benchmark stimulus bank; not part of the production parser or its latency.
    always_ff @(posedge clk) begin
        p_q <= p;
        in_valid_q <= in_valid;
        out_ready_q <= out_ready;
    end
    posit_parser #(.NB(32), .ES(ES)) u_parser (
        .clk(clk), .reset_n(reset_n), .p(p_q),
        .in_valid(in_valid_q), .in_ready(in_ready),
        .out_ready(out_ready_q), .out_valid(out_valid),
        .s(s), .is_zero(is_zero), .is_nar(is_nar), .sf(sf), .frac(frac)
    );
endmodule
