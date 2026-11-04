# Matched A35T synthesis only. Clock and I/O constraints precede synthesis.
set root [file normalize [lindex $argv 0]]
set_param general.maxThreads 4
create_project -in_memory -part xc7a35tcpg236-1
set_property include_dirs [list [file join $root rtl]] [current_fileset]
set handle [open [file join $root rtl quire_active.f] r]
foreach path [split [read $handle] \n] {
    set path [string trim $path]
    if {$path ne {}} {read_verilog -sv [list [file join $root $path]]}
}
close $handle
read_verilog -sv [list [file join $root tb quire_ppa_top.sv]]
read_xdc [list [file join $root syn constraints a35t_clock.xdc]]
read_xdc [list [file join $root syn constraints a35t_benchmark_100mhz.xdc]]
synth_design -top quire_ppa_top -part xc7a35tcpg236-1 -mode out_of_context -flatten_hierarchy rebuilt -max_dsp 0 -max_bram 0
report_utilization -file synthesis_utilization.rpt
report_utilization -hierarchical -file synthesis_hierarchy.rpt
report_timing_summary -delay_type min_max -report_unconstrained -file synthesis_timing.rpt
write_checkpoint synthesis.dcp
write_xdc effective_constraints.xdc
source [file join $root syn report_quire_f2f.tcl]
set handle [open status.txt w];puts $handle SYNTHESIS_COMPLETE;close $handle
puts QUIRE_SYNTHESIS_ONLY_COMPLETE
close_project
exit
