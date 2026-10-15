//-----------------------------------------------------------------------------
// File          : normalize_refactor_checker.sv
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Two candidates versus baseline and independent integer model.
// $Source: $ $Revision: 1.0 $ $Log: Raw magnitudes, flags and signed boundaries. $
//-----------------------------------------------------------------------------
module normalize_refactor_checker #(
    parameter int NB = 32,
    parameter int ES = 3,
    parameter int F = NB - 3 - ES,
    parameter int SF_W = $clog2(64'd4 * (longint'(NB)-64'd2) * (64'd1<<ES) + 64'd4) + 1,
    parameter int RANDOM_CASES = 50000
)(
    output bit done = 1'b0
);
    localparam int Q = F + 3;
    localparam int F_OUT = 2 * F + 1;
    typedef logic [Q+1:0] word_t;
    typedef logic signed [SF_W-1:0] sf_t;
    typedef struct packed {
        logic sign;
        logic is_zero;
        logic is_nar;
        sf_t sf;
        logic [F_OUT-1:0] frac;
        logic sticky;
        logic [4:0] flags_out;
    } payload_t;

    word_t magnitude;
    logic sign_base;
    sf_t sf_base;
    logic alignment_tail;
    logic is_zero_in;
    logic is_nar_in;
    logic [4:0] flags_in;
    payload_t baseline;
    payload_t early_zero;
    payload_t shared_sf;
    payload_t expected;
    logic [31:0] random_state;
    sf_t scales [7:0];
    integer checks = 0;
    integer zero_clean = 0;
    integer zero_prior_inexact = 0;
    integer nar_zero = 0;
    integer carry_cases = 0;
    integer retained_only = 0;
    integer tail_only = 0;
    integer shift_hits [Q:0];

    posit_add_normalize #(.NB(NB), .ES(ES), .F(F), .SF_W(SF_W)) u_baseline (
        .magnitude(magnitude),
        .sign_base(sign_base),
        .sf_base(sf_base),
        .alignment_tail(alignment_tail),
        .is_zero_in(is_zero_in),
        .is_nar_in(is_nar_in),
        .flags_in(flags_in),
        .sign(baseline.sign),
        .is_zero(baseline.is_zero),
        .is_nar(baseline.is_nar),
        .sf(baseline.sf),
        .frac(baseline.frac),
        .sticky(baseline.sticky),
        .flags_out(baseline.flags_out)
    );
    posit_add_normalize_zero #(.NB(NB), .ES(ES), .F(F), .SF_W(SF_W)) u_zero (
        .magnitude(magnitude),
        .sign_base(sign_base),
        .sf_base(sf_base),
        .alignment_tail(alignment_tail),
        .is_zero_in(is_zero_in),
        .is_nar_in(is_nar_in),
        .flags_in(flags_in),
        .sign(early_zero.sign),
        .is_zero(early_zero.is_zero),
        .is_nar(early_zero.is_nar),
        .sf(early_zero.sf),
        .frac(early_zero.frac),
        .sticky(early_zero.sticky),
        .flags_out(early_zero.flags_out)
    );
    posit_add_normalize_shared #(.NB(NB), .ES(ES), .F(F), .SF_W(SF_W)) u_shared (
        .magnitude(magnitude),
        .sign_base(sign_base),
        .sf_base(sf_base),
        .alignment_tail(alignment_tail),
        .is_zero_in(is_zero_in),
        .is_nar_in(is_nar_in),
        .flags_in(flags_in),
        .sign(shared_sf.sign),
        .is_zero(shared_sf.is_zero),
        .is_nar(shared_sf.is_nar),
        .sf(shared_sf.sf),
        .frac(shared_sf.frac),
        .sticky(shared_sf.sticky),
        .flags_out(shared_sf.flags_out)
    );

    function automatic logic [31:0] random_word;
        random_state = random_state ^ (random_state << 13);
        random_state = random_state ^ (random_state >> 17);
        random_state = random_state ^ (random_state << 5);
        return random_state;
    endfunction

    task check;
        integer highest;
        integer shift_count;
        longint signed scale_value;
        word_t norm_word;
        begin
            #1;
            // Independent highest-set-bit search and direct shifts; no tree/shifter calls.
            expected = '0;
            expected.is_nar = is_nar_in || flags_in[4];
            expected.is_zero = !expected.is_nar && (is_zero_in || magnitude == '0);
            expected.flags_out = expected.is_nar ? 5'b10000 : {1'b0, flags_in[3:0]};
            expected.sign = expected.is_nar || (!expected.is_zero && sign_base);
            highest = -1;
            shift_count = 0;
            norm_word = '0;
            scale_value = $signed(sf_base);
            if (!expected.is_nar && !expected.is_zero) begin
                for (int b = 0; b < Q+2; b++) begin
                    if (magnitude[b]) highest = b;
                end
                if (highest > Q) begin
                    norm_word = (magnitude >> 1) | word_t'(magnitude[0]);
                    scale_value++;
                    carry_cases++;
                end else begin
                    shift_count = Q - highest;
                    norm_word = magnitude << shift_count;
                    scale_value -= shift_count;
                    shift_hits[shift_count]++;
                end
                expected.sf = sf_t'(scale_value);
                expected.frac = {norm_word[Q-1:0], {(F-2){1'b0}}};
                expected.sticky = alignment_tail || (highest > Q && magnitude[0]);
                expected.flags_out[1] = flags_in[1] || expected.sticky;
                retained_only += norm_word[0] && !expected.sticky;
                tail_only += !norm_word[0] && expected.sticky;
                if (!u_baseline.normalized[Q]) begin
                    $fatal(1, "NORM hidden invariant NB=%0d ES=%0d row=%0d", NB, ES, checks);
                end
            end
            if (early_zero !== baseline || shared_sf !== baseline
                || baseline !== expected) begin
                $display("magnitude=%h scale=%0d flags=%h base=%h zero=%h shared=%h ref=%h",
                    magnitude, sf_base, flags_in, baseline, early_zero, shared_sf, expected);
                $fatal(1, "NORM mismatch NB=%0d ES=%0d SW=%0d row=%0d", NB, ES, SF_W, checks);
            end
            zero_clean += expected.is_zero && !flags_in[1];
            zero_prior_inexact += expected.is_zero && flags_in[1];
            nar_zero += expected.is_nar && (is_zero_in || magnitude == '0);
            checks++;
        end
    endtask

    initial begin
        random_state = 20261015 + 100*NB + ES + 10000*SF_W;
        for (int b=0; b<=Q; b++) shift_hits[b]=0;
        scales[0]='0;
        scales[1]=sf_t'(1);
        scales[2]=sf_t'(-1);
        scales[3]={1'b1, {(SF_W-1){1'b0}}};
        scales[4]={1'b0, {(SF_W-1){1'b1}}};
        scales[5]=sf_t'(-Q);
        scales[6]=sf_t'(Q);
        scales[7]=sf_t'(Q+1);
        // Every leading position, carry and adjacent bit pattern; all flags/context.
        for (int pos=0; pos<Q+2; pos++) begin
            for (int pattern=0; pattern<3; pattern++) begin
                for (int scale=0; scale<8; scale++) begin
                    for (int meta=0; meta<32; meta++) begin
                        for (int meta_case=0; meta_case<16; meta_case++) begin
                            magnitude = word_t'(1) << pos;
                            if (pattern==1) magnitude = magnitude - word_t'(1);
                            if (pattern==2) magnitude = magnitude | word_t'(1);
                            sf_base=scales[scale];
                            flags_in=5'(meta);
                            {sign_base, alignment_tail, is_zero_in, is_nar_in}=4'(meta_case);
                            check();
                        end
                    end
                end
            end
        end
        // Exhaust every raw magnitude and scale for the small F=2 profiles.
        // This is arithmetic-domain exhaustive, not all cross-products of metadata.
        if (F==2 && SF_W<=8) begin
            for (int mag=0; mag<(1<<(Q+2)); mag++) begin
                for (int scale=0; scale<(1<<SF_W); scale++) begin
                    magnitude=word_t'(mag);
                    sf_base=sf_t'(scale);
                    flags_in=5'(scale);
                    {sign_base, alignment_tail, is_zero_in, is_nar_in}=4'(mag);
                    check();
                end
            end
        end
        for (int trial=0; trial<RANDOM_CASES; trial++) begin
            magnitude=word_t'(random_word());
            sf_base=sf_t'({random_word(), random_word()});
            {flags_in, sign_base, alignment_tail, is_zero_in, is_nar_in}=9'(random_word());
            check();
        end
        for (int b=0; b<=Q; b++) begin
            if (!shift_hits[b]) $fatal(1, "NORM missing shift bin %0d", b);
        end
        if (!zero_clean || !zero_prior_inexact || !nar_zero || !carry_cases
            || !retained_only || !tail_only) $fatal(1, "NORM missing semantic coverage");
        $display("NORM PASS NB=%0d ES=%0d SW=%0d checks=%0d mismatch=0 shifts=%0d zero_clean=%0d zero_prior=%0d nar_zero=%0d carry=%0d retained_only=%0d tail_only=%0d",
            NB, ES, SF_W, checks, Q+1, zero_clean, zero_prior_inexact,
            nar_zero, carry_cases, retained_only, tail_only);
        done=1'b1;
    end
endmodule
// End of normalize_refactor_checker.sv
