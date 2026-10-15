# Usage: vivado -mode batch -source <this> -tclargs <part> [smoke]
# The process working directory and all output files must be in Posit_MAC.
set root [file normalize [file join [file dirname [info script]] ..]]
set output [file join $root results primitive_xilinx_20261015]
set part [lindex $argv 0]
if {[llength [get_parts -quiet $part]] != 1} { error "Unavailable part: $part" }
set smoke [expr {[lindex $argv 1] eq "smoke"}]
set_param general.maxThreads 4
set fp [open [file join [pwd] tool.txt] w]
puts $fp [version]
puts $fp [help place_design]
puts $fp [help route_design]
close $fp
set csv_path [file join [pwd] measurements.csv]
set completed [dict create]
if {[file exists $csv_path]} {
    set old [open $csv_path r]
    gets $old header
    while {[gets $old line] >= 0} {
        set fields [split $line ,]
        if {[llength $fields] == 16} {
            dict set completed [lrange $fields 0 4] 1
        }
    }
    close $old
}
set csv [open $csv_path a]
if {[file size $csv_path] == 0} {
    puts $csv "part,variant,n,kind,strategy,period_ns,r2r_setup_slack_ns,r2r_hold_slack_ns,r2r_logic_ns,r2r_route_ns,lut_cells,ff,carry4,dsp,bram,logic_levels"
}
flush $csv

set widths {26 12 32}
if {$smoke} { set widths {12} }
foreach n $widths {
    foreach kind {0 1 2} {
        foreach variant {baseline candidate} {
            set case_dir [file join [pwd] ${variant}_n${n}_k${kind}]
            file mkdir $case_dir
            create_project -in_memory -part $part
            set checkpoint [file join $case_dir optimized.dcp]
            if {[file exists $checkpoint]} {
                open_checkpoint $checkpoint
            } else {
            set src_dir [file join $output source $variant]
            foreach module {dyn_left_shifter dyn_right_shifter lod_lzd_core} {
                read_verilog -sv [list [file join $src_dir ${module}.sv]]
            }
            set_property include_dirs [list $src_dir] [current_fileset]
            read_verilog -sv [list [file join $src_dir primitive_ppa_boundary.sv]]
            read_verilog -sv [list [file join $src_dir primitive_ppa_top.sv]]
            synth_design -top primitive_ppa_top -part $part -mode out_of_context \
                -generic [list N=$n KIND=$kind] -flatten_hierarchy rebuilt
            create_clock -name clk -period 5.000 [get_ports clk]
            set_clock_uncertainty 0.100 [get_clocks clk]
            set inputs [get_ports -quiet {data[*] amount[*] fill_val}]
            # Synthetic boundary I/O contract, not a board pin interface.
            # Calibrated in the smoke run before any candidate measurement.
            # All functional R2R paths retain the full, single-cycle clock.
            set_input_delay -clock clk -max 2.500 $inputs
            set_input_delay -clock clk -min 2.500 $inputs
            set_output_delay -clock clk -max 0.500 [get_ports {result[*]}]
            set_output_delay -clock clk -min 0.000 [get_ports {result[*]}]
            opt_design
            write_checkpoint -force [file join $case_dir optimized.dcp]
            }
            close_design
            foreach strategy {default explore runtime} {
                set key [list $part $variant $n $kind $strategy]
                if {[dict exists $completed $key]} { continue }
                open_checkpoint $checkpoint
                set run_dir [file join $case_dir $strategy]
                file mkdir $run_dir
                if {$strategy eq "default"} {
                    place_design -directive Default
                    route_design -directive Default
                } elseif {$strategy eq "explore"} {
                    place_design -directive Explore
                    route_design -directive Explore
                } else {
                    place_design -directive RuntimeOptimized
                    route_design -directive Default
                }
                report_timing_summary -delay_type min_max -report_unconstrained \
                    -check_timing_verbose -max_paths 10 -file [file join $run_dir timing.rpt]
                report_utilization -file [file join $run_dir utilization.rpt]
                report_utilization -hierarchical -file [file join $run_dir hierarchy.rpt]
                report_route_status -file [file join $run_dir route.rpt]
                report_drc -file [file join $run_dir drc.rpt]
                set regs [all_registers]
                set setup [get_timing_paths -from $regs -to $regs -delay_type max -max_paths 1]
                set hold [get_timing_paths -from $regs -to $regs -delay_type min -max_paths 1]
                if {[llength $setup] != 1 || [llength $hold] != 1} {
                    error "Missing R2R timing paths"
                }
                report_timing -from $regs -to $regs -delay_type max -max_paths 5 \
                    -path_type full_clock_expanded -file [file join $run_dir r2r_setup.rpt]
                report_timing -from $regs -to $regs -delay_type min -max_paths 5 \
                    -path_type full_clock_expanded -file [file join $run_dir r2r_hold.rpt]
                set metrics [list $part $variant $n $kind $strategy 5.0 \
                    [get_property SLACK $setup] [get_property SLACK $hold] \
                    [get_property DATAPATH_LOGIC_DELAY $setup] \
                    [get_property DATAPATH_NET_DELAY $setup]]
                foreach filter {{REF_NAME =~ LUT*} {REF_NAME =~ FD*} {REF_NAME == CARRY4} \
                    {REF_NAME =~ DSP*} {REF_NAME =~ RAMB*}} {
                    lappend metrics [llength [get_cells -quiet -hierarchical -filter $filter]]
                }
                lappend metrics [get_property LOGIC_LEVELS $setup]
                puts $csv [join $metrics ,]
                flush $csv
                puts "PPA_DONE [join $metrics ,]"
                if {$smoke} { close $csv; exit }
                close_design
            }
            close_project
        }
    }
}
close $csv
exit
