// Parameter-edge regression: independent field scan plus old/new cycle equality.
`timescale 1ns/1ps
module parser_xor_param_checker #(
    parameter int NB = 4,
    parameter int ES = 0,
    parameter int SF_W = $clog2(64'd4 * (longint'(NB)-2) * (64'd1<<ES)+4)+1
)(
    output bit done = 1'b0
);
    localparam int F = NB - 3 - ES;
    localparam int B = 3 + SF_W + F;
    localparam int SAMPLES = NB <= 10 ? (1 << NB) : 10000;
    bit clk = 0;
    logic reset_n = 0;
    logic in_valid = 0;
    logic out_ready = 0;
    logic [NB-1:0] p = '0;
    wire ready_new, ready_old, valid_new, valid_old;
    wire [B-1:0] comb_value, new_value, old_value;
    logic [31:0] random_state = 20261016 + NB * 100 + ES + SF_W;
    logic [NB-1:0] candidate;
    integer accepted = 0;
    integer retired = 0;
    integer stalled = 0;
    always #5 clk = ~clk;

    posit_parser_comb #(.NB(NB), .ES(ES), .SF_W(SF_W)) u_comb (
        .p(p), .s(comb_value[B-1]), .is_zero(comb_value[B-2]),
        .is_nar(comb_value[B-3]), .sf(comb_value[F+SF_W-1:F]),
        .frac(comb_value[F-1:0])
    );
    posit_parser #(.NB(NB), .ES(ES), .SF_W(SF_W)) u_new (
        .clk(clk), .reset_n(reset_n), .in_valid(in_valid), .in_ready(ready_new),
        .p(p), .out_valid(valid_new), .out_ready(out_ready),
        .s(new_value[B-1]), .is_zero(new_value[B-2]),
        .is_nar(new_value[B-3]), .sf(new_value[F+SF_W-1:F]),
        .frac(new_value[F-1:0])
    );
    posit_parser_before #(.NB(NB), .ES(ES), .SF_W(SF_W)) u_old (
        .clk(clk), .reset_n(reset_n), .in_valid(in_valid), .in_ready(ready_old),
        .p(p), .out_valid(valid_old), .out_ready(out_ready),
        .s(old_value[B-1]), .is_zero(old_value[B-2]),
        .is_nar(old_value[B-3]), .sf(old_value[F+SF_W-1:F]),
        .frac(old_value[F-1:0])
    );

    function automatic logic [B-1:0] reference_fields(input logic [NB-1:0] raw);
        logic sign_bit, zero_bit, nar_bit, r;
        logic [NB-1:0] mag;
        logic [F-1:0] fraction;
        logic signed [SF_W-1:0] scale;
        longint signed k, exponent_value;
        integer cursor, run_length;
        sign_bit = raw[NB-1];
        zero_bit = raw == '0;
        nar_bit = raw == {1'b1, {(NB-1){1'b0}}};
        fraction = '0;
        scale = '0;
        if (!zero_bit && !nar_bit) begin
            mag = sign_bit ? -raw : raw;
            cursor = NB-2;
            r = mag[cursor];
            run_length = 0;
            while (cursor >= 0 && mag[cursor] == r) begin
                run_length++;
                cursor--;
            end
            k = r ? longint'(run_length-1) : -longint'(run_length);
            if (cursor >= 0) cursor--;
            exponent_value = 0;
            for (integer e=0; e<ES; e++) begin
                exponent_value = exponent_value << 1;
                if (cursor >= 0) begin
                    exponent_value = exponent_value | longint'(mag[cursor]);
                    cursor--;
                end
            end
            scale = SF_W'(k * (64'sd1 << ES) + exponent_value);
            for (integer f=F-1; f>=0; f--) begin
                if (cursor >= 0) begin
                    fraction[f] = mag[cursor];
                    cursor--;
                end
            end
        end
        return {sign_bit, zero_bit, nar_bit, scale, fraction};
    endfunction

    initial begin
        // Fixed generator, no simulator-dependent $urandom sequence.
        for (integer cycle=0; cycle<SAMPLES+256; cycle++) begin
            @(negedge clk);
            random_state = random_state ^ (random_state << 13);
            random_state = random_state ^ (random_state >> 17);
            random_state = random_state ^ (random_state << 5);
            reset_n = !(cycle < 4 || (cycle >= 65 && cycle < 68) ||
                        (cycle >= 130 && cycle < 133));
            out_ready = cycle < 60 ? 1'b1 : (cycle % 128 < 32 ? 1'b0 : random_state[0]);
            if (!reset_n || !in_valid || ready_new) begin
                if (cycle < 256) begin
                    case (cycle % 8)
                        0: candidate = '0;
                        1: candidate = {1'b1, {(NB-1){1'b0}}};
                        2: candidate = NB'(1);
                        3: candidate = {1'b0, {(NB-1){1'b1}}};
                        4: candidate = NB'(1) << ((cycle/8) % (NB-1));
                        5: candidate = -(NB'(1) << ((cycle/8) % (NB-1)));
                        6: candidate = '1;
                        default: candidate = NB'(random_state);
                    endcase
                end else begin
                    candidate = NB <= 10 ? NB'(cycle-256) : NB'(random_state);
                end
                p = candidate;
                // Exhaustive small formats always issue; large ones add bubbles.
                in_valid = NB <= 10 || random_state[2];
            end
            #2;
            if (comb_value !== reference_fields(p))
                $fatal(1, "PARAM FIELD FAIL NB=%0d ES=%0d SW=%0d p=%h", NB, ES, SF_W, p);
            if ({ready_new,valid_new,new_value} !== {ready_old,valid_old,old_value})
                $fatal(1, "PARAM CYCLE FAIL NB=%0d ES=%0d SW=%0d cycle=%0d", NB, ES, SF_W, cycle);
            if (in_valid && ready_new) accepted++;
            if (valid_new && out_ready) retired++;
            if (valid_new && !out_ready) stalled++;
        end
        if (accepted == 0 || retired == 0 || stalled == 0)
            $fatal(1, "PARAM COVERAGE FAIL");
        $display("PARAM PASS NB=%0d ES=%0d SW=%0d checks=%0d accepted=%0d retired=%0d stalled=%0d",
                 NB, ES, SF_W, SAMPLES+256, accepted, retired, stalled);
        done = 1;
    end
endmodule
