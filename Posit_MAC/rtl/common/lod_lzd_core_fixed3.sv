//-----------------------------------------------------------------------------
// File          : lod_lzd_core_fixed3.sv
// Author(s)     : Dan Huy / Codex
// Email         :
// Project       : Posit MAC IP
// Creation Date : 2026-10-16
// Description   : Selective group4 N31/N32 MODE0; binary fallback.
//                 Unmeasured configurations retain the binary baseline.
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 2.0-selective-candidate $
// $Log: Same parameters/ports; no registers or added combinational latency. $
//-----------------------------------------------------------------------------
module lod_lzd_core_fixed3 (
    input  logic [25:0] in,
    output logic [4:0] K,               // Index of first match (0-indexed from MSB)
    output logic         vld              // 1 if matching bit is found, 0 if all 0s (LOD) or all 1s (LZD)
);
    // Fixed posit32/ES3 elaboration; no public parameters.
    localparam int N = 26;
    localparam int MODE = 0;
    localparam int S = 5;


    generate
        if (MODE == 0 && (N == 31 || N == 32) && S == $clog2(N)) begin : g_group4
            localparam int LEVELS = ($clog2(N) + 1) / 2;
            localparam int POS_W = 2 * LEVELS;
            localparam int PAD_N = 1 << POS_W;
            logic [N-1:0] match_bits;
            logic [PAD_N-1:0] padded;
            wire [PAD_N-1:0] valid_tree [LEVELS:0] /* verilator split_var */;
            wire [POS_W-1:0] pos_tree [LEVELS:0][PAD_N-1:0] /* verilator split_var */;

            assign match_bits = (MODE == 1) ? ~in : in;
            assign padded = {match_bits, {(PAD_N-N){1'b0}}};

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
            assign vld = valid_tree[LEVELS][0];
            assign K = vld ? S'(pos_tree[LEVELS][0]) : '0;
        end else begin : g_baseline
            //-------------------------------------------------------------------------
            // Parameter Validation
            //-------------------------------------------------------------------------
                if (N < 2) begin : g_param_check
                    initial $error("lod_lzd_core: Parameter N must be >= 2, got %0d", N);
                end

            //-------------------------------------------------------------------------
            // 1. Align N to nearest power of 2 with zero-padding
            //-------------------------------------------------------------------------
            localparam int POW2_N = 1 << S;

            logic [POW2_N-1:0] data_pad;

            always_comb begin
                data_pad = '0; // Unused lower bits padded with 0 (will never match)
                for (int i = 0; i < N; i++) begin
                    data_pad[POW2_N - 1 - i] = (MODE == 1) ? ~in[N - 1 - i] : in[N - 1 - i];
                end
            end

            //-------------------------------------------------------------------------
            // 2. Flat Binary Tree Implementation
            //    tree_vld[l][j]: indicates if there is any '1' in the 2^l group
            //    tree_pos[l][j]: index of the first '1' within the 2^l group
            //-------------------------------------------------------------------------
            logic [POW2_N-1:0] tree_vld [S:0] /* verilator split_var */;
            logic [S-1:0]      tree_pos [S:0][POW2_N-1:0] /* verilator split_var */;

            // Level 0: Leaves (individual bits)
            genvar l, j;
                for (j = 0; j < POW2_N; j++) begin : g_leaves
                    assign tree_vld[0][j] = data_pad[j];
                    assign tree_pos[0][j] = '0;
                end

                // Levels 1 to S: Combine adjacent pairs
                for (l = 0; l < S; l++) begin : g_tree_levels
                    localparam int NODES = POW2_N >> (l + 1);
                    localparam int STEP  = 1 << l;

                    for (j = 0; j < NODES; j++) begin : g_nodes
                        wire vld_hi = tree_vld[l][2*j + 1];
                        wire vld_lo = tree_vld[l][2*j];

                        assign tree_vld[l+1][j] = vld_hi | vld_lo;
                        assign tree_pos[l+1][j] = vld_hi ? tree_pos[l][2*j + 1] 
                                                         : (tree_pos[l][2*j] | STEP[S-1:0]);
                    end
                end

            //-------------------------------------------------------------------------
            // 3. Output Assignment from Tree Root
            //-------------------------------------------------------------------------
            assign vld = tree_vld[S][0];
            assign K   = vld ? tree_pos[S][0] : '0;

        end
    endgenerate
endmodule
// End of lod_lzd_core.sv
