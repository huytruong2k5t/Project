// Compatibility export proof: all fill/shift combinations and data-bit bases.
`timescale 1ns/1ps
module tb_shifter_export;
    logic [13:0] data0 = '0;
    logic [2:0] amount0 = '0;
    logic fill0 = 1'b0;
    wire [13:0] original0, exported0;
    bit done0 = 1'b0;
    dyn_right_shifter_reference #(.N(14), .SHIFT_W(3), .ARITH(0)) ref0 (
        .in(data0), .b(amount0), .fill_val(fill0), .out(original0));
    dyn_right_shifter #(.N(14), .SHIFT_W(3), .ARITH(0)) exp0 (
        .in(data0), .b(amount0), .fill_val(fill0), .out(exported0));
    initial begin
        for (int f = 0; f < 2; ++f) begin
            fill0 = f;
            for (int a = 0; a < 8; ++a) begin
                amount0 = a;
                for (int bit_index = -2; bit_index < 14; ++bit_index) begin
                    if (bit_index == -2) data0 = '0;
                    else if (bit_index == -1) data0 = '1;
                    else data0 = 14'b1 << bit_index;
                    #2;
                    if (original0 !== exported0) $fatal(1, "export mismatch");
                end
            end
        end
        done0 = 1'b1;
    end
    logic [28:0] data1 = '0;
    logic [3:0] amount1 = '0;
    logic fill1 = 1'b0;
    wire [28:0] original1, exported1;
    bit done1 = 1'b0;
    dyn_right_shifter_reference #(.N(29), .SHIFT_W(4), .ARITH(0)) ref1 (
        .in(data1), .b(amount1), .fill_val(fill1), .out(original1));
    dyn_right_shifter #(.N(29), .SHIFT_W(4), .ARITH(0)) exp1 (
        .in(data1), .b(amount1), .fill_val(fill1), .out(exported1));
    initial begin
        for (int f = 0; f < 2; ++f) begin
            fill1 = f;
            for (int a = 0; a < 16; ++a) begin
                amount1 = a;
                for (int bit_index = -2; bit_index < 29; ++bit_index) begin
                    if (bit_index == -2) data1 = '0;
                    else if (bit_index == -1) data1 = '1;
                    else data1 = 29'b1 << bit_index;
                    #2;
                    if (original1 !== exported1) $fatal(1, "export mismatch");
                end
            end
        end
        done1 = 1'b1;
    end
    logic [59:0] data2 = '0;
    logic [4:0] amount2 = '0;
    logic fill2 = 1'b0;
    wire [59:0] original2, exported2;
    bit done2 = 1'b0;
    dyn_right_shifter_reference #(.N(60), .SHIFT_W(5), .ARITH(0)) ref2 (
        .in(data2), .b(amount2), .fill_val(fill2), .out(original2));
    dyn_right_shifter #(.N(60), .SHIFT_W(5), .ARITH(0)) exp2 (
        .in(data2), .b(amount2), .fill_val(fill2), .out(exported2));
    initial begin
        for (int f = 0; f < 2; ++f) begin
            fill2 = f;
            for (int a = 0; a < 32; ++a) begin
                amount2 = a;
                for (int bit_index = -2; bit_index < 60; ++bit_index) begin
                    if (bit_index == -2) data2 = '0;
                    else if (bit_index == -1) data2 = '1;
                    else data2 = 60'b1 << bit_index;
                    #2;
                    if (original2 !== exported2) $fatal(1, "export mismatch");
                end
            end
        end
        done2 = 1'b1;
    end
    logic [58:0] data3 = '0;
    logic [4:0] amount3 = '0;
    logic fill3 = 1'b0;
    wire [58:0] original3, exported3;
    bit done3 = 1'b0;
    dyn_right_shifter_reference #(.N(59), .SHIFT_W(5), .ARITH(0)) ref3 (
        .in(data3), .b(amount3), .fill_val(fill3), .out(original3));
    dyn_right_shifter #(.N(59), .SHIFT_W(5), .ARITH(0)) exp3 (
        .in(data3), .b(amount3), .fill_val(fill3), .out(exported3));
    initial begin
        for (int f = 0; f < 2; ++f) begin
            fill3 = f;
            for (int a = 0; a < 32; ++a) begin
                amount3 = a;
                for (int bit_index = -2; bit_index < 59; ++bit_index) begin
                    if (bit_index == -2) data3 = '0;
                    else if (bit_index == -1) data3 = '1;
                    else data3 = 59'b1 << bit_index;
                    #2;
                    if (original3 !== exported3) $fatal(1, "export mismatch");
                end
            end
        end
        done3 = 1'b1;
    end
    initial begin
        wait (done0 && done1 && done2 && done3);
        $display("SHIFTER EXPORT PASS basis_checks=9120");
        $finish;
    end
endmodule
