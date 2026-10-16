//-----------------------------------------------------------------------------
// File          : lod_lzd_core.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP
// Creation Date : 2026-10-16
// Description   : Four-way levels with a two-way root for odd count width.
// $Source: $ $Revision: 2.1-candidate $ $Log: Minimal power-of-two padding. $
//-----------------------------------------------------------------------------
module lod_lzd_core #(
    parameter int N = 32,
    parameter int MODE = 0,
    parameter int S = (N > 1) ? $clog2(N) : 1
)(
    input logic [N-1:0] in,
    output logic [S-1:0] K,
    output logic vld
);
    localparam int POS_W = (N > 1) ? $clog2(N) : 1;
    localparam int LEVELS = (POS_W + 1) / 2;
    localparam int PAD_N = 1 << POS_W;
    wire [N-1:0] match_bits;
    wire [PAD_N-1:0] padded;
    wire [PAD_N-1:0] valid_tree [LEVELS:0] /* verilator split_var */;
    wire [POS_W-1:0] pos_tree [LEVELS:0][PAD_N-1:0] /* verilator split_var */;
    assign match_bits = (MODE == 1) ? ~in : in;
    assign padded = {match_bits, {(PAD_N-N){1'b0}}};
    generate
        if (N < 2 || S < POS_W) begin : g_invalid
            initial $fatal(1,"lod_lzd_core: unsupported parameters");
        end
        for (genvar j=0;j<PAD_N;j++) begin : g_leaves
            assign valid_tree[0][j] = padded[j];
            assign pos_tree[0][j] = '0;
        end
        for (genvar l=0;l<LEVELS;l++) begin : g_levels
            localparam bit BINARY_ROOT = ((POS_W % 2) != 0) && (l == LEVELS-1);
            localparam int COVER_BITS = BINARY_ROOT ? POS_W : 2*(l+1);
            localparam int NODES = PAD_N >> COVER_BITS;
            for (genvar j=0;j<NODES;j++) begin : g_nodes
                if (BINARY_ROOT) begin : g_binary
                    wire hi;
                    wire lo;
                    assign hi = valid_tree[l][2*j+1];
                    assign lo = valid_tree[l][2*j];
                    assign valid_tree[l+1][j] = hi | lo;
                    assign pos_tree[l+1][j] = hi ? pos_tree[l][2*j+1]
                        : (pos_tree[l][2*j] | (POS_W'(1) << (2*l)));
                end else begin : g_four
                    wire [3:0] child;
                    wire [1:0] index;
                    wire [POS_W-1:0] local_pos;
                    assign child = valid_tree[l][4*j +: 4];
                    assign valid_tree[l+1][j] = |child;
                    assign index[1] = !(|child[3:2]);
                    assign index[0] = !child[3] & (child[2] | !child[1]);
                    assign local_pos = child[3] ? pos_tree[l][4*j+3]
                                     : child[2] ? pos_tree[l][4*j+2]
                                     : child[1] ? pos_tree[l][4*j+1]
                                                : pos_tree[l][4*j];
                    assign pos_tree[l+1][j] = local_pos | (POS_W'(index) << (2*l));
                end
            end
        end
    endgenerate
    assign vld = valid_tree[LEVELS][0];
    assign K = vld ? S'(pos_tree[LEVELS][0]) : '0;
endmodule
// End of lod_lzd_core.sv
