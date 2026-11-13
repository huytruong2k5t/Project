
module fp32_fma_full_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    output wire         in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    output wire         out_valid,
    input  logic        out_ready,
    output wire  [31:0] d
);
    wire clk_core;
    BUFG u_clk (.I(clk), .O(clk_core));
    wire a_rdy, b_rdy, c_rdy;
    assign in_ready = a_rdy & b_rdy & c_rdy;
    fp32_fma_full_ip u_ip (
        .aclk(clk_core),
        .aresetn(rst_n),
        .s_axis_a_tvalid(in_valid), .s_axis_a_tready(a_rdy), .s_axis_a_tdata(a),
        .s_axis_b_tvalid(in_valid), .s_axis_b_tready(b_rdy), .s_axis_b_tdata(b),
        .s_axis_c_tvalid(in_valid), .s_axis_c_tready(c_rdy), .s_axis_c_tdata(c),
        .m_axis_result_tvalid(out_valid), .m_axis_result_tready(out_ready), .m_axis_result_tdata(d)
    );
endmodule

module fp32_fma_med_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    output wire         in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    output wire         out_valid,
    input  logic        out_ready,
    output wire  [31:0] d
);
    wire clk_core;
    BUFG u_clk (.I(clk), .O(clk_core));
    wire a_rdy, b_rdy, c_rdy;
    assign in_ready = a_rdy & b_rdy & c_rdy;
    fp32_fma_med_ip u_ip (
        .aclk(clk_core),
        .aresetn(rst_n),
        .s_axis_a_tvalid(in_valid), .s_axis_a_tready(a_rdy), .s_axis_a_tdata(a),
        .s_axis_b_tvalid(in_valid), .s_axis_b_tready(b_rdy), .s_axis_b_tdata(b),
        .s_axis_c_tvalid(in_valid), .s_axis_c_tready(c_rdy), .s_axis_c_tdata(c),
        .m_axis_result_tvalid(out_valid), .m_axis_result_tready(out_ready), .m_axis_result_tdata(d)
    );
endmodule

module fp32_nf_nodsp_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    output wire         in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    output wire         out_valid,
    input  logic        out_ready,
    output wire  [31:0] d
);
    wire clk_core;
    BUFG u_clk (.I(clk), .O(clk_core));
    wire a_rdy, b_rdy, mul_v, mul_rdy, c_rdy;
    wire [31:0] prod;
    assign in_ready = a_rdy & b_rdy & c_rdy;
    fp32_mul_nodsp_ip u_mul (
        .aclk(clk_core),
        .aresetn(rst_n),
        .s_axis_a_tvalid(in_valid), .s_axis_a_tready(a_rdy), .s_axis_a_tdata(a),
        .s_axis_b_tvalid(in_valid), .s_axis_b_tready(b_rdy), .s_axis_b_tdata(b),
        .m_axis_result_tvalid(mul_v), .m_axis_result_tready(mul_rdy), .m_axis_result_tdata(prod)
    );
    fp32_add_ip u_add (
        .aclk(clk_core),
        .aresetn(rst_n),
        .s_axis_a_tvalid(mul_v), .s_axis_a_tready(mul_rdy), .s_axis_a_tdata(prod),
        .s_axis_b_tvalid(in_valid), .s_axis_b_tready(c_rdy), .s_axis_b_tdata(c),
        .m_axis_result_tvalid(out_valid), .m_axis_result_tready(out_ready), .m_axis_result_tdata(d)
    );
endmodule

