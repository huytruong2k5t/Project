set root [file normalize [file join [file dirname [info script]] ..]]
set part xc7a35tcpg236-1
set_param general.maxThreads 4
create_project -in_memory -part $part
set_property include_dirs [list [file join $root rtl]] [current_fileset]
set f [open [file join $root scripts week13_sources.txt] r]
foreach line [split [read $f] "\n"] {
 set line [string trim $line]
 if {$line ne ""} {read_verilog -sv [list [file join $root $line]]}
}
close $f
read_verilog -sv [list [file join $root tb week13_fused_ppa_top.sv]]
synth_design -top week13_fused_ppa_top -part $part -mode out_of_context -flatten_hierarchy rebuilt
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
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -file timing.rpt
report_utilization -file utilization.rpt
report_utilization -hierarchical -file hierarchy.rpt
report_route_status -file route.rpt
report_drc -file drc.rpt
report_methodology -file methodology.rpt
set regs [all_registers]
report_timing -from $regs -to $regs -delay_type max -max_paths 10 -path_type full_clock_expanded -file r2r_setup.rpt
report_timing -from $regs -to $regs -delay_type min -max_paths 5 -path_type full_clock_expanded -file r2r_hold.rpt
set setup [get_timing_paths -from $regs -to $regs -delay_type max -max_paths 1]
set hold [get_timing_paths -from $regs -to $regs -delay_type min -max_paths 1]
set f [open metrics.txt w]
puts $f [version]
puts $f "part=$part period_ns=10 strategy=Default"
foreach prop {SLACK DATAPATH_DELAY DATAPATH_LOGIC_DELAY DATAPATH_NET_DELAY LOGIC_LEVELS STARTPOINT_PIN ENDPOINT_PIN} {
 puts $f "setup_$prop=[get_property $prop $setup]"
}
puts $f "hold_slack=[get_property SLACK $hold]"
puts $f "latches=[llength [get_cells -hier -filter {REF_NAME =~ LD*}]]"
close $f
foreach stage {f1 f2 f3 f4 f5} {
 set dest [get_cells -quiet -hier -filter "NAME =~ *${stage}_q_reg* && IS_SEQUENTIAL"]
 if {[llength $dest]} {report_timing -to [get_pins -of_objects $dest -filter {REF_PIN_NAME == D}] -delay_type max -max_paths 3 -file ${stage}.rpt}
}
puts W13_PPA_COMPLETE
exit
