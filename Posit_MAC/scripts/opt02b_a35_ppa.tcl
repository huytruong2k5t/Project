# Exactly one synthesis, placement and routing of the entire NF MAC.
# Reports below are queries of this one routed netlist, not extra P&R runs.
set part xc7a35tcpg236-1
set_param general.maxThreads 4
set f [open tool.txt w]; puts $f [version]; close $f
create_project -in_memory -part $part
set src [file join [pwd] source]
set_property include_dirs [list $src] [current_fileset]
foreach path [lsort [glob [file join $src *.sv]]] {
    read_verilog -sv [list $path]
}
read_verilog -sv [list [file join [pwd] driver prepack_nf_ppa_top.sv]]
synth_design -top prepack_nf_ppa_top -part $part -mode out_of_context -flatten_hierarchy rebuilt
create_clock -name clk -period 10.000 [get_ports clk]
set_clock_uncertainty 0.100 [get_clocks clk]
set inputs [get_ports -filter {DIRECTION == IN && NAME != clk}]
set outputs [get_ports -filter {DIRECTION == OUT}]
set_input_delay -clock clk -max 2.500 $inputs
set_input_delay -clock clk -min 2.500 $inputs
set_output_delay -clock clk -max 0.500 $outputs
set_output_delay -clock clk -min 0.000 $outputs
opt_design
place_design -directive Default
route_design -directive Default
report_utilization -file utilization.rpt
report_utilization -hierarchical -file hierarchy.rpt
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -file timing.rpt
report_route_status -file route.rpt
report_drc -file drc.rpt
report_methodology -file methodology.rpt
set regs [all_registers]
set csv [open stages.csv w]
puts $csv "group,register_count,setup_slack_ns,hold_slack_ns,data_delay_ns,logic_delay_ns,route_delay_ns,levels,startpoint,endpoint"

proc report_group {name targets} {
    global regs csv
    if {![llength $targets]} {error "Empty target group: $name"}
    set setup [get_timing_paths -from $regs -to $targets -delay_type max -max_paths 1]
    set hold [get_timing_paths -from $regs -to $targets -delay_type min -max_paths 1]
    if {[llength $setup]!=1 || [llength $hold]!=1} {error "Missing timing path: $name"}
    report_timing -from $regs -to $targets -delay_type max -max_paths 10 -file ${name}_setup.rpt
    report_timing -from $regs -to $targets -delay_type min -max_paths 5 -file ${name}_hold.rpt
    set f [open ${name}_registers.txt w]
    foreach cell $targets {puts $f [get_property NAME $cell]}
    close $f
    puts $csv [join [list $name [llength $targets] \
        [get_property SLACK $setup] [get_property SLACK $hold] \
        [get_property DATAPATH_DELAY $setup] [get_property DATAPATH_LOGIC_DELAY $setup] \
        [get_property DATAPATH_NET_DELAY $setup] [get_property LOGIC_LEVELS $setup] \
        [get_property STARTPOINT_PIN $setup] [get_property ENDPOINT_PIN $setup]] ,]
    flush $csv
}

report_group whole_mac $regs
# Preceding product-P1 bank: include all D/CE setup paths to accumulator data.
report_group before_product_p1_acc [get_cells -hier -filter {IS_SEQUENTIAL && NAME =~ *u_core/u_acc/acc_reg*}]
report_group product_p1 [get_cells -hier -filter {IS_SEQUENTIAL && NAME =~ *u_product_pack/g_rne.p1_*_q_reg*}]
# Include flags and valid, not only the packed-data register.
report_group after_product_p1_p2 [get_cells -hier -filter {IS_SEQUENTIAL && (NAME =~ *u_product_pack/g_rne.d_q_reg* || NAME =~ *u_product_pack/g_rne.flags_q_reg* || NAME =~ *u_product_pack/g_rne.p2_valid_q_reg*)}]
report_group product_parse [get_cells -hier -filter {IS_SEQUENTIAL && (NAME =~ *product_frac_q_reg* || NAME =~ *norm_*_q_reg*)}]
report_group add_align [get_cells -hier -filter {IS_SEQUENTIAL && NAME =~ *u_add/a1_q_reg*}]
close $csv
set f [open structural.txt w]
puts $f "latches=[llength [get_cells -quiet -hier -filter {REF_NAME =~ LD*}]]"
puts $f "unrouted=[llength [get_nets -quiet -hier -filter {ROUTE_STATUS == UNROUTED}]]"
close $f
write_xdc measured_constraints.xdc
set f [open status.txt w]; puts $f COMPLETE; close $f
puts OPT02B_A35_PPA_COMPLETE
close_project
exit
