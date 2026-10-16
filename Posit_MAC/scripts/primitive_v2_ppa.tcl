# Explicit case list; all inputs/snapshots and outputs stay inside Posit_MAC.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root results primitive_v2_20261016]
set part [lindex $argv 0]
set phase [lindex $argv 1]
if {[llength [get_parts -quiet $part]] != 1} {error "Unavailable part $part"}
set_param general.maxThreads 4
set f [open [file join [pwd] tool.txt] w]; puts $f [version]; close $f
set cases [open [file join $out ${phase}_cases.tsv] r]
set metrics_path [file join [pwd] metrics.csv]
set finished [dict create]
if {[file exists $metrics_path]} {
    set old [open $metrics_path r]; gets $old line
    while {[gets $old line]>=0} {dict set finished [lindex [split $line ,] 0] 1};close $old
}
set csv [open $metrics_path a]
if {[file size $metrics_path]==0} {
    puts $csv "id,part,variant,n,kind,mode,arith,fill,strategy,lut,ff,slack,hold,logic_ns,route_ns,levels,latches,unrouted"
}
while {[gets $cases line]>=0} {
    if {[string trim $line] eq ""} {continue}
    lassign [split $line \t] id variant n kind mode arith fill strategy
    if {[dict exists $finished $id]} {continue}
    set case_dir [file join [pwd] $id];file mkdir $case_dir
    create_project -in_memory -part $part
    set source [file join $out source $variant]
    foreach module {lod_lzd_core dyn_left_shifter dyn_right_shifter} {
        read_verilog -sv [list [file join $source ${module}.sv]]
    }
    read_verilog -sv [list [file join $root tb primitive_v2_boundary.sv]]
    read_verilog -sv [list [file join $root tb primitive_v2_top.sv]]
    set_property include_dirs [list $source] [current_fileset]
    synth_design -top primitive_v2_top -part $part -mode out_of_context \
        -generic [list N=$n KIND=$kind MODE=$mode ARITH=$arith FILL_KIND=$fill] -flatten_hierarchy rebuilt
    create_clock -name clk -period 5.000 [get_ports clk]
    set_clock_uncertainty 0.100 [get_clocks clk]
    set inputs [get_ports -quiet {data[*] amount[*] fill_val}]
    set_input_delay -clock clk -max 2.500 $inputs
    set_input_delay -clock clk -min 2.500 $inputs
    set_output_delay -clock clk -max 0.500 [get_ports {result[*]}]
    set_output_delay -clock clk -min 0.000 [get_ports {result[*]}]
    opt_design
    if {$strategy eq "explore"} {
        place_design -directive Explore;route_design -directive Explore
    } elseif {$strategy eq "runtime"} {
        place_design -directive RuntimeOptimized;route_design -directive Default
    } else {
        place_design -directive Default;route_design -directive Default
    }
    report_utilization -file [file join $case_dir utilization.rpt]
    report_timing_summary -delay_type min_max -report_unconstrained -max_paths 3 -file [file join $case_dir timing.rpt]
    report_route_status -file [file join $case_dir route.rpt]
    set regs [all_registers]
    set setup [get_timing_paths -from $regs -to $regs -delay_type max -max_paths 1]
    set hold [get_timing_paths -from $regs -to $regs -delay_type min -max_paths 1]
    if {[llength $setup]!=1 || [llength $hold]!=1} {error "Missing R2R path $id"}
    report_timing -from $regs -to $regs -delay_type max -max_paths 3 -file [file join $case_dir setup.rpt]
    report_timing -from $regs -to $regs -delay_type min -max_paths 2 -file [file join $case_dir hold.rpt]
    set fp [open [file join $case_dir utilization.rpt] r];set util [read $fp];close $fp
    if {![regexp {\| Slice LUTs\s*\|\s*([0-9]+)} $util -> lut]} {error "No physical LUT count"}
    if {![regexp {\| Slice Registers\s*\|\s*([0-9]+)} $util -> ff]} {error "No FF count"}
    set latch [llength [get_cells -quiet -hier -filter {REF_NAME =~ LD*}]]
    set unrouted [llength [get_nets -quiet -hier -filter {ROUTE_STATUS == UNROUTED}]]
    set row [list $id $part $variant $n $kind $mode $arith $fill $strategy $lut $ff \
        [get_property SLACK $setup] [get_property SLACK $hold] \
        [get_property DATAPATH_LOGIC_DELAY $setup] [get_property DATAPATH_NET_DELAY $setup] \
        [get_property LOGIC_LEVELS $setup] $latch $unrouted]
    puts $csv [join $row ,];flush $csv
    puts "V2_PPA_DONE [join $row ,]"
    close_project
}
close $cases;close $csv
puts "V2_PPA_PHASE_COMPLETE part=$part phase=$phase"
exit
