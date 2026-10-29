//-----------------------------------------------------------------------------
// File          : iter_ctrl_fixed2.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-09
// Description   : SAC state and L1 tokens. No bubble before init/first/last.
// $Source: $ $Revision: 1.0 $ $Log: SPEC 5.5-A fraction token schedule. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module iter_ctrl_fixed2 (
    input logic clk,
    input logic reset_n,
    input logic launch,
    input logic cfg_mode,
    input logic [3:0] cfg_n,
    input logic [11:0] x_frac,
    output wire run_ready,
    output logic token_valid,
    output logic first,
    output logic last,
    output logic init_only,
    output logic [3:0] scale,
    output logic [3:0] iteration,
    output logic approx_cut,
    output wire state_error
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    localparam int FRAC_MAX = 12;
    
    localparam int S_W = 4;
    
    localparam int I_W = 4;

    (* ASYNC_REG="TRUE" *) logic meta_sync1,meta_sync2;
    logic emitting_q;
    logic [FRAC_MAX-1:0] fx_q;
    logic [S_W-1:0] scale_q;
    logic [I_W-1:0] count_q,limit_q;
    typedef logic [I_W-1:0] iteration_value_t;
    wire [S_W-1:0] unused_sa;
    wire unused_valid,step_error;
    wire [FRAC_MAX-1:0] fx_next;
    wire [S_W-1:0] next_scale;
    wire is_init,is_last;
    wire exhausted_selected;
    wire [I_W-1:0] next_count;
    localparam logic [I_W-1:0] EXACT_LIMIT=iteration_value_t'(FRAC_MAX);
    assign run_ready=meta_sync2;
    assign state_error=emitting_q && step_error;
    assign is_init=(fx_q=='0) || (limit_q=='0);
    assign next_count=count_q+1'b1;
    assign is_last = is_init || exhausted_selected || (next_count >= limit_q);
    // Both modes use the same 12-bit fraction; only the iteration limit differs.
    sac_step_comb_fixed3  u_step (
        .fx(fx_q),
        .scale(scale_q),
        .term_valid(unused_valid),
        .sa(unused_sa),
        .scale_next(next_scale),
        .fx_next(fx_next),
        .exhausted(exhausted_selected),
        .state_error(step_error)
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
                approx_cut <= `CK2Q (is_init ? (fx_q!='0) : (is_last && !exhausted_selected));
                fx_q <= `CK2Q fx_next;
                scale_q <= `CK2Q next_scale;
                count_q <= `CK2Q next_count;
                if (is_last) emitting_q <= `CK2Q 1'b0;
            end
        end
    end
endmodule
// End of iter_ctrl.sv
