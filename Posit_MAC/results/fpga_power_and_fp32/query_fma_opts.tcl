create_project -in_memory -part xc7a35tcpg236-1
create_ip -name floating_point -vendor xilinx.com -library ip -module_name fp_fma
puts "OP_TYPE_RANGE: [list_property_value CONFIG.Operation_Type [get_ips fp_fma]]"
puts "MULT_USAGE_RANGE: [list_property_value CONFIG.C_Mult_Usage [get_ips fp_fma]]"
set_property -dict [list CONFIG.Operation_Type {FMA} CONFIG.Add_Sub_Value {Add} CONFIG.A_Precision_Type {Single} CONFIG.Result_Precision_Type {Single} CONFIG.Flow_Control {Blocking} CONFIG.Has_ARESETn {true} CONFIG.Has_RESULT_TREADY {true} CONFIG.C_Optimization {Speed_Optimized}] [get_ips fp_fma]
puts "FMA_FULL_LAT: [get_property CONFIG.C_Latency [get_ips fp_fma]]"
puts "FMA_FULL_MULT: [get_property CONFIG.C_Mult_Usage [get_ips fp_fma]]"
set_property -dict [list CONFIG.C_Mult_Usage {No_Usage}] [get_ips fp_fma]
puts "FMA_NO_DSP_LAT: [get_property CONFIG.C_Latency [get_ips fp_fma]]"
puts "FMA_NO_DSP_MULT: [get_property CONFIG.C_Mult_Usage [get_ips fp_fma]]"
close_project
exit
