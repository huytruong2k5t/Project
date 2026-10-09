//-----------------------------------------------------------------------------
// File          : paper_mul_wrapper.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP - separate research branch
// Creation Date : 2026-10-09
// Description   : Single owned transaction; autonomous signed recurrence.
//                 Input E0 -> t commit edges -> pack/output edge E(t+1).
//                 Zero/NaR bypass has t=0; NaR takes precedence over Zero.
//                 Arithmetic, tie-A and prefix padding are research assumptions.
// $Source: $ $Revision: 1.0 $ $Log: Autonomous research integration. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module paper_mul_wrapper (
    input logic clk,
    input logic reset_n,
    input logic in_valid,
    output wire in_ready,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [3:0] n_terms,
    input logic force_a,
    output wire out_valid,
    input logic out_ready,
    output logic [31:0] d,
    output wire [3:0] iterations,
    output logic state_error,
    output wire trace_valid,
    output wire [3:0] trace_iteration,
    output wire [12:0] trace_mantissa,
    output wire signed [7:0] trace_exponent,
    output wire signed [7:0] trace_power,
    output wire trace_negative,
    output wire trace_anchor,
    output wire [13:0] trace_acc,
    output wire [13:0] trace_term,
    output wire trace_tail,
    output wire [12:0] trace_mantissa_next,
    output wire signed [7:0] trace_exponent_next,
    output wire trace_negative_next,
    output wire [13:0] trace_acc_next
);
    localparam logic [1:0] IDLE = 2'd0;
    localparam logic [1:0] STEP = 2'd1;
    localparam logic [1:0] PACK = 2'd2;
    localparam logic [1:0] HOLD = 2'd3;
    (* ASYNC_REG = "TRUE" *) logic meta_sync1, meta_sync2;
    logic [1:0] state_q, state_d;
    logic [3:0] limit_q, count_q;
    logic sign_q, zero_q, nar_q, anchor_q, negative_q;
    logic [12:0] mantissa_q, y_q;
    logic signed [7:0] exponent_q;
    logic signed [10:0] sf_base_q;
    logic [13:0] acc_q;
    wire s_a, s_b, zero_a, zero_b, nar_a, nar_b;
    wire signed [10:0] sf_a, sf_b, sf;
    wire [25:0] frac_a, frac_b;
    wire [12:0] mant_a, mant_b, x_mant, y_mant;
    wire [11:0] score_a, score_b;
    wire swapped;
    wire [13:0] normalized;
    wire [52:0] frac;
    wire [31:0] packed_d;
    wire [4:0] packed_flags;
    wire [4:0] flags_in;
    wire sticky;
    wire step_error, config_valid, first_anchor;

    assign config_valid = n_terms >= 4'd1 && n_terms <= 4'd8;
    assign in_ready = reset_n && meta_sync2 && state_q == IDLE && config_valid;
    assign out_valid = reset_n && meta_sync2 && state_q == HOLD;
    assign iterations = count_q;
    assign trace_valid = reset_n && meta_sync2 && state_q == STEP;
    assign trace_iteration = count_q + 4'd1;
    assign trace_mantissa = mantissa_q;
    assign trace_exponent = exponent_q;
    assign trace_negative = negative_q;
    assign trace_anchor = anchor_q;
    assign trace_acc = acc_q;
    assign mant_a = {1'b1, frac_a[25:14]};
    assign mant_b = {1'b1, frac_b[25:14]};
    assign first_anchor = x_mant[11];
    // Algorithmic residual and input cut are not final-pack sticky.
    assign sticky = 1'b0;
    assign flags_in = 5'b0;
    // Scores/swapped are consumed inside OPS; no duplicate output registers.
    // packed_flags are local packer diagnostics, not paper-defined status flags.

    posit_parser_comb #(
        .NB(32),
        .ES(3)
    ) u_a (
        .p(a),
        .s(s_a),
        .is_zero(zero_a),
        .is_nar(nar_a),
        .sf(sf_a),
        .frac(frac_a)
    );
    posit_parser_comb #(
        .NB(32),
        .ES(3)
    ) u_b (
        .p(b),
        .s(s_b),
        .is_zero(zero_b),
        .is_nar(nar_b),
        .sf(sf_b),
        .frac(frac_b)
    );
    paper_ops_comb u_ops (
        .mant_a(mant_a),
        .mant_b(mant_b),
        .force_a(force_a),
        .x_mant(x_mant),
        .y_mant(y_mant),
        .score_a(score_a),
        .score_b(score_b),
        .swapped(swapped)
    );
    paper_step_comb u_step (
        .mantissa(mantissa_q),
        .exponent(exponent_q),
        .negative_coefficient(negative_q),
        .anchor(anchor_q),
        .y_mant(y_q),
        .acc(acc_q),
        .power(trace_power),
        .mantissa_next(trace_mantissa_next),
        .exponent_next(trace_exponent_next),
        .negative_next(trace_negative_next),
        .term(trace_term),
        .term_tail(trace_tail),
        .acc_next(trace_acc_next),
        .state_error(step_error)
    );
    paper_norm_comb u_norm (
        .acc(acc_q),
        .sf_base(sf_base_q),
        .anchor(anchor_q),
        .normalized(normalized),
        .sf(sf),
        .frac(frac)
    );
    posit_pack_comb #(
        .NB(32),
        .ES(3),
        .ROUND_MODE("TRUNC")
    ) u_pack (
        .sign(sign_q),
        .is_zero(zero_q),
        .is_nar(nar_q),
        .sf(sf),
        .frac(frac),
        .sticky(sticky),
        .flags_in(flags_in),
        .d(packed_d),
        .flags(packed_flags)
    );

    always_comb begin
        state_d = state_q;
        case (state_q)
            IDLE: begin
                if (in_valid && in_ready) begin
                    state_d = (zero_a || zero_b || nar_a || nar_b) ? PACK : STEP;
                end
            end
            STEP: begin
                if (trace_mantissa_next == 0 || count_q + 4'd1 >= limit_q) begin
                    state_d = PACK;
                end
            end
            PACK: state_d = HOLD;
            HOLD: begin
                if (out_ready) state_d = IDLE;
            end
            default: state_d = IDLE;
        endcase
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

    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            state_q <= IDLE;
            limit_q <= '0;
            count_q <= '0;
            sign_q <= 1'b0;
            zero_q <= 1'b0;
            nar_q <= 1'b0;
            anchor_q <= 1'b0;
            negative_q <= 1'b0;
            mantissa_q <= '0;
            y_q <= '0;
            exponent_q <= '0;
            sf_base_q <= '0;
            acc_q <= '0;
            d <= '0;
            state_error <= 1'b0;
        end else begin
            state_q <= `CK2Q state_d;
            if (in_valid && in_ready) begin
                limit_q <= `CK2Q n_terms;
                count_q <= `CK2Q '0;
                sign_q <= `CK2Q (s_a ^ s_b);
                zero_q <= `CK2Q (zero_a || zero_b);
                nar_q <= `CK2Q (nar_a || nar_b);
                anchor_q <= `CK2Q first_anchor;
                negative_q <= `CK2Q 1'b0;
                mantissa_q <= `CK2Q x_mant;
                y_q <= `CK2Q y_mant;
                exponent_q <= `CK2Q '0;
                sf_base_q <= `CK2Q (sf_a + sf_b);
                acc_q <= `CK2Q '0;
                state_error <= `CK2Q 1'b0;
            end else if (state_q == STEP) begin
                count_q <= `CK2Q (count_q + 4'd1);
                mantissa_q <= `CK2Q trace_mantissa_next;
                exponent_q <= `CK2Q trace_exponent_next;
                negative_q <= `CK2Q trace_negative_next;
                acc_q <= `CK2Q trace_acc_next;
                state_error <= `CK2Q (state_error || step_error);
            end else if (state_q == PACK) begin
                d <= `CK2Q packed_d;
            end
        end
    end
endmodule
// End of paper_mul_wrapper.sv
