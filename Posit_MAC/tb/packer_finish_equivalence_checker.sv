//-----------------------------------------------------------------------------
// File          : packer_finish_equivalence_checker.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-07
// Description   : P2 before/after equivalence on binary input bundles.
//-----------------------------------------------------------------------------
// $Revision: 1.0 $
// $Log: P2 single-adder equivalence regression. $

module packer_finish_equivalence_checker #(
    parameter int NB = 8
)(
    output logic done
);
    logic [NB-2:0] mag_trunc;
    logic guard_bit, round_bit, sticky_bit, sign;
    logic [2:0] special_sel;
    logic [4:0] flags_in;
    wire [NB-1:0] d_rne, ref_rne, d_trunc, ref_trunc;
    wire [4:0] f_rne, rf_rne, f_trunc, rf_trunc;
    int unsigned rng;
    int checks;

    posit_pack_finish #(.NB(NB), .ROUND_MODE("RNE")) u_rne (
        .mag_trunc(mag_trunc), .guard_bit(guard_bit),
        .round_bit(round_bit), .sticky_bit(sticky_bit), .sign(sign),
        .special_sel(special_sel), .flags_in(flags_in),
        .d(d_rne), .flags(f_rne)
    );
    posit_pack_finish_reference #(.NB(NB), .ROUND_MODE("RNE")) u_ref_rne (
        .mag_trunc(mag_trunc), .guard_bit(guard_bit),
        .round_bit(round_bit), .sticky_bit(sticky_bit), .sign(sign),
        .special_sel(special_sel), .flags_in(flags_in),
        .d(ref_rne), .flags(rf_rne)
    );
    posit_pack_finish #(.NB(NB), .ROUND_MODE("TRUNC")) u_trunc (
        .mag_trunc(mag_trunc), .guard_bit(guard_bit),
        .round_bit(round_bit), .sticky_bit(sticky_bit), .sign(sign),
        .special_sel(special_sel), .flags_in(flags_in),
        .d(d_trunc), .flags(f_trunc)
    );
    posit_pack_finish_reference #(.NB(NB), .ROUND_MODE("TRUNC")) u_ref_trunc (
        .mag_trunc(mag_trunc), .guard_bit(guard_bit),
        .round_bit(round_bit), .sticky_bit(sticky_bit), .sign(sign),
        .special_sel(special_sel), .flags_in(flags_in),
        .d(ref_trunc), .flags(rf_trunc)
    );

    initial begin
        done = 0;
        checks = 0;
        rng = 20261007 + NB;
        for (int i = 0; i < ((NB == 8) ? 524288 : 100000); i++) begin
            if (NB == 8) begin
                {mag_trunc, guard_bit, round_bit, sticky_bit,
                 sign, special_sel, flags_in} = i;
            end else begin
                rng = rng ^ (rng << 13);
                rng = rng ^ (rng >> 17);
                rng = rng ^ (rng << 5);
                mag_trunc = rng;
                rng = rng ^ (rng << 13);
                rng = rng ^ (rng >> 17);
                rng = rng ^ (rng << 5);
                {guard_bit, round_bit, sticky_bit,
                 sign, special_sel, flags_in} = rng[11:0];
            end
            #1;
            if ({d_rne, f_rne, d_trunc, f_trunc} !==
                {ref_rne, rf_rne, ref_trunc, rf_trunc}) begin
                $fatal(1, "P2 mismatch NB=%0d i=%0d", NB, i);
            end
            checks = checks + 2;
        end
        $display("P2 EQUIVALENCE PASS NB=%0d checks=%0d", NB, checks);
        done = 1;
    end
endmodule
//-----------------------------------------------------------------------------
// End of packer_finish_equivalence_checker.sv
//-----------------------------------------------------------------------------
