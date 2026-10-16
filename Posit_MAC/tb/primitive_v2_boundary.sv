//-----------------------------------------------------------------------------
// File          : primitive_v2_boundary.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP
// Creation Date : 2026-10-16
// Description   : Matched measurement banks; no protocol or pipeline in DUT.
// $Source: $ $Revision: 2.0 $ $Log: Leaf, LOD-to-shift, LOD-plus-one-to-shift. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module primitive_v2_boundary #(
    parameter int N = 30,
    parameter int KIND = 2,
    parameter int MODE = 0,
    parameter int ARITH = 0,
    parameter int FILL_KIND = 1,
    parameter int SHIFT_W = (N > 1) ? $clog2(N) : 1,
    parameter int RESULT_W = (KIND == 2) ? SHIFT_W+1
                          : (KIND >= 3) ? N+SHIFT_W+1 : N
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
        if (KIND >= 2) begin : g_detector
            wire [SHIFT_W-1:0] count;
            wire found;
            lod_lzd_core #(.N(N), .MODE(MODE), .S(SHIFT_W)) u_lod (
                .in(data_q),
                .K(count),
                .vld(found)
            );
            if (KIND == 2) begin : g_leaf
                assign result_d = {found, count};
            end else begin : g_chain
                wire [N-1:0] shifted;
                wire [SHIFT_W:0] shift_control;
                if (KIND == 4) begin : g_increment
                    assign shift_control = {1'b0, count} + 1'b1;
                end else begin : g_direct
                    assign shift_control = {1'b0, count};
                end
                dyn_left_shifter #(.N(N), .SHIFT_W(SHIFT_W+1)) u_shift (
                    .in(data_q),
                    .b(shift_control),
                    .out(shifted)
                );
                assign result_d = {found, count, shifted};
            end
        end else begin : g_shift
            logic [SHIFT_W-1:0] amount_q;
            always_ff @(posedge clk) begin
                amount_q <= `CK2Q amount;
            end
            if (KIND == 0) begin : g_left
                dyn_left_shifter #(.N(N), .SHIFT_W(SHIFT_W)) u_shift (
                    .in(data_q), .b(amount_q), .out(result_d)
                );
            end else begin : g_right
                wire fill;
                if (FILL_KIND == 0) begin : g_zero
                    assign fill = 1'b0;
                end else begin : g_dynamic
                    logic fill_q;
                    always_ff @(posedge clk) begin
                        fill_q <= `CK2Q fill_val;
                    end
                    assign fill = fill_q;
                end
                dyn_right_shifter #(.N(N), .SHIFT_W(SHIFT_W), .ARITH(ARITH)) u_shift (
                    .in(data_q), .b(amount_q), .fill_val(fill), .out(result_d)
                );
            end
        end
    endgenerate
endmodule
// End of primitive_v2_boundary.sv
