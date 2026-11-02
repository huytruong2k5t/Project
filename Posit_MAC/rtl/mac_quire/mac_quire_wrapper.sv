//-----------------------------------------------------------------------------
// File          : mac_quire_wrapper.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-11-03
// Description   : Q12-1024 CLEAR/MAC/READ, one command/response outstanding.
// $Revision: 1.0 $ $Log: Shared multiplier, atomic bank, RNE only on READ. $
//-----------------------------------------------------------------------------
`include "posit_mac.vh"
module mac_quire_wrapper (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    output wire         in_ready,
    input  logic [1:0]  q_cmd,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  cfg_n,
    input  logic [1:0]  cfg_ops,
    output wire         out_valid,
    input  logic        out_ready,
    output logic [1:0]  out_cmd,
    output logic [31:0] d,
    output logic [4:0]  flags,
    output logic        q_overflow
);
    localparam logic [1:0] CLEAR=2'd0, MAC=2'd1, READ=2'd2;
    localparam logic [2:0] IDLE=3'd0, PRODUCT=3'd1, BANK=3'd2,
                           READING=3'd3, RESPONSE=3'd4;
    logic reset_bridge_q;
    wire reset_n;
    (* ASYNC_REG="TRUE" *) logic meta_sync1, meta_sync2;
    logic [2:0] state_q;
    logic [3:0] n_q;
    logic ops_q;
    logic product_nar_q;
    wire accept, retire, mac_accept, read_accept, clear_select;
    wire cfg_valid;
    wire ready_a, ready_b, valid_a, valid_b, pair_retire;
    wire s_a, s_b, z_a, z_b, nar_a, nar_b;
    wire signed [10:0] sf_a, sf_b;
    wire [25:0] frac_a, frac_b;
    wire [11:0] ops_x, x;
    wire [12:0] ops_y, y;
    wire ops_sign, ops_cut, bypass;
    wire signed [10:0] ops_sf;
    wire core_ready, core_run, core_done, core_error, core_release;
    wire [25:0] acc;
    wire [3:0] iterations_done;
    wire approx_cut, core_sign, core_cut;
    wire signed [10:0] core_sf;
    wire [971:0] aligned_term;
    wire align_error;
    wire bank_valid, bank_ready, bank_done;
    wire bank_invalid, bank_loss;
    wire [971:0] q_value;
    wire [10:0] q_count;
    wire q_nar, q_invalid, q_loss, q_cut, bank_overflow;
    wire read_ready, read_valid, pack_ready;
    wire read_sign, read_zero, read_nar, read_sticky;
    wire signed [10:0] read_sf;
    wire [52:0] read_frac;
    wire [4:0] read_flags;
    wire pack_valid, pack_retire;
    wire [31:0] pack_d;
    wire [4:0] pack_flags;
    wire [4:0] status_flags;

    assign reset_n = reset_bridge_q;
    assign cfg_valid = cfg_n <= 4'd12 && cfg_ops <= 2'd1;
    assign clear_select = state_q == IDLE && q_cmd == CLEAR;
    assign in_ready = rst_n && meta_sync2 && state_q == IDLE
                    && ready_a && ready_b && core_run && core_ready && read_ready
                    && ((q_cmd == CLEAR && bank_ready)
                     || (q_cmd == MAC && cfg_valid && bank_ready && q_count < 11'd1024)
                     || (q_cmd == READ));
    assign accept = in_valid && in_ready;
    assign mac_accept = accept && q_cmd == MAC;
    assign read_accept = accept && q_cmd == READ;
    assign out_valid = rst_n && meta_sync2 && state_q == RESPONSE;
    assign retire = out_valid && out_ready;
    assign core_release = retire && out_cmd == MAC;
    assign pair_retire = valid_a && valid_b && core_ready;
    assign bypass = nar_a || nar_b || z_a || z_b;
    assign x = bypass ? 12'b0 : ops_x;
    assign y = bypass ? 13'b0 : ops_y;
    assign ops_cut = |(frac_a[13:0] | frac_b[13:0]);
    assign bank_valid = (accept && q_cmd == CLEAR) || (state_q == PRODUCT && core_done);
    assign bank_invalid = align_error || core_error;
    assign bank_loss = core_cut || approx_cut;
    assign status_flags = (q_nar || q_invalid) ? 5'b10000 : {3'b0, q_loss, q_cut};
    assign pack_retire = state_q == READING;

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

    posit_parser u_a (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (mac_accept),
        .in_ready (ready_a),
        .p (a),
        .out_valid (valid_a),
        .out_ready (pair_retire),
        .s (s_a),
        .is_zero (z_a),
        .is_nar (nar_a),
        .sf (sf_a),
        .frac (frac_a)
    );
    posit_parser u_b (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (mac_accept),
        .in_ready (ready_b),
        .p (b),
        .out_valid (valid_b),
        .out_ready (pair_retire),
        .s (s_b),
        .is_zero (z_b),
        .is_nar (nar_b),
        .sf (sf_b),
        .frac (frac_b)
    );
    ops_sel_comb u_ops (
        .frac_a (frac_a[25:14]),
        .frac_b (frac_b[25:14]),
        .s_a (s_a),
        .s_b (s_b),
        .sf_a (sf_a),
        .sf_b (sf_b),
        .cfg_ops (ops_q),
        .x_frac (ops_x),
        .y_mant (ops_y),
        .sign_o (ops_sign),
        .sf_o (ops_sf)
    );
    mul_iter_core u_core (
        .clk (clk),
        .reset_n (reset_n),
        .launch_valid (pair_retire),
        .launch_ready (core_ready),
        .release_result (core_release),
        .x_frac (x),
        .y_mant (y),
        .cfg_n (n_q),
        .sign_i (ops_sign),
        .sf_i (ops_sf),
        .input_cut_i (ops_cut),
        .run_ready (core_run),
        .core_done (core_done),
        .acc (acc),
        .iterations_done (iterations_done),
        .approx_cut (approx_cut),
        .sign_o (core_sign),
        .sf_o (core_sf),
        .input_cut_o (core_cut),
        .state_error (core_error)
    );
    quire_align_comb u_align (
        .magnitude (acc),
        .sign (core_sign),
        .sf (core_sf),
        .term (aligned_term),
        .align_error (align_error)
    );
    quire_bank u_bank (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (bank_valid),
        .in_ready (bank_ready),
        .clear (clear_select),
        .term (aligned_term),
        .term_nar (product_nar_q),
        .term_invalid (bank_invalid),
        .term_loss (bank_loss),
        .term_cut (approx_cut),
        .done (bank_done),
        .q_value (q_value),
        .q_count (q_count),
        .q_nar (q_nar),
        .q_invalid (q_invalid),
        .q_loss (q_loss),
        .q_cut (q_cut),
        .q_overflow (bank_overflow)
    );
    quire_read u_read (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (read_accept),
        .in_ready (read_ready),
        .q_value (q_value),
        .q_nar (q_nar),
        .q_invalid (q_invalid),
        .q_loss (q_loss),
        .q_cut (q_cut),
        .out_valid (read_valid),
        .out_ready (pack_ready),
        .sign (read_sign),
        .is_zero (read_zero),
        .is_nar (read_nar),
        .sf (read_sf),
        .frac (read_frac),
        .sticky (read_sticky),
        .flags_in (read_flags)
    );
    posit_pack u_pack (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (read_valid),
        .in_ready (pack_ready),
        .sign (read_sign),
        .is_zero (read_zero),
        .is_nar (read_nar),
        .sf (read_sf),
        .frac (read_frac),
        .sticky (read_sticky),
        .flags_in (read_flags),
        .out_valid (pack_valid),
        .out_ready (pack_retire),
        .d (pack_d),
        .flags (pack_flags)
    );

    always_ff @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
            state_q <= IDLE;
            n_q <= 4'd12;
            ops_q <= 1'b1;
            product_nar_q <= 1'b0;
            out_cmd <= CLEAR;
            d <= '0;
            flags <= '0;
            q_overflow <= 1'b0;
        end else begin
            if (pair_retire) product_nar_q <= `CK2Q (nar_a || nar_b);
            case (state_q)
                IDLE: begin
                    if (accept) begin
                        out_cmd <= `CK2Q q_cmd;
                        if (q_cmd == MAC) begin
                            n_q <= `CK2Q cfg_n;
                            ops_q <= `CK2Q cfg_ops[0];
                            state_q <= `CK2Q PRODUCT;
                        end else if (q_cmd == CLEAR) begin
                            state_q <= `CK2Q BANK;
                        end else begin
                            state_q <= `CK2Q READING;
                        end
                    end
                end
                PRODUCT: begin
                    if (core_done) state_q <= `CK2Q BANK;
                end
                BANK: begin
                    if (bank_done) begin
                        d <= `CK2Q 32'b0;
                        flags <= `CK2Q status_flags;
                        q_overflow <= `CK2Q bank_overflow;
                        state_q <= `CK2Q RESPONSE;
                    end
                end
                READING: begin
                    if (pack_valid) begin
                        d <= `CK2Q pack_d;
                        flags <= `CK2Q pack_flags;
                        q_overflow <= `CK2Q bank_overflow;
                        state_q <= `CK2Q RESPONSE;
                    end
                end
                RESPONSE: begin
                    if (retire) state_q <= `CK2Q IDLE;
                end
                default: state_q <= `CK2Q IDLE;
            endcase
        end
    end

    // synthesis translate_off
    always @(posedge clk or negedge meta_sync2) begin
        if (!meta_sync2) begin
        end else if (meta_sync2) begin
            assert (!(bank_valid && !bank_ready)) else $fatal(1, "Quire bank request lost");
            assert (!core_error) else $fatal(1, "Quire multiplier invariant");
            assert (!core_done || iterations_done <= n_q) else $fatal(1, "Quire iteration limit");
            assert (q_count <= 11'd1024) else $fatal(1, "Quire capacity");
        end
    end
    // synthesis translate_on
endmodule
// End of mac_quire_wrapper.sv
