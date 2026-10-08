//-----------------------------------------------------------------------------
// File          : posit_pack_finish.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-06
// Description   : P2 combinational rounding, magnitude clamp and sign encoding.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: Initial implementation of SPEC 5.9-D. $

module posit_pack_finish_reference #(
    parameter int NB = 32,
    parameter ROUND_MODE = "RNE"
)(
    input  logic [NB-2:0] mag_trunc,
    input  logic guard_bit,
    input  logic round_bit,
    input  logic sticky_bit,
    input  logic sign,
    input  logic [2:0] special_sel,
    input  logic [4:0] flags_in,
    output logic [NB-1:0] d,
    output logic [4:0] flags
);
    localparam logic [2:0] NORMAL = 3'd0;
    localparam logic [2:0] ZERO = 3'd1;
    localparam logic [2:0] NAR = 3'd2;
    localparam logic [2:0] MAXPOS = 3'd3;
    localparam logic [2:0] MINPOS = 3'd4;
    localparam logic [NB-1:0] MAX_MAG = {1'b0, {NB-1{1'b1}}};

    wire round_up;
    logic [NB-1:0] mag_extended;
    logic [NB-1:0] magnitude;

    generate
        if (ROUND_MODE == "RNE") begin : g_rne
            assign round_up = guard_bit
                            & (mag_trunc[0] | round_bit | sticky_bit);
        end else if (ROUND_MODE == "TRUNC") begin : g_trunc
            assign round_up = 1'b0;
        end else begin : g_invalid
            initial $fatal(1, "posit_pack_finish: ROUND_MODE must be RNE or TRUNC");
        end
    endgenerate

    always_comb begin
        mag_extended = {1'b0, mag_trunc}
                     + {{NB-1{1'b0}}, round_up};
        magnitude = mag_extended;
        flags = flags_in;
        d = '0;

        if (mag_extended > MAX_MAG) begin
            magnitude = MAX_MAG;
        end else if (mag_extended == '0) begin
            magnitude = {{NB-1{1'b0}}, 1'b1};
        end

        case (special_sel)
            ZERO: begin
                magnitude = '0;
                d = '0;
            end
            NAR: begin
                magnitude = '0;
                d = {1'b1, {NB-1{1'b0}}};
                flags = 5'b10000;
            end
            MAXPOS: begin
                magnitude = MAX_MAG;
                d = sign ? (~magnitude + 1'b1) : magnitude;
            end
            MINPOS: begin
                magnitude = {{NB-1{1'b0}}, 1'b1};
                d = sign ? (~magnitude + 1'b1) : magnitude;
            end
            NORMAL: begin
                d = sign ? (~magnitude + 1'b1) : magnitude;
            end
            default: begin
                d = '0;
                flags = '0;
            end
        endcase
    end
endmodule
//-----------------------------------------------------------------------------
// End of posit_pack_finish.sv
//-----------------------------------------------------------------------------
