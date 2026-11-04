# Synthesis only, current snapshotted mac_active.f; no implementation/bitstream.
if {[llength $argv]!=1 || [lindex $argv 0] ni {nf f}} {error "Expected nf or f"}
set variant [lindex $argv 0]
set root [file normalize [file join [file dirname [info script]] ..]]
set part xc7a35tcpg236-1
set_param general.maxThreads 4
create_project -in_memory -part $part
set_property include_dirs [list [file join $root rtl]] [current_fileset]
set f [open [file join $root rtl mac_active.f] r]
foreach path [split [read $f] \n] {
    set path [string trim $path]
    if {$path ne {}} {read_verilog -sv [list [file join $root $path]]}
}
close $f
if {$variant eq "nf"} {set top prepack_nf_ppa_top} else {set top week13_fused_ppa_top}
read_verilog -sv [list [file join $root tb ${top}.sv]]
read_xdc [file join $root syn constraints a35t_clock.xdc]
read_xdc [file join $root syn constraints a35t_benchmark_100mhz.xdc]
synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy rebuilt -max_dsp 0 -max_bram 0
report_utilization -file synthesis_utilization.rpt
report_utilization -hierarchical -file synthesis_hierarchy.rpt
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file synthesis_timing.rpt
report_drc -file synthesis_drc.rpt
report_clocks -file clocks.rpt
write_checkpoint synthesis.dcp
write_xdc effective_constraints.xdc
set f [open status.txt w];puts $f SYNTHESIS_COMPLETE;close $f
puts "REFACTORED_MAC_SYNTHESIS_COMPLETE variant=$variant part=$part"
close_project
exit
