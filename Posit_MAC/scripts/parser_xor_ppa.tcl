# Matched parser OOC study. No full-MAC or board-frequency claim.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root results parser_xor_20261016]
set part [lindex $argv 0]
set_param general.maxThreads 4
set f [open tool.txt w]; puts $f [version]; close $f
set csv [open metrics.csv w]
puts $csv "variant,part,es,strategy,lut,ff,slack,hold,logic_ns,route_ns,levels,latches,unrouted"
foreach es {2 3} {
    foreach variant {baseline xor} {
        foreach strategy {default explore runtime} {
            set id ${variant}_es${es}_${strategy}
            set dir [file join [pwd] $id]; file mkdir $dir
            create_project -in_memory -part $part
            set src [file join $out source $variant]
            set_property include_dirs [list $src] [current_fileset]
            foreach name {lod_lzd_core dyn_left_shifter posit_parser} {
                read_verilog -sv [list [file join $src ${name}.sv]]
            }
            read_verilog -sv [list [file join $root tb parser_xor_ppa_top.sv]]
            synth_design -top parser_xor_ppa_top -part $part -mode out_of_context \
                -generic [list ES=$es] -flatten_hierarchy rebuilt
            create_clock -name clk -period 5.000 [get_ports clk]
            set_clock_uncertainty 0.100 [get_clocks clk]
            set inputs [get_ports {p[*] in_valid out_ready}]
            set_input_delay -clock clk -max 2.500 $inputs
            set_input_delay -clock clk -min 2.500 $inputs
            set outputs [get_ports {in_ready out_valid s is_zero is_nar sf[*] frac[*]}]
            set_output_delay -clock clk -max 0.500 $outputs
            set_output_delay -clock clk -min 0.000 $outputs
            # Only external asynchronous reset is excluded; synchronizer-to-bank
            # reset recovery/removal and all data/control paths remain timed.
            set_false_path -from [get_ports reset_n]
            opt_design
            if {$strategy eq "explore"} {
                place_design -directive Explore; route_design -directive Explore
            } elseif {$strategy eq "runtime"} {
                place_design -directive RuntimeOptimized; route_design -directive Default
            } else {
                place_design -directive Default; route_design -directive Default
            }
            report_utilization -file [file join $dir utilization.rpt]
            report_timing_summary -delay_type min_max -report_unconstrained -max_paths 3 -file [file join $dir timing.rpt]
            report_route_status -file [file join $dir route.rpt]
            set regs [all_registers]
            set input_regs [get_cells -hier -filter {NAME =~ *p_q_reg*}]
            set p1 [get_timing_paths -from $input_regs -to $regs -max_paths 1]
            set p2 [get_timing_paths -from $regs -to $regs -max_paths 1]
            set hold [get_timing_paths -from $input_regs -to $regs -delay_type min -max_paths 1]
            if {[llength $p1]!=1 || [llength $p2]!=1} {error "Missing timing paths"}
            report_timing -from $input_regs -to $regs -max_paths 3 -file [file join $dir p1.rpt]
            report_timing -from $regs -to $regs -max_paths 3 -file [file join $dir p2.rpt]
            set f [open [file join $dir p2_slack.txt] w]; puts $f [get_property SLACK $p2]; close $f
            set f [open [file join $dir utilization.rpt] r]; set util [read $f]; close $f
            if {![regexp {\| Slice LUTs\s*\|\s*([0-9]+)} $util -> lut]} {error "Missing physical LUT count"}
            if {![regexp {\| Slice Registers\s*\|\s*([0-9]+)} $util -> ff]} {error "Missing FF count"}
            set latches [llength [get_cells -quiet -hier -filter {REF_NAME =~ LD*}]]
            set unrouted [llength [get_nets -quiet -hier -filter {ROUTE_STATUS == UNROUTED}]]
            puts $csv [join [list $variant $part $es $strategy $lut $ff \
                [get_property SLACK $p1] [get_property SLACK $hold] \
                [get_property DATAPATH_LOGIC_DELAY $p1] [get_property DATAPATH_NET_DELAY $p1] \
                [get_property LOGIC_LEVELS $p1] $latches $unrouted] ,]
            flush $csv
            puts "PARSER_XOR_PPA_DONE $part $id"
            close_project
        }
    }
}
close $csv
puts PARSER_XOR_PPA_COMPLETE
exit
