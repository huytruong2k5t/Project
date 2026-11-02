//-----------------------------------------------------------------------------
// File          : tb_mul_iter_core.sv
// Project       : Posit MAC IP
// Description   : Source-bound shared FULL_TERM core checks, including every
//                 fraction12/n pair, commit checkpoints, reset and live-port changes.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
module tb_mul_iter_core;
    logic clk = 0;
    always #5 clk = ~clk;
    logic reset_n = 0;
    logic launch_valid = 0;
    wire launch_ready;
    logic release_result = 0;
    logic [11:0] x_frac = 0;
    logic [12:0] y_mant = 4096;
    logic [3:0] cfg_n = 12;
    logic sign_i = 0;
    logic signed [10:0] sf_i = 0;
    logic input_cut_i = 0;
    wire run_ready;
    wire core_done;
    wire [25:0] acc;
    wire [3:0] iterations_done;
    wire approx_cut;
    wire sign_o;
    wire signed [10:0] sf_o;
    wire input_cut_o;
    wire state_error;

    mul_iter_core dut (
        .clk(clk),
        .reset_n(reset_n),
        .launch_valid(launch_valid),
        .launch_ready(launch_ready),
        .release_result(release_result),
        .x_frac(x_frac),
        .y_mant(y_mant),
        .cfg_n(cfg_n),
        .sign_i(sign_i),
        .sf_i(sf_i),
        .input_cut_i(input_cut_i),
        .run_ready(run_ready),
        .core_done(core_done),
        .acc(acc),
        .iterations_done(iterations_done),
        .approx_cut(approx_cut),
        .sign_o(sign_o),
        .sf_o(sf_o),
        .input_cut_o(input_cut_o),
        .state_error(state_error)
    );

    integer cases = 0;
    integer checkpoints = 0;
    integer timeout;
    integer pop;
    integer wanted_t;
    integer check_fx;
    integer check_y;
    integer saved_iteration;
    logic checking = 0;
    logic [25:0] held_acc;

    function automatic integer selected_product(input integer fx, input integer yy, input integer nn);
        integer selected;
        integer count;
        begin
            selected = 0;
            count = 0;
            for (integer bit_index = 11; bit_index >= 0; bit_index--) begin
                if (((fx >> bit_index) & 1) && count < nn) begin
                    selected = selected | (1 << bit_index);
                    count++;
                end
            end
            selected_product = (4096 + selected) * yy;
        end
    endfunction

    always @(posedge clk) begin
        if (run_ready && checking && dut.t2_valid) begin
            saved_iteration = dut.t2_iteration;
            #2;
            if (acc !== selected_product(check_fx, check_y, saved_iteration))
                $fatal(1, "core checkpoint fx=%h y=%h iteration=%0d", check_fx, check_y, saved_iteration);
            if (iterations_done !== saved_iteration)
                $fatal(1, "core iteration metadata");
            checkpoints++;
        end
    end

    task automatic transaction(input integer fx, input integer yy, input integer nn);
        logic expected_sign;
        logic expected_loss;
        logic signed [10:0] expected_scale;
        begin
            @(negedge clk);
            x_frac = fx;
            y_mant = yy;
            cfg_n = nn;
            expected_sign = (yy != 0) && ((fx & 1) != 0);
            expected_loss = (yy != 0) && ((fx & 2) != 0);
            expected_scale = (yy == 0) ? 0 : ((fx % 961) - 480);
            sign_i = expected_sign;
            sf_i = expected_scale;
            input_cut_i = expected_loss;
            if (!launch_ready) $fatal(1, "core not ready between transactions");
            launch_valid = 1;
            check_fx = fx;
            check_y = yy;
            checking = 1;
            @(negedge clk);
            launch_valid = 0;
            // These must not affect the stored context or running arithmetic.
            x_frac = ~fx;
            y_mant = 8191;
            cfg_n = 15;
            sign_i = ~expected_sign;
            sf_i = 511;
            input_cut_i = ~expected_loss;
            timeout = 0;
            while (!core_done) begin
                @(negedge clk);
                timeout++;
                if (state_error || timeout > 24) $fatal(1, "core error/timeout");
            end
            pop = $countones(fx & 4095);
            wanted_t = (pop < nn) ? pop : nn;
            if (acc !== selected_product(fx, yy, nn)
                || iterations_done !== wanted_t
                || approx_cut !== (pop > nn)
                || sign_o !== expected_sign
                || sf_o !== expected_scale
                || input_cut_o !== expected_loss)
                $fatal(1, "core final fx=%h y=%h n=%0d", fx, yy, nn);
            held_acc = acc;
            repeat (3) begin
                @(negedge clk);
                if (launch_ready || core_done || acc !== held_acc || state_error)
                    $fatal(1, "core result retention/repeated done");
            end
            checking = 0;
            release_result = 1;
            @(negedge clk);
            release_result = 0;
            cfg_n = 12;
            cases++;
        end
    endtask

    initial begin
        repeat (4) @(negedge clk);
        reset_n = 1;
        while (!run_ready) @(negedge clk);
        for (integer bad_n = 13; bad_n < 16; bad_n++) begin
            cfg_n = bad_n;
            launch_valid = 1;
            repeat (3) begin
                @(negedge clk);
                if (launch_ready || core_done) $fatal(1, "invalid n accepted by core");
            end
        end
        launch_valid = 0;
        cfg_n = 12;
        transaction(0, 0, 12);
        for (integer fx = 0; fx < 4096; fx++) begin
            for (integer n = 0; n <= 12; n++) begin
                transaction(fx, ((fx+n)&1) ? 8191 : 4096, n);
            end
        end
        if (cases != 53249 || checkpoints == 0) $fatal(1, "incomplete core coverage");
        $display("SHARED_CORE_PASS cases=%0d checkpoints=%0d mismatches=0", cases, checkpoints);
        $finish;
    end
    initial begin
        #20000000;
        $fatal(1, "shared core watchdog");
    end
endmodule
