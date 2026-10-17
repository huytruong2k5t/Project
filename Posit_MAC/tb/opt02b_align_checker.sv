//-----------------------------------------------------------------------------
// File          : opt02b_align_checker.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Baseline/candidate and independent alignment arithmetic check.
// $Source: $ $Revision: 1.0 $ $Log: Signed extremes and canonical specials. $
//-----------------------------------------------------------------------------
module opt02b_align_checker #(
    parameter int NB = 32,
    parameter int ES = 3,
    parameter int F = NB - 3 - ES,
    parameter int SF_W = $clog2(64'd4 * (longint'(NB)-64'd2) * (64'd1<<ES) + 64'd4) + 1,
    parameter int RANDOM_CASES = 50000
)(
    output bit done = 1'b0
);
    localparam int ADD_W = F + 5;
    typedef logic [F-1:0] frac_t;
    typedef logic [ADD_W-1:0] word_t;
    typedef logic signed [SF_W-1:0] sf_t;
    typedef struct packed {
        word_t x;
        word_t y;
        logic subtract;
        logic sign_base;
        sf_t sf_base;
        logic alignment_tail;
        logic is_zero;
        logic is_nar;
        logic [4:0] flags;
    } payload_t;
    logic a_sign, a_is_zero, a_is_nar;
    logic b_sign, b_is_zero, b_is_nar;
    sf_t a_sf, b_sf;
    frac_t a_frac, b_frac;
    logic [4:0] flags_in;
    payload_t baseline, candidate, expected;
    logic [31:0] random_state;
    integer checks = 0;
    integer nar_zero_cases = 0;
    integer clamp_cases = 0;
    integer threshold_cases = 0;
    integer tie_cases = 0;
    sf_t scales [8:0];
    frac_t patterns [5:0];

    posit_add_align_before #(.NB(NB), .ES(ES), .F(F), .SF_W(SF_W)) u_baseline (
        .a_sign(a_sign),
        .a_is_zero(a_is_zero),
        .a_is_nar(a_is_nar),
        .a_sf(a_sf),
        .a_frac(a_frac),
        .b_sign(b_sign),
        .b_is_zero(b_is_zero),
        .b_is_nar(b_is_nar),
        .b_sf(b_sf),
        .b_frac(b_frac),
        .flags_in(flags_in),
        .x(baseline.x),
        .y(baseline.y),
        .subtract(baseline.subtract),
        .sign_base(baseline.sign_base),
        .sf_base(baseline.sf_base),
        .alignment_tail(baseline.alignment_tail),
        .is_zero(baseline.is_zero),
        .is_nar(baseline.is_nar),
        .flags_o(baseline.flags)
    );
    posit_add_align #(.NB(NB), .ES(ES), .F(F), .SF_W(SF_W)) u_candidate (
        .a_sign(a_sign),
        .a_is_zero(a_is_zero),
        .a_is_nar(a_is_nar),
        .a_sf(a_sf),
        .a_frac(a_frac),
        .b_sign(b_sign),
        .b_is_zero(b_is_zero),
        .b_is_nar(b_is_nar),
        .b_sf(b_sf),
        .b_frac(b_frac),
        .flags_in(flags_in),
        .x(candidate.x),
        .y(candidate.y),
        .subtract(candidate.subtract),
        .sign_base(candidate.sign_base),
        .sf_base(candidate.sf_base),
        .alignment_tail(candidate.alignment_tail),
        .is_zero(candidate.is_zero),
        .is_nar(candidate.is_nar),
        .flags_o(candidate.flags)
    );

    function automatic logic [31:0] random_word;
        random_state = random_state ^ (random_state << 13);
        random_state = random_state ^ (random_state >> 17);
        random_state = random_state ^ (random_state << 5);
        return random_state;
    endfunction

    task check;
        bit select_a, both_nonzero, lost;
        longint signed big_sf, small_sf, difference;
        word_t big_word, small_word;
        begin
            #1;
            if (candidate !== baseline) begin
                $fatal(1, "ALIGN RTL mismatch NB=%0d ES=%0d SW=%0d row=%0d a_sf=%0d b_sf=%0d flags=%h",
                    NB, ES, SF_W, checks, a_sf, b_sf, flags_in);
            end
            // Independent integer comparison and direct shift; no delta MUX/mask/shifter calls.
            select_a = !a_is_zero && (b_is_zero || a_sf > b_sf
                     || (a_sf == b_sf && a_frac >= b_frac));
            both_nonzero = !a_is_zero && !b_is_zero;
            big_sf = select_a ? $signed(a_sf) : $signed(b_sf);
            small_sf = select_a ? $signed(b_sf) : $signed(a_sf);
            big_word = select_a ? {1'b0,1'b1,a_frac,3'b000}
                               : {1'b0,1'b1,b_frac,3'b000};
            small_word = select_a ? {1'b0,1'b1,b_frac,3'b000}
                                 : {1'b0,1'b1,a_frac,3'b000};
            difference = both_nonzero ? big_sf - small_sf : 0;
            expected = '0;
            expected.is_nar = a_is_nar || b_is_nar || flags_in[4];
            expected.is_zero = !expected.is_nar && a_is_zero && b_is_zero;
            expected.flags = expected.is_nar ? 5'b10000 : {1'b0,flags_in[3:0]};
            expected.sign_base = expected.is_nar ? 1'b1 : expected.is_zero ? 1'b0
                              : select_a ? a_sign : b_sign;
            if (!expected.is_nar && !expected.is_zero) begin
                expected.x = big_word;
                expected.sf_base = sf_t'(big_sf);
                expected.subtract = both_nonzero && (a_sign != b_sign);
                if (both_nonzero) begin
                    if (difference > F+2) begin
                        expected.y = word_t'(1);
                        expected.alignment_tail = 1'b1;
                    end else begin
                        lost = 1'b0;
                        for (int bit_index = 0; bit_index < ADD_W; bit_index++) begin
                            if (bit_index < difference) lost |= small_word[bit_index];
                        end
                        expected.y = (small_word >> difference) | word_t'(lost);
                        expected.alignment_tail = lost;
                    end
                end
            end
            if (candidate !== expected) $fatal(1, "ALIGN oracle mismatch NB=%0d ES=%0d SW=%0d row=%0d",NB,ES,SF_W,checks);
            nar_zero_cases += (a_is_zero && b_is_zero && expected.is_nar);
            clamp_cases += (!expected.is_nar && both_nonzero && difference > F+2);
            threshold_cases += (!expected.is_nar && both_nonzero && difference == F+2);
            tie_cases += (!expected.is_nar && both_nonzero && a_sf == b_sf && a_frac == b_frac);
            checks++;
        end
    endtask

    initial begin
        random_state = 20261017 + 100*NB + ES + 10000*SF_W;
        scales[0]='0; scales[1]=sf_t'(1); scales[2]=sf_t'(-1);
        scales[3]={1'b1,{(SF_W-1){1'b0}}};
        scales[4]={1'b0,{(SF_W-1){1'b1}}};
        scales[5]=sf_t'(F+2); scales[6]=sf_t'(F+3);
        scales[7]=sf_t'(-F-2); scales[8]=sf_t'(-F-3);
        patterns[0]='0; patterns[1]='1; patterns[2]=frac_t'(1);
        patterns[3]=frac_t'(64'h1 << (F-1));
        patterns[4]=frac_t'(32'haaaaaaaa); patterns[5]=frac_t'(32'h55555555);
        a_is_zero=0; b_is_zero=0; a_is_nar=0; b_is_nar=0;
        for (int ia=0;ia<9;ia++) for (int ib=0;ib<9;ib++) begin
            for (int fa=0;fa<6;fa++) for (int fb=0;fb<6;fb++) begin
                for (int signs=0;signs<4;signs++) begin
                    a_sf=scales[ia]; b_sf=scales[ib]; a_frac=patterns[fa]; b_frac=patterns[fb];
                    a_sign=signs[0]; b_sign=signs[1]; flags_in=checks[4:0]; check();
                end
            end
        end
        for (int specials=0;specials<16;specials++) begin
            a_is_zero=specials[0]; a_is_nar=specials[1];
            b_is_zero=specials[2]; b_is_nar=specials[3];
            for (int flags=0;flags<32;flags++) for (int signs=0;signs<4;signs++) begin
                flags_in=flags[4:0]; a_sign=signs[0]; b_sign=signs[1];
                for (int dirty=0;dirty<6;dirty++) begin
                    a_frac=patterns[dirty]; b_frac=patterns[5-dirty];
                    a_sf=scales[3+dirty]; b_sf=scales[8-dirty]; check();
                end
            end
        end
        if (F<=5) begin
            a_is_zero=0; b_is_zero=0; a_is_nar=0; b_is_nar=0;
            for (int fa=0;fa<(1<<F);fa++) for (int fb=0;fb<(1<<F);fb++) begin
                for (int d=0;d<=F+3;d++) begin
                    a_sf=sf_t'(d); b_sf='0; a_frac=frac_t'(fa); b_frac=frac_t'(fb);
                    flags_in='0; a_sign=fa[0]; b_sign=fb[0]; check();
                end
            end
        end
        // Each low bit at every shift, both scale directions and all signs.
        a_is_zero=0; b_is_zero=0; a_is_nar=0; b_is_nar=0; flags_in=0;
        for (int d=0;d<=F+3;d++) for (int bitpos=0;bitpos<F;bitpos++) begin
            for (int signs=0;signs<4;signs++) begin
                a_sign=signs[0]; b_sign=signs[1];
                a_frac=frac_t'(1) << bitpos; b_frac=a_frac;
                a_sf=sf_t'(d); b_sf=0; check();
                a_sf=0; b_sf=sf_t'(d); check();
                a_frac='0; b_frac=frac_t'(1) << bitpos; check();
                a_sf=sf_t'(d); b_sf=0; check();
            end
        end
        for (int trial=0;trial<RANDOM_CASES;trial++) begin
            a_frac=frac_t'(random_word()); b_frac=frac_t'(random_word());
            a_sf=sf_t'({random_word(),random_word()});
            b_sf=sf_t'({random_word(),random_word()});
            {flags_in,a_sign,b_sign,a_is_zero,b_is_zero,a_is_nar,b_is_nar}=11'(random_word());
            check();
        end
        if (!nar_zero_cases || !clamp_cases || !threshold_cases || !tie_cases)
            $fatal(1,"ALIGN missing directed coverage");
        $display("ALIGN PASS NB=%0d ES=%0d SW=%0d checks=%0d mismatch=0 nar_zero=%0d clamp=%0d threshold=%0d tie=%0d",
            NB,ES,SF_W,checks,nar_zero_cases,clamp_cases,threshold_cases,tie_cases);
        done=1'b1;
    end
endmodule
// End of opt02b_align_checker.sv
