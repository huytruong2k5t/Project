//-----------------------------------------------------------------------------
// File          : tb_posit_pack_equiv.sv
// Description   : Bit-exact equivalence testbench for refactored Posit Packer:
//                 - posit_pack
//                 - posit_product_pack
//                 - posit_pack_prepare
//                 - posit_pack_finish
//                 - dyn_right_shifter_fixed2
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module ref_posit_pack_comb (
    input  logic               sign,
    input  logic               is_zero,
    input  logic               is_nar,
    input  logic signed [10:0] sf,
    input  logic        [52:0] frac,
    input  logic               sticky,
    input  logic        [4:0]  flags_in,
    input  logic               product_mode,
    output logic        [31:0] d,
    output logic        [4:0]  flags,
    output logic               sign_o
);
    localparam int NB = 32;
    localparam int ES = 3;
    localparam int SF_MAX = 240;
    localparam int SHIFT_W = 5;
    localparam int PAYLOAD_W = 59;
    localparam int LOW_W = 26;
    localparam int OFFSETS = 32;
    localparam logic [2:0] NORMAL = 3'd0;
    localparam logic [2:0] ZERO   = 3'd1;
    localparam logic [2:0] NAR    = 3'd2;
    localparam logic [2:0] MAXPOS = 3'd3;
    localparam logic [2:0] MINPOS = 3'd4;

    typedef logic [SHIFT_W-1:0] offset_value_t;
    wire [SHIFT_W-1:0] regime = offset_value_t'($signed(sf) >>> ES);
    wire first_regime_bit = !sf[10];
    wire [SHIFT_W-1:0] offset = regime[SHIFT_W-1:0] ^ {SHIFT_W{sf[10]}};
    wire [PAYLOAD_W-1:0] payload = {first_regime_bit, !first_regime_bit, sf[2:0], frac, 1'b0};

    logic [PAYLOAD_W-1:0] shifted;
    always_comb begin
        shifted = payload >> offset;
        for (int k = 0; k < PAYLOAD_W; k++) begin
            if (k >= (PAYLOAD_W - int'(offset)))
                shifted[k] = first_regime_bit;
        end
    end

    logic [OFFSETS-1:0] sticky_lookup;
    always_comb begin
        for (int j = 0; j < OFFSETS; j++) begin
            logic s_acc;
            s_acc = 1'b0;
            for (int b = 0; b < LOW_W + j; b++) begin
                s_acc |= payload[b];
            end
            sticky_lookup[j] = s_acc;
        end
    end

    logic [30:0] mag_trunc;
    logic guard_bit, round_bit, sticky_bit;
    logic [2:0] special_sel;
    logic [4:0] flags_p1;

    always_comb begin
        mag_trunc   = shifted[PAYLOAD_W-1 -: NB-1];
        guard_bit   = shifted[PAYLOAD_W-NB];
        round_bit   = shifted[PAYLOAD_W-NB-1];
        sticky_bit  = sticky | sticky_lookup[offset];
        sign_o      = sign;
        special_sel = NORMAL;
        flags_p1    = {1'b0, flags_in[3:0]};
        flags_p1[1] = flags_in[1] | guard_bit | round_bit | sticky_bit;

        if (is_nar || flags_in[4]) begin
            special_sel = NAR;
            flags_p1    = 5'b10000;
            mag_trunc   = '0;
            guard_bit   = 1'b0;
            round_bit   = 1'b0;
            sticky_bit  = 1'b0;
        end else if (is_zero) begin
            special_sel = ZERO;
            mag_trunc   = '0;
            guard_bit   = 1'b0;
            round_bit   = 1'b0;
            sticky_bit  = 1'b0;
            flags_p1    = {1'b0, flags_in[3:0]};
        end else if (int'($signed(sf)) >= SF_MAX) begin
            special_sel = MAXPOS;
            mag_trunc   = {NB-1{1'b1}};
            guard_bit   = 1'b0;
            round_bit   = 1'b0;
            sticky_bit  = 1'b0;
            flags_p1    = {1'b0, flags_in[3:0]};
            if (int'($signed(sf)) > SF_MAX || (|frac) || sticky) begin
                flags_p1[3] = 1'b1;
                flags_p1[1] = 1'b1;
            end
        end else if (int'($signed(sf)) < -SF_MAX) begin
            special_sel = MINPOS;
            mag_trunc   = {{NB-2{1'b0}}, 1'b1};
            guard_bit   = 1'b0;
            round_bit   = 1'b0;
            sticky_bit  = 1'b0;
            flags_p1    = {1'b0, flags_in[3:0]};
            flags_p1[2] = 1'b1;
            flags_p1[1] = 1'b1;
        end
    end

    wire eff_sign         = product_mode ? 1'b0 : sign;
    wire round_up         = guard_bit & (mag_trunc[0] | round_bit | sticky_bit);
    wire [31:0] signed_base = {1'b0, mag_trunc} ^ {32{eff_sign}};
    wire signed_increment = eff_sign ^ round_up;
    wire [31:0] rounded_signed = signed_base + {31'd0, signed_increment};
    wire magnitude_zero   = ~(|mag_trunc);
    wire magnitude_max    = &mag_trunc;
    wire [31:0] min_encoded = eff_sign ? 32'hFFFF_FFFF : 32'h0000_0001;
    wire [31:0] max_encoded = eff_sign ? 32'h8000_0001 : 32'h7FFF_FFFF;

    always_comb begin
        flags = flags_p1;
        d     = '0;
        unique case (special_sel)
            ZERO:   d = '0;
            NAR: begin
                d     = 32'h8000_0000;
                flags = 5'b10000;
            end
            MAXPOS: d = max_encoded;
            MINPOS: d = min_encoded;
            NORMAL: begin
                if (magnitude_max)       d = max_encoded;
                else if (magnitude_zero) d = min_encoded;
                else                     d = rounded_signed;
            end
            default: begin
                d     = '0;
                flags = '0;
            end
        endcase
    end
endmodule

module tb_posit_pack_equiv;
    logic               clk = 1'b0;
    logic               reset_n;
    logic               in_valid;
    wire                in_ready_pack, in_ready_prod;
    logic               sign;
    logic               is_zero;
    logic               is_nar;
    logic signed [10:0] sf;
    logic        [52:0] frac;
    logic               sticky;
    logic        [4:0]  flags_in;
    wire                out_valid_pack, out_valid_prod;
    logic               out_ready;
    wire         [31:0] d_pack, d_prod;
    wire         [4:0]  flags_pack, flags_prod;
    wire                sign_o_prod;

    always #2.5 clk = ~clk; // 200 MHz

    posit_pack u_dut_pack (
        .clk       (clk),
        .reset_n   (reset_n),
        .in_valid  (in_valid),
        .in_ready  (in_ready_pack),
        .sign      (sign),
        .is_zero   (is_zero),
        .is_nar    (is_nar),
        .sf        (sf),
        .frac      (frac),
        .sticky    (sticky),
        .flags_in  (flags_in),
        .out_valid (out_valid_pack),
        .out_ready (out_ready),
        .d         (d_pack),
        .flags     (flags_pack)
    );

    posit_product_pack u_dut_prod (
        .clk       (clk),
        .reset_n   (reset_n),
        .in_valid  (in_valid),
        .in_ready  (in_ready_prod),
        .sign      (sign),
        .is_zero   (is_zero),
        .is_nar    (is_nar),
        .sf        (sf),
        .frac      (frac),
        .sticky    (sticky),
        .flags_in  (flags_in),
        .out_valid (out_valid_prod),
        .out_ready (out_ready),
        .d         (d_prod),
        .flags     (flags_prod),
        .sign_o    (sign_o_prod)
    );

    wire [31:0] ref_d_pack, ref_d_prod;
    wire [4:0]  ref_flags_pack, ref_flags_prod;
    wire        ref_sign_prod;

    ref_posit_pack_comb u_ref_pack (
        .sign         (sign),
        .is_zero      (is_zero),
        .is_nar       (is_nar),
        .sf           (sf),
        .frac         (frac),
        .sticky       (sticky),
        .flags_in     (flags_in),
        .product_mode (1'b0),
        .d            (ref_d_pack),
        .flags        (ref_flags_pack),
        .sign_o       ()
    );

    ref_posit_pack_comb u_ref_prod (
        .sign         (sign),
        .is_zero      (is_zero),
        .is_nar       (is_nar),
        .sf           (sf),
        .frac         (frac),
        .sticky       (sticky),
        .flags_in     (flags_in),
        .product_mode (1'b1),
        .d            (ref_d_prod),
        .flags        (ref_flags_prod),
        .sign_o       (ref_sign_prod)
    );

    typedef struct packed {
        logic [31:0] d_pack;
        logic [4:0]  flags_pack;
        logic [31:0] d_prod;
        logic [4:0]  flags_prod;
        logic        sign_prod;
    } exp_item_t;

    exp_item_t exp_q[$];
    int completed_cnt = 0;
    int stall_cnt     = 0;
    int err_cnt       = 0;
    bit held = 0;
    logic [105:0] held_bundle;

    always @(posedge clk) begin
        if (!reset_n) held = 0;
        else begin
            if (in_ready_pack !== in_ready_prod || out_valid_pack !== out_valid_prod)
                $fatal(1,"packer handshake divergence");
            if (held && (!out_valid_pack || {d_pack,flags_pack,d_prod,flags_prod,sign_o_prod} !== held_bundle))
                $fatal(1,"packer stall payload/valid changed");
            held = out_valid_pack && !out_ready;
            held_bundle = {d_pack,flags_pack,d_prod,flags_prod,sign_o_prod};
        end
        if (reset_n && in_valid && in_ready_pack) begin
            exp_item_t item;
            item.d_pack     = ref_d_pack;
            item.flags_pack = ref_flags_pack;
            item.d_prod     = ref_d_prod;
            item.flags_prod = ref_flags_prod;
            item.sign_prod  = ref_sign_prod;
            exp_q.push_back(item);
        end

        if (reset_n && out_valid_pack && !out_ready) begin
            stall_cnt++;
        end

        if (reset_n && out_valid_pack && out_ready) begin
            exp_item_t exp;
            if (exp_q.size() == 0) begin
                $display("ERROR: Unexpected output valid!");
                err_cnt++;
            end else begin
                exp = exp_q.pop_front();
                completed_cnt++;
                if (d_pack !== exp.d_pack || flags_pack !== exp.flags_pack) begin
                    $display("ERROR [posit_pack] tx=%0d: got d=%h flags=%b, exp d=%h flags=%b",
                             completed_cnt, d_pack, flags_pack, exp.d_pack, exp.flags_pack);
                    err_cnt++;
                end
                if (d_prod !== exp.d_prod || flags_prod !== exp.flags_prod || sign_o_prod !== exp.sign_prod) begin
                    $display("ERROR [posit_product_pack] tx=%0d: got d=%h flags=%b sign=%b, exp d=%h flags=%b sign=%b",
                             completed_cnt, d_prod, flags_prod, sign_o_prod, exp.d_prod, exp.flags_prod, exp.sign_prod);
                    err_cnt++;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (reset_n) begin
            out_ready <= ($urandom_range(0, 3) != 0); // 75% ready, 25% backpressure
        end else begin
            out_ready <= 1'b1;
        end
    end

    initial begin
        reset_n   = 1'b0;
        in_valid  = 1'b0;
        sign      = 1'b0;
        is_zero   = 1'b0;
        is_nar    = 1'b0;
        sf        = '0;
        frac      = '0;
        sticky    = 1'b0;
        flags_in  = '0;

        repeat (6) @(posedge clk);
        reset_n = 1'b1;
        repeat (4) @(posedge clk);

        // 1. Directed sweep across all sf values (-260 .. +260) and rounding corners
        for (int s = -260; s <= 260; s++) begin
            for (int c = 0; c < 8; c++) begin
                @(posedge clk);
                in_valid <= 1'b1;
                sign     <= c[0];
                is_zero  <= 1'b0;
                is_nar   <= 1'b0;
                sf       <= s[10:0];
                sticky   <= c[1];
                flags_in <= {1'b0, $urandom_range(0, 15)};
                case (c[2:1])
                    2'd0: frac <= 53'h0;
                    2'd1: frac <= 53'h1F_FFFF_FFFF_FFFF;
                    2'd2: frac <= 53'h10_0000_0000_0000;
                    2'd3: frac <= {$urandom, $urandom} & 53'h1F_FFFF_FFFF_FFFF;
                endcase
                while (!(in_valid && in_ready_pack)) @(posedge clk);
            end
        end

        // 2. Random stress with NaR, Zero, MAXPOS, MINPOS, and random backpressure
        for (int i = 0; i < 10000; i++) begin
            @(posedge clk);
            if (!in_valid || in_ready_pack) begin
            in_valid <= ($urandom_range(0, 4) != 0);
            sign     <= $urandom_range(0, 1);
            is_zero  <= ($urandom_range(0, 19) == 0);
            is_nar   <= ($urandom_range(0, 19) == 0);
            sf       <= $signed($urandom_range(0, 2047)) - 11'sd1024;
            frac     <= {$urandom, $urandom} & 53'h1F_FFFF_FFFF_FFFF;
            sticky   <= $urandom_range(0, 1);
            flags_in <= $urandom_range(0, 31);
            end
        end

        @(posedge clk);
        in_valid <= 1'b0;
        while (exp_q.size() > 0) @(posedge clk);
        repeat (20) @(posedge clk);

        $display("=============================================================");
        $display("TB_POSIT_PACK_EQUIV DONE: completed=%0d, stalls=%0d, errors=%0d",
                 completed_cnt, stall_cnt, err_cnt);
        $display("=============================================================");
        if (err_cnt == 0 && completed_cnt > 5000 && exp_q.size() == 0)
            $display("PACKER_REFACTOR_PASS completed=%0d stalls=%0d errors=0",completed_cnt,stall_cnt);
        else
            $fatal(1,"packer acceptance failed");
        $finish;
    end
    initial begin #10000000; $fatal(1,"packer watchdog"); end
endmodule

