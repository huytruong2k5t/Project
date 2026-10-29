# Matched FULL_TERM OOC: one synthesis, three placement/routing strategies.
# Current directory is results/opt17_20261029/ppa/<top>, isolated by the PS runner.
set_param general.maxThreads 4
set part xc7a35tcpg236-1
set period 8.300
create_project -in_memory -part $part
set_property include_dirs [list [file normalize source/rtl]] [current_fileset]
foreach source [lsort [glob source/rtl/*.sv]] {
    read_verilog -sv [list $source]
}
read_verilog -sv [list source/opt17_ppa_top.sv]
# Load the identical XDC before synthesis; do not query ports before elaboration.
read_xdc source/matched.xdc
synth_design -top opt17_ppa_top -part $part -mode out_of_context -flatten_hierarchy rebuilt
report_utilization -file synthesis_utilization.rpt
report_timing_summary -delay_type min_max -report_unconstrained -file synthesis_timing.rpt
write_checkpoint synthesis.dcp
set log [open version.txt w]
puts $log [version]
close $log
set csv [open summary.csv w]
puts $csv "strategy,lut,ff,carry4,dsp,bram,latches,wns,tns,whs,ths,r2r_setup,r2r_hold,unrouted"
flush $csv
close_project
foreach strategy {Default Explore RuntimeOptimized} {
    file mkdir $strategy
    open_checkpoint synthesis.dcp
    opt_design
    place_design -directive $strategy
    if {$strategy eq "RuntimeOptimized"} {
        route_design -directive Default
    } else {
        route_design -directive $strategy
    }
    report_utilization -file $strategy/utilization.rpt
    report_utilization -hierarchical -file $strategy/hierarchy.rpt
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -file $strategy/timing.rpt
    report_route_status -file $strategy/route.rpt
    report_drc -file $strategy/drc.rpt
    report_methodology -file $strategy/methodology.rpt
    report_cdc -details -file $strategy/cdc.rpt
    set regs [all_registers]
    set global_setup [get_timing_paths -delay_type max -max_paths 1]
    set global_hold [get_timing_paths -delay_type min -max_paths 1]
    set r2r_setup [get_timing_paths -from $regs -to $regs -delay_type max -max_paths 1]
    set r2r_hold [get_timing_paths -from $regs -to $regs -delay_type min -max_paths 1]
    if {[llength $global_setup]!=1 || [llength $global_hold]!=1 || [llength $r2r_setup]!=1 || [llength $r2r_hold]!=1} {
        error "Missing timing paths"
    }
    report_timing -from $regs -to $regs -delay_type max -max_paths 5 -file $strategy/r2r_setup.rpt
    report_timing -from $regs -to $regs -delay_type min -max_paths 5 -file $strategy/r2r_hold.rpt
    set f [open $strategy/utilization.rpt r]
    set util [read $f]
    close $f
    if {![regexp {\| Slice LUTs\s*\|\s*([0-9]+)} $util -> lut]} {error "Missing LUT count"}
    if {![regexp {\| Slice Registers\s*\|\s*([0-9]+)} $util -> ff]} {error "Missing FF count"}
    set f [open $strategy/timing.rpt r]
    set timing [read $f]
    close $f
    if {![regexp {WNS\(ns\)\s+TNS\(ns\)[^\n]*\n[^\n]*\n\s*([-0-9.]+)\s+([-0-9.]+)\s+[0-9]+\s+[0-9]+\s+([-0-9.]+)\s+([-0-9.]+)} $timing -> wns tns whs ths]} {
        error "Timing summary parse failed; keep raw reports"
    }
    set carry [llength [get_cells -quiet -hier -filter {REF_NAME == CARRY4}]]
    set dsp [llength [get_cells -quiet -hier -filter {REF_NAME =~ DSP*}]]
    set bram [llength [get_cells -quiet -hier -filter {REF_NAME =~ RAMB*}]]
    set latches [llength [get_cells -quiet -hier -filter {REF_NAME =~ LD*}]]
    set unrouted [llength [get_nets -quiet -hier -filter {ROUTE_STATUS == UNROUTED}]]
    puts $csv [join [list $strategy $lut $ff $carry $dsp $bram $latches $wns $tns $whs $ths \
        [get_property SLACK $r2r_setup] [get_property SLACK $r2r_hold] $unrouted] ,]
    flush $csv
    puts "OPT17_PPA_DONE $strategy wns=$wns whs=$whs"
    close_project
}
close $csv
set f [open status.txt w]
puts $f COMPLETE
close $f
puts OPT17_PPA_COMPLETE
exit
