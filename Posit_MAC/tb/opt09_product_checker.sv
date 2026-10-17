// Pipeline round-trip comparison, including unsigned P2 and canonical specials.
module opt09_product_checker #(
    parameter int NB = 32,
    parameter int ES = 3,
    parameter int CASES = 100000,
    parameter [39:0] ROUND_MODE = "RNE",
    parameter int F = NB-3-ES,
    parameter int FIN = 2*F+1,
    parameter int SW = $clog2(64'd4*(longint'(NB)-64'd2)*(64'd1<<ES)+64'd4)+1
)(output logic done);
    logic clk = 0;
    always #5 clk = !clk;
    logic reset_n, valid_i, ready_o, sign_i, zero_i, nar_i, sticky_i;
    logic signed [SW-1:0] sf_i;
    logic [FIN-1:0] frac_i;
    logic [4:0] flags_i;
    wire ready_ref, ready_new, valid_ref, valid_new;
    wire [NB-1:0] packed_ref, magnitude_new;
    wire [4:0] flags_ref, flags_new;
    wire sign_new;
    wire s_ref, z_ref, n_ref, s_new, z_new, n_new;
    wire signed [SW-1:0] sf_ref, sf_new;
    wire [F-1:0] frac_ref, frac_new;
    int unsigned rng;
    int completed;
    bit accepted;
    typedef logic [FIN-1:0] fraction_t;
    typedef logic signed [SW-1:0] scale_t;

    posit_pack #(.NB(NB),.ES(ES),.F_IN(FIN),.ROUND_MODE(ROUND_MODE)) u_ref (
        .clk(clk),.reset_n(reset_n),.in_valid(valid_i),.in_ready(ready_ref),
        .sign(sign_i),.is_zero(zero_i),.is_nar(nar_i),.sf(sf_i),.frac(frac_i),
        .sticky(sticky_i),.flags_in(flags_i),.out_valid(valid_ref),.out_ready(ready_o),
        .d(packed_ref),.flags(flags_ref)
    );
    posit_product_pack #(.NB(NB),.ES(ES),.F_IN(FIN),.ROUND_MODE(ROUND_MODE)) u_new (
        .clk(clk),.reset_n(reset_n),.in_valid(valid_i),.in_ready(ready_new),
        .sign(sign_i),.is_zero(zero_i),.is_nar(nar_i),.sf(sf_i),.frac(frac_i),
        .sticky(sticky_i),.flags_in(flags_i),.out_valid(valid_new),.out_ready(ready_o),
        .d(magnitude_new),.flags(flags_new),.sign_o(sign_new)
    );
    posit_parser_comb #(.NB(NB),.ES(ES)) u_parse_ref (
        .p(packed_ref),.s(s_ref),.is_zero(z_ref),.is_nar(n_ref),.sf(sf_ref),.frac(frac_ref)
    );
    posit_magnitude_parse #(.NB(NB),.ES(ES)) u_parse_new (
        .p(magnitude_new),.sign_i(sign_new),.s(s_new),.is_zero(z_new),
        .is_nar(n_new),.sf(sf_new),.frac(frac_new)
    );
    function automatic int unsigned advance(input int unsigned v);
        int unsigned t;
        t = v ^ (v << 13);
        t ^= t >> 17;
        return t ^ (t << 5);
    endfunction

    initial begin
        done=0; reset_n=0; valid_i=0; ready_o=0;
        sign_i=0; zero_i=0; nar_i=0; sticky_i=0;
        sf_i='0; frac_i='0; flags_i='0;
        rng=20261018+100*NB+ES; completed=0; accepted=0;
        repeat (5) @(negedge clk);
        reset_n=1;
        for (int cycle=0; cycle<CASES; cycle++) begin
            @(negedge clk);
            rng=advance(rng);
            ready_o=(rng[1:0]!=0);
            if (cycle%4093==4092) reset_n=0;
            else reset_n=1;
            if (!valid_i || accepted || !reset_n) begin
                valid_i=rng[2]; sign_i=rng[3];
                zero_i=(rng[7:4]==0); nar_i=(rng[11:8]==0);
                sticky_i=rng[12]; flags_i=rng[17:13];
                rng=advance(rng); sf_i=scale_t'(rng);
                // Exercise the normal encoder as well as extreme scales.
                if (cycle%4!=0) sf_i=scale_t'(int'(rng%unsigned'(2*(NB-2)*(1<<ES)+1))-(NB-2)*(1<<ES));
                rng=advance(rng); frac_i=fraction_t'(rng);
                rng=advance(rng); frac_i=(frac_i<<32)|fraction_t'(rng);
                if (cycle%8==0) frac_i='0;
                if (cycle%8==1) frac_i='1;
                if (cycle%8==2) frac_i=fraction_t'(1)<<(FIN-1);
            end
            @(posedge clk);
            accepted=valid_i && ready_ref;
            if (valid_ref && ready_o) completed++;
            #2;
            if ({ready_ref,valid_ref} !== {ready_new,valid_new})
                $fatal(1,"OPT09 handshake NB=%0d ES=%0d cycle=%0d",NB,ES,cycle);
            if (valid_ref && {s_ref,z_ref,n_ref,sf_ref,frac_ref,flags_ref} !==
                             {s_new,z_new,n_new,sf_new,frac_new,flags_new})
                $fatal(1,"OPT09 value NB=%0d ES=%0d mode=%s cycle=%0d",NB,ES,ROUND_MODE,cycle);
        end
        @(negedge clk); valid_i=0; ready_o=1;
        repeat (5) @(posedge clk);
        $display("PRODUCT ROUNDTRIP PASS NB=%0d ES=%0d mode=%s cycles=%0d completed=%0d mismatches=0",
                 NB,ES,ROUND_MODE,CASES,completed);
        done=1;
    end
endmodule
