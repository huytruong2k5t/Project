//-----------------------------------------------------------------------------
// File          : primitive_ppa_boundary.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Measurement banks only; no protocol/state is owned here.
//                 KIND: 0 left, 1 dynamic-fill right, 2 LOD (MODE=0).
// $Source: $ $Revision: 1.0 $ $Log: Matched Xilinx primitive benchmarks. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module primitive_ppa_boundary #(
    parameter int N = 26,
    parameter int SHIFT_W = $clog2(N),
    parameter int KIND = 0,
    parameter int RESULT_W = (KIND == 2) ? $clog2(N)+1 : N
)(
    input logic clk,
    input logic [N-1:0] data,
    input logic [SHIFT_W-1:0] amount,
    input logic fill_val,
    output logic [RESULT_W-1:0] result
);
    logic [N-1:0] data_q;
    wire [RESULT_W-1:0] result_d;

    always_ff @(posedge clk) begin
        data_q <= `CK2Q data;
        result <= `CK2Q result_d;
    end

    generate
        if (KIND == 2) begin : g_lod
            wire [$clog2(N)-1:0] k_d;
            wire vld_d;
            lod_lzd_core #(.N(N)) u_dut (
                .in(data_q),
                .K(k_d),
                .vld(vld_d)
            );
            assign result_d = {vld_d, k_d};
        end else begin : g_shift
            logic [SHIFT_W-1:0] amount_q;
            always_ff @(posedge clk) begin
                amount_q <= `CK2Q amount;
            end

            if (KIND == 0) begin : g_left
                dyn_left_shifter #(.N(N), .SHIFT_W(SHIFT_W)) u_dut (
                    .in(data_q),
                    .b(amount_q),
                    .out(result_d)
                );
            end else begin : g_right
                logic fill_q;
                always_ff @(posedge clk) begin
                    fill_q <= `CK2Q fill_val;
                end
                dyn_right_shifter #(.N(N), .SHIFT_W(SHIFT_W)) u_dut (
                    .in(data_q),
                    .b(amount_q),
                    .fill_val(fill_q),
                    .out(result_d)
                );
            end
        end
    endgenerate
endmodule
// End of primitive_ppa_boundary.sv
