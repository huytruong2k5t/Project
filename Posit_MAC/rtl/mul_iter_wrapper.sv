//-----------------------------------------------------------------------------
// File          : mul_iter_wrapper.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : Atomic parser pair, one reserved result, norm and packer.
//                 Synchronous top reset bridge and leaf startup barrier.
// $Source: $ $Revision: 1.0 $ $Log: Week9 standalone multiplier integration. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module mul_iter_wrapper #(
    parameter int NB=32,
    parameter int ES=2,
    parameter int FRAC_W=12,
    parameter int N_MAX=8,
    parameter int ROUND_SCHEME=0,
    parameter ROUND_MODE="RNE",
    parameter bit EXACT_EN=1'b1,
    parameter bit OPS_EN=1'b1,
    parameter int F=NB-3-ES,
    parameter int SF_W=$clog2(64'd4*(NB-2)*(64'd1<<ES)+64'd4)+1,
    parameter int N_W=(N_MAX>1)?$clog2(N_MAX+1):1,
    parameter int I_W=$clog2(((F>N_MAX)?F:N_MAX)+1),
    parameter int ACC_W=EXACT_EN?((2*F+2>FRAC_W+4)?2*F+2:FRAC_W+4):FRAC_W+4,
    parameter int FIN=2*F+1
)(
    input logic clk,
    input logic rst_n,
    input logic in_valid,
    output wire in_ready,
    input logic [NB-1:0] a,
    input logic [NB-1:0] b,
    input logic cfg_mode,
    input logic [N_W-1:0] cfg_n,
    input logic [1:0] cfg_ops,
    output wire out_valid,
    input logic out_ready,
    output wire [NB-1:0] d,
    output wire [4:0] flags
);
    logic reset_bridge_q;
    (* ASYNC_REG="TRUE" *) logic meta_sync1,meta_sync2;
    logic busy_q,mode_q;
    logic [N_W-1:0] n_q;
    logic [1:0] ops_q;
    wire reset_n;
    wire ready_a,ready_b,valid_a,valid_b,pair_accept,pair_retire;
    wire s_a,s_b,z_a,z_b,nar_a,nar_b;
    wire signed [SF_W-1:0] sf_a,sf_b;
    wire [F-1:0] frac_a,frac_b;
    wire [F-1:0] ops_x,x;
    wire [F:0] ops_y,y;
    wire [$clog2(F+1)-1:0] active_width;
    wire ops_sign,ops_cut,ops_swapped,ops_error;
    wire signed [SF_W-1:0] ops_sf;
    wire cfg_valid,core_ready,core_run,core_done,core_error,retire;
    wire bypass;
    wire [ACC_W-1:0] acc;
    wire sticky_acc,numerical_tail,approx_cut,core_sign,core_cut,core_mode;
    wire [I_W-1:0] iterations_done;
    wire signed [SF_W-1:0] core_sf,sf_norm;
    wire [FIN-1:0] frac_norm;
    wire sticky_norm;
    logic zero_q,nar_q;
    logic norm_valid_q,norm_sign_q,norm_zero_q,norm_nar_q,norm_sticky_q;
    logic signed [SF_W-1:0] norm_sf_q;
    logic [FIN-1:0] norm_frac_q;
    logic [4:0] norm_flags_q;
    wire pack_ready,pack_out_valid;
    assign reset_n=reset_bridge_q;
    assign cfg_valid=(cfg_ops <= 1) && (OPS_EN || cfg_ops==0) &&
                     (cfg_mode || EXACT_EN) && (!cfg_mode || cfg_n <= N_MAX);
    assign in_ready=rst_n && meta_sync2 && core_run && pack_ready &&
                    ready_a && ready_b && !busy_q && cfg_valid;
    assign pair_accept=in_valid && in_ready;
    assign pair_retire=valid_a && valid_b && core_ready;
    assign bypass=nar_a || nar_b || z_a || z_b;
    assign x=bypass ? {F{1'b0}} : ops_x;
    assign y=bypass ? {(F+1){1'b0}} : ops_y;
    assign retire=out_valid && out_ready;
    assign out_valid=rst_n && meta_sync2 && pack_out_valid;
    always_ff @(posedge clk) begin
        reset_bridge_q <= `CK2Q rst_n;
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end
    posit_parser #(
        .NB(NB),
        .ES(ES)) u_a (
        .clk(clk),
        .reset_n(reset_n),
        .in_valid(pair_accept),
        .in_ready(ready_a),
        .p(a),
        .out_valid(valid_a),
        .out_ready(pair_retire),
        .s(s_a),
        .is_zero(z_a),
        .is_nar(nar_a),
        .sf(sf_a),
        .frac(frac_a)
    );
    posit_parser #(
        .NB(NB),
        .ES(ES)) u_b (
        .clk(clk),
        .reset_n(reset_n),
        .in_valid(pair_accept),
        .in_ready(ready_b),
        .p(b),
        .out_valid(valid_b),
        .out_ready(pair_retire),
        .s(s_b),
        .is_zero(z_b),
        .is_nar(nar_b),
        .sf(sf_b),
        .frac(frac_b)
    );
    ops_sel_comb #(
        .FRAC_MAX(F),
        .FRAC_W(FRAC_W),
        .SF_W(SF_W),
        .EXACT_EN(EXACT_EN),
        .OPS_EN(OPS_EN)) u_ops (
        .frac_a(frac_a),
        .frac_b(frac_b),
        .s_a(s_a),
        .s_b(s_b),
        .sf_a(sf_a),
        .sf_b(sf_b),
        .cfg_mode(mode_q),
        .cfg_ops(ops_q),
        .x_frac(ops_x),
        .y_mant(ops_y),
        .active_width(active_width),
        .sign_o(ops_sign),
        .sf_o(ops_sf),
        .swapped(ops_swapped),
        .input_cut(ops_cut),
        .cfg_error(ops_error)
    );
    mul_iter_core #(
        .FRAC_MAX(F),
        .FRAC_W(FRAC_W),
        .N_MAX(N_MAX),
        .ROUND_SCHEME(ROUND_SCHEME),
        .EXACT_EN(EXACT_EN),
        .SF_W(SF_W)) u_core (
        .clk(clk),
        .reset_n(reset_n),
        .launch_valid(pair_retire),
        .launch_ready(core_ready),
        .release_result(retire),
        .x_frac(x),
        .y_mant(y),
        .cfg_mode(mode_q),
        .cfg_n(n_q),
        .sign_i(ops_sign),
        .sf_i(ops_sf),
        .input_cut_i(ops_cut),
        .run_ready(core_run),
        .core_done(core_done),
        .acc(acc),
        .sticky_acc(sticky_acc),
        .numerical_tail(numerical_tail),
        .iterations_done(iterations_done),
        .approx_cut(approx_cut),
        .sign_o(core_sign),
        .sf_o(core_sf),
        .input_cut_o(core_cut),
        .mode_o(core_mode),
        .state_error(core_error)
    );
    mul_norm_comb #(
        .FRAC_MAX(F),
        .FRAC_W(FRAC_W),
        .ROUND_SCHEME(ROUND_SCHEME),
        .EXACT_EN(EXACT_EN),
        .SF_W(SF_W)) u_norm (
        .cfg_mode(core_mode),
        .acc(acc),
        .sticky_acc(sticky_acc),
        .sf(core_sf),
        .sf_norm(sf_norm),
        .frac_norm(frac_norm),
        .sticky_norm(sticky_norm)
    );
    posit_pack #(
        .NB(NB),
        .ES(ES),
        .ROUND_MODE(ROUND_MODE)) u_pack (
        .clk(clk),
        .reset_n(reset_n),
        .in_valid(norm_valid_q),
        .in_ready(pack_ready),
        .sign(norm_sign_q),
        .is_zero(norm_zero_q),
        .is_nar(norm_nar_q),
        .sf(norm_sf_q),
        .frac(norm_frac_q),
        .sticky(norm_sticky_q),
        .flags_in(norm_flags_q),
        .out_valid(pack_out_valid),
        .out_ready(out_ready),
        .d(d),
        .flags(flags)
    );
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            busy_q <= 1'b0;
            mode_q <= 1'b0;
            n_q <= '0;
            ops_q <= '0;
            zero_q <= 1'b0;
            nar_q <= 1'b0;
            norm_valid_q <= 1'b0;
            norm_sign_q <= 1'b0;
            norm_zero_q <= 1'b0;
            norm_nar_q <= 1'b0;
            norm_sticky_q <= 1'b0;
            norm_sf_q <= '0;
            norm_frac_q <= '0;
            norm_flags_q <= '0;
        end else begin
            if (retire) busy_q <= `CK2Q 1'b0;
            if (pair_accept) begin
                busy_q <= `CK2Q 1'b1;
                mode_q <= `CK2Q cfg_mode;
                n_q <= `CK2Q cfg_n;
                ops_q <= `CK2Q cfg_ops;
            end
            if (pair_retire) begin
                zero_q <= `CK2Q (z_a || z_b);
                nar_q <= `CK2Q (nar_a || nar_b);
            end
            if (norm_valid_q && pack_ready) norm_valid_q <= `CK2Q 1'b0;
            if (core_done) begin
                norm_valid_q <= `CK2Q 1'b1;
                norm_sign_q <= `CK2Q core_sign;
                norm_zero_q <= `CK2Q zero_q;
                norm_nar_q <= `CK2Q nar_q;
                norm_sf_q <= `CK2Q sf_norm;
                norm_frac_q <= `CK2Q frac_norm;
                norm_sticky_q <= `CK2Q sticky_norm;
                norm_flags_q <= `CK2Q ((zero_q || nar_q) ? 5'b0 :
                    {3'b0,(core_cut || approx_cut || numerical_tail),approx_cut});
            end
        end
    end
endmodule
// End of mul_iter_wrapper.sv
