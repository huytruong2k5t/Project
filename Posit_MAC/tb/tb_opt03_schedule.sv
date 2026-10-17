//-----------------------------------------------------------------------------
// File          : tb_opt03_schedule.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-17
// Description   : Edge schedule, II and reset at every pipeline age.
// $Source: $ $Revision: 1.0 $ $Log: OPT-03 protocol verification. $
//-----------------------------------------------------------------------------
module tb_opt03_schedule;
    parameter int NB = 32;
    parameter int ES = 3;
    localparam int F = NB-3-ES;
    localparam int FW = F < 12 ? F : 12;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst_n = 1'b0;
    logic in_valid = 1'b0;
    logic out_ready = 1'b1;
    logic cfg_mode = 1'b0;
    wire in_ready;
    wire out_valid;
    wire [NB-1:0] d;
    wire [4:0] flags;
    logic [NB-1:0] a;
    logic [NB-1:0] b;
    logic [NB-1:0] c;
    integer cycle_count = 0;
    integer accepted_at, done_at, valid_at, retired_at, q;
    integer captures, age, mode_index, reset_count, dense_checks;
    logic pending = 1'b0;
    logic captured = 1'b0;
    posit_mac_nf #(.NB(NB), .ES(ES), .FRAC_W(FW)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready),
        .a(a), .b(b), .c(c), .acc_mode(1'b0), .acc_clr(1'b0),
        .cfg_mode(cfg_mode), .cfg_n(4'd8), .cfg_ops(2'd0),
        .out_valid(out_valid), .out_ready(out_ready), .d(d), .flags(flags)
    );
    always @(posedge clk) begin
        cycle_count = cycle_count+1;
        if (rst_n && pending) begin
            if (dut.u_wrapper.core_done) begin
                done_at = cycle_count;
                q = dut.u_wrapper.unused_iterations_done;
                if (q < 1) q = 1;
                if (!dut.u_wrapper.product_pack_ready)
                    $fatal(1,"core done without pack credit");
            end
            if (dut.u_wrapper.product_capture) begin
                if (captured || cycle_count != done_at+2)
                    $fatal(1,"product capture edge/duplicate");
                captured = 1'b1;
                captures = captures+1;
            end
        end
    end
    task reset_dut;
        begin
            @(negedge clk);
            rst_n=0;
            in_valid=0;
            pending=0;
            repeat(3) begin
                @(posedge clk); #2;
                if (in_ready !== 0 || out_valid !== 0) $fatal(1,"reset gating");
            end
            @(negedge clk); rst_n=1;
            repeat(8) @(negedge clk);
            if (out_valid !== 0 || in_ready !== 1) $fatal(1,"startup/ghost result");
        end
    endtask
    task launch;
        begin
            @(negedge clk); in_valid=1;
            @(posedge clk);
            if (in_ready !== 1) $fatal(1,"input credit missing");
            accepted_at=cycle_count;
            // Evaluate after the monitoring process, avoiding an active-region race.
            #2; accepted_at=cycle_count;
            pending=1; captured=0; done_at=-1000;
            @(negedge clk); in_valid=0;
        end
    endtask
    task complete_and_check;
        integer timeout_count;
        begin
            timeout_count=0;
            while (out_valid !== 1) begin
                @(negedge clk);
                timeout_count=timeout_count+1;
                if (timeout_count>80) $fatal(1,"deadlock");
            end
            valid_at=cycle_count;
            if (!captured || valid_at-accepted_at != q+12)
                $fatal(1,"first valid schedule");
            if (in_ready !== 0) $fatal(1,"accepted before retire");
            @(posedge clk); #2;
            retired_at=cycle_count;
            if (retired_at-accepted_at != q+13 || in_ready !== 1)
                $fatal(1,"retire/next credit schedule");
            // Next acceptance would occur at this following rising edge.
            if (cycle_count+1-accepted_at != q+14) $fatal(1,"II budget");
            pending=0;
            // Measure a real second handshake at the first eligible edge.
            @(negedge clk); in_valid=1;
            @(posedge clk);
            if (in_ready !== 1) $fatal(1,"dense second request not accepted");
            #2;
            if (cycle_count-accepted_at != q+14) $fatal(1,"measured II");
            dense_checks=dense_checks+1;
            @(negedge clk); in_valid=0;
            reset_dut();
        end
    endtask
    initial begin
        captures=0; reset_count=0; dense_checks=0;
        a={NB{1'b1}}/3; b=a; c='0;
        for (mode_index=0;mode_index<2;mode_index=mode_index+1) begin
            cfg_mode=(mode_index!=0);
            reset_dut(); launch(); complete_and_check();
            // Every age includes core, P1, P2, parser/product, add, final pack,
            // plus a stalled valid output. No old token may escape reset.
            for(age=1;age<=F+18;age=age+1) begin
                reset_dut();
                out_ready=0;
                launch();
                repeat(age) @(negedge clk);
                reset_dut();
                out_ready=1;
                repeat(F+20) begin
                    @(negedge clk);
                    if(out_valid !== 0) $fatal(1,"pre-reset token escaped");
                end
                launch(); complete_and_check();
                reset_count=reset_count+1;
            end
        end
        $display("OPT03 SCHEDULE PASS NB=%0d ES=%0d reset_ages=%0d captures=%0d dense_checks=%0d valid=q+12 handshake=q+13 II=q+14",NB,ES,reset_count,captures,dense_checks);
        $finish;
    end
    initial begin #2000000; $fatal(1,"watchdog"); end
endmodule
