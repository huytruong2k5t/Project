// Compare every P1 field; include non-power-of-two NB and narrow/max FIN.
module opt10a_prepare_checker #(
    parameter int NB=32,
    parameter int ES=3,
    parameter int FIN=2*(NB-3-ES)+1,
    parameter int SW=$clog2(64'd4*(longint'(NB)-64'd2)*(64'd1<<ES)+64'd4)+1
)(output logic done);
    logic sign_i,zero_i,nar_i,sticky_i;
    logic signed [SW-1:0] sf_i;
    logic [FIN-1:0] frac_i;
    logic [4:0] flags_i;
    typedef struct packed {
        logic [NB-2:0] mag;
        logic guard_bit;
        logic round_bit;
        logic sticky_bit;
        logic sign_o;
        logic [2:0] special;
        logic [4:0] flags;
    } result_t;
    result_t ref_o,new_o;
    typedef logic [FIN-1:0] fraction_t;
    typedef logic signed [SW-1:0] scale_t;
    int unsigned rng;
    int checks;
    posit_pack_prepare_baseline #(.NB(NB),.ES(ES),.F_IN(FIN)) u_ref (
        .sign(sign_i),.is_zero(zero_i),.is_nar(nar_i),.sf(sf_i),.frac(frac_i),
        .sticky(sticky_i),.flags_in(flags_i),.mag_trunc(ref_o.mag),
        .guard_bit(ref_o.guard_bit),.round_bit(ref_o.round_bit),.sticky_bit(ref_o.sticky_bit),
        .sign_o(ref_o.sign_o),.special_sel(ref_o.special),.flags_o(ref_o.flags)
    );
    posit_pack_prepare #(.NB(NB),.ES(ES),.F_IN(FIN)) u_new (
        .sign(sign_i),.is_zero(zero_i),.is_nar(nar_i),.sf(sf_i),.frac(frac_i),
        .sticky(sticky_i),.flags_in(flags_i),.mag_trunc(new_o.mag),
        .guard_bit(new_o.guard_bit),.round_bit(new_o.round_bit),.sticky_bit(new_o.sticky_bit),
        .sign_o(new_o.sign_o),.special_sel(new_o.special),.flags_o(new_o.flags)
    );
    function automatic int unsigned advance(input int unsigned v);
        int unsigned t;
        t=v^(v<<13); t^=t>>17; return t^(t<<5);
    endfunction
    task automatic compare;
        #1;
        if (ref_o !== new_o) $fatal(1,"P1 mismatch NB=%0d ES=%0d FIN=%0d sf=%0d frac=%h",NB,ES,FIN,sf_i,frac_i);
        checks++;
    endtask
    initial begin
        done=0;checks=0;rng=20261018+100*NB+ES+FIN;
        sign_i=0;zero_i=0;nar_i=0;sticky_i=0;sf_i='0;frac_i='0;flags_i='0;
        // Sweep all SF codes and every source one-hot bit when SF is small.
        if (SW<=13) begin
            for (int s=0;s<(1<<SW);s++) begin
                sf_i=scale_t'(s);
                frac_i='0; compare();
                frac_i='1; compare();
                for (int bit_no=0;bit_no<FIN;bit_no++) begin
                    frac_i=fraction_t'(1)<<bit_no; compare();
                end
            end
        end
        for (int i=0;i<100000;i++) begin
            rng=advance(rng);
            sign_i=rng[0]; zero_i=(rng[4:1]==0); nar_i=(rng[8:5]==0);
            sticky_i=rng[9]; flags_i=rng[14:10];
            if (i%4==0) begin zero_i=0;nar_i=0;flags_i=0; end
            rng=advance(rng);sf_i=scale_t'(rng);
            rng=advance(rng);frac_i=fraction_t'(rng);
            rng=advance(rng);frac_i=(frac_i<<32)|fraction_t'(rng);
            compare();
        end
        $display("PREPARE PASS NB=%0d ES=%0d FIN=%0d checks=%0d mismatches=0",NB,ES,FIN,checks);
        done=1;
    end
endmodule
