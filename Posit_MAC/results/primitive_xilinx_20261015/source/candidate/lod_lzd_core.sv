//-----------------------------------------------------------------------------
// File          : lod_lzd_core.sv
// Author(s)     : Dan Huy
// Project       : Posit MAC IP
// Creation Date : 2026-10-15
// Description   : Isolated BASE-02 candidate. Invalid subtrees encode K=0;
//                 only the position bits meaningful at each level are muxed.
// $Source: $ $Revision: 1.1-candidate $ $Log: Keep MODE, padding, S and K0. $
//-----------------------------------------------------------------------------
module lod_lzd_core #(
    parameter int N    = 32,
    parameter int MODE = 0,
    parameter int S    = (N > 1) ? $clog2(N) : 1
)(
    input  logic [N-1:0] in,
    output logic [S-1:0] K,
    output logic         vld
);
    localparam int POW2_N = 1 << S;

    logic [N-1:0] in_norm;
    logic [POW2_N-1:0] data_pad;
    logic [POW2_N-1:0] tree_vld [S:0] /* verilator split_var */;
    logic [S-1:0] tree_pos [S:0][POW2_N-1:0] /* verilator split_var */;

    assign in_norm = (MODE == 1) ? ~in : in;

    generate
        if (N < 2 || S < $clog2(N)) begin : g_invalid
            initial $fatal(1, "lod_lzd_core: invalid parameters");
        end

        if (POW2_N > N) begin : g_pad
            assign data_pad = {in_norm, {(POW2_N-N){1'b0}}};
        end else begin : g_no_pad
            assign data_pad = in_norm;
        end

        for (genvar j = 0; j < POW2_N; j++) begin : g_leaves
            assign tree_vld[0][j] = data_pad[j];
            assign tree_pos[0][j] = '0;
        end

        for (genvar l = 0; l < S; l++) begin : g_tree_levels
            localparam int NODES = POW2_N >> (l + 1);

            for (genvar j = 0; j < NODES; j++) begin : g_nodes
                logic vld_hi;
                logic vld_lo;
                assign vld_hi = tree_vld[l][2*j+1];
                assign vld_lo = tree_vld[l][2*j];
                assign tree_vld[l+1][j] = vld_hi | vld_lo;

                // No match in either child must also produce position zero.
                assign tree_pos[l+1][j][l] = ~vld_hi & vld_lo;

                if (l > 0) begin : g_lower_position
                    assign tree_pos[l+1][j][l-1:0] = vld_hi
                        ? tree_pos[l][2*j+1][l-1:0]
                        : tree_pos[l][2*j][l-1:0];
                end

                if (S > l + 1) begin : g_upper_zero
                    assign tree_pos[l+1][j][S-1:l+1] = '0;
                end
            end
        end
    endgenerate

    assign vld = tree_vld[S][0];
    assign K = tree_pos[S][0];
endmodule
// End of lod_lzd_core.sv
