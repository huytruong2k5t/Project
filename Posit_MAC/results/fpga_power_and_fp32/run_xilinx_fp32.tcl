set root "C:/HCMUT/HK261/DOAN2~1/Posit_MAC"
set out_dir "$root/results/fpga_power_and_fp32"
file mkdir $out_dir
set ip_proj "$out_dir/ip_build"
file delete -force $ip_proj
create_project fp32_bench $ip_proj -part xc7a35tcpg236-1 -force

# Variant 1: Xilinx FP32 FMA Full_Usage (DSP)
create_ip -name floating_point -vendor xilinx.com -library ip -module_name fp32_fma_full_ip
set_property -dict [list \
    CONFIG.Operation_Type {FMA} \
    CONFIG.Add_Sub_Value {Add} \
    CONFIG.A_Precision_Type {Single} \
    CONFIG.Result_Precision_Type {Single} \
    CONFIG.Flow_Control {Blocking} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Has_RESULT_TREADY {true} \
    CONFIG.C_Mult_Usage {Full_Usage} \
    CONFIG.C_Optimization {Speed_Optimized} \
] [get_ips fp32_fma_full_ip]
generate_target synthesis [get_ips fp32_fma_full_ip]

# Variant 2: Xilinx FP32 FMA Medium_Usage (DSP)
create_ip -name floating_point -vendor xilinx.com -library ip -module_name fp32_fma_med_ip
set_property -dict [list \
    CONFIG.Operation_Type {FMA} \
    CONFIG.Add_Sub_Value {Add} \
    CONFIG.A_Precision_Type {Single} \
    CONFIG.Result_Precision_Type {Single} \
    CONFIG.Flow_Control {Blocking} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Has_RESULT_TREADY {true} \
    CONFIG.C_Mult_Usage {Medium_Usage} \
    CONFIG.C_Optimization {Speed_Optimized} \
] [get_ips fp32_fma_med_ip]
generate_target synthesis [get_ips fp32_fma_med_ip]

# Variant 3: Xilinx FP32 0-DSP Non-Fused MAC (Multiply No_Usage -> Add_Subtract)
create_ip -name floating_point -vendor xilinx.com -library ip -module_name fp32_mul_nodsp_ip
set_property -dict [list \
    CONFIG.Operation_Type {Multiply} \
    CONFIG.A_Precision_Type {Single} \
    CONFIG.Result_Precision_Type {Single} \
    CONFIG.Flow_Control {Blocking} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Has_RESULT_TREADY {true} \
    CONFIG.C_Mult_Usage {No_Usage} \
    CONFIG.C_Optimization {Speed_Optimized} \
] [get_ips fp32_mul_nodsp_ip]
generate_target synthesis [get_ips fp32_mul_nodsp_ip]

create_ip -name floating_point -vendor xilinx.com -library ip -module_name fp32_add_ip
set_property -dict [list \
    CONFIG.Operation_Type {Add_Subtract} \
    CONFIG.Add_Sub_Value {Add} \
    CONFIG.A_Precision_Type {Single} \
    CONFIG.Result_Precision_Type {Single} \
    CONFIG.Flow_Control {Blocking} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Has_RESULT_TREADY {true} \
    CONFIG.C_Mult_Usage {No_Usage} \
    CONFIG.C_Optimization {Speed_Optimized} \
] [get_ips fp32_add_ip]
generate_target synthesis [get_ips fp32_add_ip]

puts "LAT_FMA_FULL=[get_property CONFIG.C_Latency [get_ips fp32_fma_full_ip]]"
puts "LAT_FMA_MED=[get_property CONFIG.C_Latency [get_ips fp32_fma_med_ip]]"
puts "LAT_MUL_NODSP=[get_property CONFIG.C_Latency [get_ips fp32_mul_nodsp_ip]]"
puts "LAT_ADD=[get_property CONFIG.C_Latency [get_ips fp32_add_ip]]"

# IP RTL targets already generated; synth_design will compile each IP cleanly during run_impl
close_project

# Top wrapper RTL file for the 3 benchmarks
set wrap_sv "$out_dir/fp32_bench_tops.sv"
set fp [open $wrap_sv w]
puts $fp {
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
}
close $fp

proc run_impl {tag top_name ip_xcis root out_dir ip_proj wrap_sv} {
    create_project -in_memory -part xc7a35tcpg236-1
    read_verilog -sv [list $wrap_sv]
    foreach x $ip_xcis {
        read_ip [list "$ip_proj/fp32_bench.srcs/sources_1/ip/$x/${x}.xci"]
        generate_target synthesis [get_ips $x]
        synth_ip [get_ips $x]
    }
    read_xdc [list "$root/syn/constraints/a35t_clock.xdc" "$root/syn/constraints/a35t_benchmark_100mhz.xdc"]
    synth_design -top $top_name -part xc7a35tcpg236-1 -mode out_of_context -flatten_hierarchy rebuilt
    opt_design
    place_design -directive Default
    route_design -directive Default
    report_utilization -file "$out_dir/${tag}_util.rpt"
    report_timing_summary -delay_type min_max -max_paths 5 -file "$out_dir/${tag}_timing.rpt"
    report_power -file "$out_dir/${tag}_power.rpt"
    set p_all [get_timing_paths -delay_type max -nworst 1 -max_paths 1]
    set p_r2r [get_timing_paths -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type max -nworst 1 -max_paths 1]
    set f [open "$out_dir/${tag}_metrics.txt" w]
    puts $f "ALL_WNS=[get_property SLACK $p_all]"
    if {[llength $p_r2r] > 0} {
        puts $f "R2R_WNS=[get_property SLACK $p_r2r]"
    }
    close $f
    close_project
}

run_impl "fp32_fma_full"  "fp32_fma_full_top"  [list fp32_fma_full_ip]            $root $out_dir $ip_proj $wrap_sv
run_impl "fp32_fma_med"   "fp32_fma_med_top"   [list fp32_fma_med_ip]             $root $out_dir $ip_proj $wrap_sv
run_impl "fp32_nf_nodsp"  "fp32_nf_nodsp_top"  [list fp32_mul_nodsp_ip fp32_add_ip] $root $out_dir $ip_proj $wrap_sv
puts "XILINX_FP32_ALL_DONE"
exit
