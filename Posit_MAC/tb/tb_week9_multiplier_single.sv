`timescale 1ns/1ps
// One profile per process; same driver/checker as the concurrent sixteen-profile TB.
module tb_week9_multiplier_single #(
    parameter int NB=32,
    parameter int ES=2,
    parameter int SCHEME=0,
    parameter int ROUNDING=0,
    parameter VECTOR_DIR="."
);
    wire done;
    multiplier_checker #(
        .NB(NB),
        .ES(ES),
        .SCHEME(SCHEME),
        .ROUNDING(ROUNDING),
        .VECTOR_DIR(VECTOR_DIR)
    ) u_checker (
        .done(done)
    );
    initial begin
        wait(done);
        $display("WEEK9 SINGLE PROFILE PASS");
        $finish;
    end
    initial begin
        #(64'd1000000000000);
        $fatal(1,"single-profile watchdog");
    end
endmodule
