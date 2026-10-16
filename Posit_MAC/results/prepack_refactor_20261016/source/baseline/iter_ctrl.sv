//-----------------------------------------------------------------------------
// File          : iter_ctrl.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : SAC state and L1 tokens. No bubble before init/first/last.
// $Source: $ $Revision: 1.0 $ $Log: SPEC 5.5-A fraction token schedule. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module iter_ctrl #(
    parameter int FRAC_MAX = 27,
    parameter int FRAC_W = 12,
    parameter int N_MAX = 8,
    parameter int S_W = (FRAC_MAX > 1) ? $clog2(FRAC_MAX+1) : 1,
    parameter int N_W = (N_MAX > 1) ? $clog2(N_MAX+1) : 1,
    parameter int I_W = $clog2(((FRAC_MAX > N_MAX) ? FRAC_MAX : N_MAX)+1)
)(
    input logic clk,
    input logic reset_n,
    input logic launch,
    input logic cfg_mode,
    input logic [N_W-1:0] cfg_n,
    input logic [FRAC_MAX-1:0] x_frac,
    output wire run_ready,
    output logic token_valid,
    output logic first,
    output logic last,
    output logic init_only,
    output logic [S_W-1:0] scale,
    output logic [I_W-1:0] iteration,
    output logic approx_cut,
    output wire state_error
);
    (* ASYNC_REG="TRUE" *) logic meta_sync1,meta_sync2;
    logic emitting_q;
    logic mode_q;
    logic [FRAC_MAX-1:0] fx_q;
    logic [S_W-1:0] scale_q;
    logic [I_W-1:0] count_q,limit_q;
    typedef logic [I_W-1:0] iteration_value_t;
    typedef logic [FRAC_MAX-1:0] fraction_value_t;
    wire [FRAC_MAX-1:0] fx_next_exact;
    wire [FRAC_W-1:0] fx_approx,fx_next_approx;
    wire [S_W-1:0] scale_exact,scale_approx,unused_sa_exact,unused_sa_approx;
    wire unused_valid_exact,unused_valid_approx,unused_exhausted_exact,unused_exhausted_approx,error_exact,error_approx;
    wire [FRAC_MAX-1:0] fx_next;
    wire [S_W-1:0] next_scale;
    wire is_init,is_last;
    wire [I_W-1:0] next_count;
    localparam logic [I_W-1:0] EXACT_LIMIT=iteration_value_t'(FRAC_MAX);
    assign run_ready=meta_sync2;
    assign fx_approx=fx_q[FRAC_W-1:0];
    assign fx_next=mode_q ? fraction_value_t'(fx_next_approx) : fx_next_exact;
    assign next_scale=mode_q ? scale_approx : scale_exact;
    assign state_error=emitting_q && (mode_q ? error_approx : error_exact);
    assign is_init=(fx_q=='0) || (limit_q=='0);
    assign next_count=count_q+1'b1;
    assign is_last=is_init || (fx_next=='0) || (next_count>=limit_q);
    sac_step_comb #(
        .W_X(FRAC_MAX),
        .S_W(S_W)) u_exact (
        .fx(fx_q),
        .scale(scale_q),
        .term_valid(unused_valid_exact),
        .sa(unused_sa_exact),
        .scale_next(scale_exact),
        .fx_next(fx_next_exact),
        .exhausted(unused_exhausted_exact),
        .state_error(error_exact)
    );
    sac_step_comb #(
        .W_X(FRAC_W),
        .S_W(S_W)) u_approx (
        .fx(fx_approx),
        .scale(scale_q),
        .term_valid(unused_valid_approx),
        .sa(unused_sa_approx),
        .scale_next(scale_approx),
        .fx_next(fx_next_approx),
        .exhausted(unused_exhausted_approx),
        .state_error(error_approx)
    );
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta_sync1 <= 1'b0;
            meta_sync2 <= 1'b0;
        end else begin
            meta_sync1 <= `CK2Q 1'b1;
            meta_sync2 <= `CK2Q meta_sync1;
        end
    end
    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            emitting_q <= 1'b0;
            mode_q <= 1'b0;
            fx_q <= '0;
            scale_q <= '0;
            count_q <= '0;
            limit_q <= '0;
            token_valid <= 1'b0;
            first <= 1'b0;
            last <= 1'b0;
            init_only <= 1'b0;
            scale <= '0;
            iteration <= '0;
            approx_cut <= 1'b0;
        end else begin
            token_valid <= `CK2Q emitting_q;
            if (launch) begin
                emitting_q <= `CK2Q 1'b1;
                mode_q <= `CK2Q cfg_mode;
                fx_q <= `CK2Q x_frac;
                scale_q <= `CK2Q '0;
                count_q <= `CK2Q '0;
                limit_q <= `CK2Q (cfg_mode ? iteration_value_t'(cfg_n) : EXACT_LIMIT);
            end else if (emitting_q) begin
                first <= `CK2Q (count_q=='0);
                last <= `CK2Q is_last;
                init_only <= `CK2Q is_init;
                scale <= `CK2Q (is_init ? {S_W{1'b0}} : next_scale);
                iteration <= `CK2Q (is_init ? {I_W{1'b0}} : next_count);
                approx_cut <= `CK2Q (is_init ? (fx_q!='0) : (is_last && fx_next!='0));
                fx_q <= `CK2Q fx_next;
                scale_q <= `CK2Q next_scale;
                count_q <= `CK2Q next_count;
                if (is_last) emitting_q <= `CK2Q 1'b0;
            end
        end
    end
endmodule
// End of iter_ctrl.sv
