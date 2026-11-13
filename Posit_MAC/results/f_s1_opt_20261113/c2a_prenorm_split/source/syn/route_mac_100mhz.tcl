# Matched NF/F out-of-context implementation with the 100 MHz benchmark XDCs.
if {[llength $argv] != 1 || [lindex $argv 0] ni {nf f}} {error "Expected nf or f"}
set variant [lindex $argv 0]
set root [file normalize [file join [file dirname [info script]] ..]]
set part xc7a35tcpg236-1
set_param general.maxThreads 4
create_project -in_memory -part $part
set_property include_dirs [list [file join $root rtl]] [current_fileset]
set list_file [open [file join $root rtl mac_active.f] r]
set rtl [split [read $list_file] \n]
close $list_file
foreach path $rtl {
    set path [string trim $path]
    if {$path ne {}} {read_verilog -sv [list [file join $root $path]]}
}
if {$variant eq "nf"} {set top prepack_nf_ppa_top} else {set top week13_fused_ppa_top}
read_verilog -sv [list [file join $root tb ${top}.sv]]
read_xdc [list [file join $root syn constraints a35t_clock.xdc]]
read_xdc [list [file join $root syn constraints a35t_benchmark_100mhz.xdc]]
synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy rebuilt -max_dsp 0 -max_bram 0
set clocks [get_clocks]
if {[llength $clocks] != 1 || [get_property NAME $clocks] ne "clk" ||
    abs([get_property PERIOD $clocks] - 10.0) > 0.000001} {error "Clock contract did not load"}
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file synthesis_timing.rpt
report_utilization -file synthesis_utilization.rpt
write_checkpoint synthesis.dcp
opt_design
place_design -directive Default
route_design -directive Default
write_checkpoint routed.dcp
write_xdc effective_constraints_routed.xdc
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file route_timing.rpt
report_timing -delay_type min_max -max_paths 10 -file route_paths.rpt
report_route_status -file route_status.rpt
report_utilization -file route_utilization.rpt
report_drc -file route_drc.rpt
puts "MAC_ROUTE_COMPLETE variant=$variant part=$part period_ns=10"
close_project
exit
