//-----------------------------------------------------------------------------
// File          : lod_lzd_core.sv
// Author(s)     : Dan Huy / Codex
// Project       : Posit MAC IP
// Creation Date : 2026-10-16
// Description   : Candidate four-way hierarchy; same public binary contract.
// $Source: $ $Revision: 2.0-candidate $ $Log: Primitive optimization study. $
//-----------------------------------------------------------------------------
module lod_lzd_core #(
    parameter int N    = 32,
    parameter int MODE = 0,
    parameter int S    = (N > 1) ? $clog2(N) : 1
)(
    input  logic [N-1:0] in,
    output logic [S-1:0] K,
    output logic vld
);
    localparam int LEVELS = ($clog2(N) + 1) / 2;
    localparam int POS_W = 2 * LEVELS;
    localparam int PAD_N = 1 << POS_W;
    logic [N-1:0] match_bits;
    logic [PAD_N-1:0] padded;
    wire [PAD_N-1:0] valid_tree [LEVELS:0] /* verilator split_var */;
    wire [POS_W-1:0] pos_tree [LEVELS:0][PAD_N-1:0] /* verilator split_var */;

    assign match_bits = (MODE == 1) ? ~in : in;
    assign padded = {match_bits, {(PAD_N-N){1'b0}}};

    generate
        if (N < 2 || S < $clog2(N)) begin : g_invalid
            initial $fatal(1, "lod_lzd_core: unsupported parameters");
        end
        for (genvar j = 0; j < PAD_N; j++) begin : g_leaves
            assign valid_tree[0][j] = padded[j];
            assign pos_tree[0][j] = '0;
        end
        for (genvar l = 0; l < LEVELS; l++) begin : g_levels
            localparam int NODES = PAD_N >> (2 * (l + 1));
            for (genvar j = 0; j < NODES; j++) begin : g_nodes
                wire [3:0] valid_child;
                wire [1:0] group_index;
                wire [POS_W-1:0] selected_pos;
                assign valid_child = valid_tree[l][4*j +: 4];
                assign valid_tree[l+1][j] = |valid_child;
                // Group 3 contains the most significant input bits.
                assign group_index[1] = !(|valid_child[3:2]);
                assign group_index[0] = !valid_child[3]
                                     & (valid_child[2] | !valid_child[1]);
                assign selected_pos = valid_child[3] ? pos_tree[l][4*j+3]
                                    : valid_child[2] ? pos_tree[l][4*j+2]
                                    : valid_child[1] ? pos_tree[l][4*j+1]
                                                     : pos_tree[l][4*j];
                assign pos_tree[l+1][j] = selected_pos
                                       | (POS_W'(group_index) << (2*l));
            end
        end
    endgenerate
    assign vld = valid_tree[LEVELS][0];
    assign K = vld ? S'(pos_tree[LEVELS][0]) : '0;
endmodule
// End of lod_lzd_core.sv
