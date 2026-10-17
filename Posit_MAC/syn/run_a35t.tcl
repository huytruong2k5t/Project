# A35T-C2 flow: nf|f benchmark_100mhz validate|synth|implement.
# Fixed 10 ns benchmark budget; no historical snapshot is modified.
if {[llength $argv] != 3} {error "Expected variant benchmark_100mhz action"}
lassign $argv variant profile action
if {$variant ni {nf f} || $profile ne "benchmark_100mhz" ||
    $action ni {validate synth implement}} {error "Unsupported flow arguments"}
set root [file normalize [file join [file dirname [info script]] ..]]
set part xc7a35tcpg236-1
set_param general.maxThreads 4
create_project -in_memory -part $part
set_property include_dirs [list [file join $root rtl]] [current_fileset]
set f [open [file join $root rtl production.f] r]
foreach path [split [read $f] \n] {
    set path [string trim $path]
    if {$path ne {}} {read_verilog -sv [list [file join $root $path]]}
}
close $f
if {$variant eq "nf"} {
    set top prepack_nf_ppa_top
    read_verilog -sv [list [file join $root tb prepack_nf_ppa_top.sv]]
} else {
    set top week13_fused_ppa_top
    read_verilog -sv [list [file join $root tb week13_fused_ppa_top.sv]]
}
# Load constraints BEFORE synthesis, so the synthesis optimizer sees the clock.
read_xdc [list [file join $root syn constraints a35t_clock.xdc]]
read_xdc [list [file join $root syn constraints a35t_benchmark_100mhz.xdc]]
if {$action eq "validate"} {
    synth_design -rtl -top $top -part $part
} else {
    synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy rebuilt
}
set clocks [get_clocks]
if {[llength $clocks] != 1 || [get_property NAME $clocks] ne "clk" ||
    abs([get_property PERIOD $clocks] - 10.0) > 0.000001} {error "Clock contract did not load"}
report_clocks -file clocks.rpt
write_xdc effective_constraints.xdc
set f [open scope.txt w]
puts $f [version]
puts $f "contract=A35T-C2 part=$part variant=$variant profile=$profile action=$action"
puts $f "clock_period_ns=10 setup_uncertainty_ns=0.100 hold_uncertainty_ns=0.100"
puts $f "NF=32/3 FW12 EXACT_EN1 OPS_EN1; F=32/3 FW12 W32 EXACT_EN0 OPS_EN1"
puts $f "No paired NF/F claim: NF EXACT_EN0 comparator still needs separate verification."
puts $f "BENCHMARK_IO_ASSUMPTIONS: input min=max 2.500 ns; output min=0.000 max=0.500 ns."
puts $f "Fixed 100 MHz benchmark budget, NOT measured board/interface timing."
puts $f "Report Internal R2R separately from assumed-budget I/O timing."
puts $f "Higher-frequency sweeps need a separate declared contract; no automatic I/O scaling."
close $f
if {$action eq "validate"} {
    set f [open status.txt w]; puts $f VALIDATED; close $f
    puts A35T_CONSTRAINTS_VALIDATED
    close_project
    exit
}
report_utilization -file synthesis_utilization.rpt
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file synthesis_timing.rpt
write_checkpoint synthesis.dcp
if {$action eq "implement"} {
    opt_design
    place_design -directive Default
    route_design -directive Default
    write_checkpoint routed.dcp
    write_xdc effective_constraints_routed.xdc
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file timing.rpt
    report_utilization -file utilization.rpt
    report_utilization -hierarchical -file hierarchy.rpt
    report_route_status -file route.rpt
    report_drc -file drc.rpt
    report_methodology -file methodology.rpt
    set targets [get_pins -of_objects [all_registers] -filter {REF_PIN_NAME == D || REF_PIN_NAME == CE}]
    report_timing -from [all_registers] -to $targets -delay_type max -max_paths 10 -file r2r_setup.rpt
    report_timing -from [all_registers] -to $targets -delay_type min -max_paths 10 -file r2r_hold.rpt
}
# COMPLETE means execution complete, not timing PASS. Inspect timing/coverage.
set f [open status.txt w]; puts $f COMPLETE; close $f
puts A35T_FLOW_COMPLETE
close_project
exit
