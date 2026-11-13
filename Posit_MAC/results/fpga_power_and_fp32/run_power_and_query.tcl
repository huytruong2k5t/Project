set root "C:/HCMUT/HK261/Do an 2/Posit_MAC"
set out_dir "$root/results/fpga_power_and_fp32"
file mkdir $out_dir

# 1. Power reports on mac_f, mac_nf, mac_quire routed checkpoints
set targets [list \
    "mac_f"     "$root/results/f_s1_opt_20261113/c1a_split_only/vivado_f/routed.dcp" \
    "mac_nf"    "$root/results/f_s1_opt_20261113/c1a_split_only/vivado_nf/routed.dcp" \
    "mac_quire" "$root/results/route_quire_20261113/routed.dcp" \
]

foreach {name dcp} $targets {
    open_checkpoint $dcp
    report_power -file "$out_dir/${name}_power.rpt"
    report_utilization -file "$out_dir/${name}_util.rpt"
    close_project
}

# 2. Query Xilinx floating_point IP properties
create_project -in_memory -part xc7a35tcpg236-1
set ipdef [get_ipdefs -all *floating_point*]
puts "IPDEFS: $ipdef"
create_ip -name floating_point -vendor xilinx.com -library ip -module_name fp_test
set fp [open "$out_dir/fp_ip_props.txt" w]
foreach p [lsort [list_property [get_ips fp_test] CONFIG.*]] {
    puts $fp "$p = [get_property $p [get_ips fp_test]]"
}
close $fp
close_project
puts "POWER_AND_QUERY_DONE"
exit
