//-----------------------------------------------------------------------------
// File          : lod_lzd_core.sv
// Author(s)     : Dan Huy
// Email         : 
// Project       : Posit MAC IP (Approximate & Iterative Posit MAC)
// Creation Date : 2026-10-01
//
// Description   : Parameterized Leading One / Zero Detector using a flat
//                 binary tree structure. Hardware-optimized for FPGA LUTs.
//                 MODE = 0: LOD (Lead One Detector / Leading Zero Counter)
//                 MODE = 1: LZD (Lead Zero Detector / Leading One Counter)
//-----------------------------------------------------------------------------
// $Source: $
// $Revision: 1.0 $
// $Log: $

module lod_lzd_core #(
    parameter int N    = 32,
    parameter int MODE = 0,               // 0: LOD (Lead One), 1: LZD (Lead Zero)
    parameter int S    = (N > 1) ? $clog2(N) : 1
)(
    input  logic [N-1:0] in,
    output logic [S-1:0] K,               // Index of first match (0-indexed from MSB)
    output logic         vld              // 1 if matching bit is found, 0 if all 0s (LOD) or all 1s (LZD)
);

    //-------------------------------------------------------------------------
    // Parameter Validation
    //-------------------------------------------------------------------------
    generate
        if (N < 2) begin : g_param_check
            initial $error("lod_lzd_core: Parameter N must be >= 2, got %0d", N);
        end
    endgenerate

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
    logic [POW2_N-1:0] tree_vld [S:0];
    logic [S-1:0]      tree_pos [S:0][POW2_N-1:0];

    // Level 0: Leaves (individual bits)
    genvar l, j;
    generate
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
    endgenerate

    //-------------------------------------------------------------------------
    // 3. Output Assignment from Tree Root
    //-------------------------------------------------------------------------
    assign vld = tree_vld[S][0];
    assign K   = vld ? tree_pos[S][0] : '0;

endmodule
