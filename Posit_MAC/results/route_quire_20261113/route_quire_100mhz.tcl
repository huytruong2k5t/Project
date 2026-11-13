# Matched MAC-Quire out-of-context implementation with the 100 MHz benchmark XDCs on 12/11 snapshot.
set run_dir [file normalize [file dirname [info script]]]
set root [file join $run_dir source]
set part xc7a35tcpg236-1
set_param general.maxThreads 4
create_project -in_memory -part $part
set_property include_dirs [list [file join $root rtl]] [current_fileset]
set list_file [open [file join $root rtl quire_active.f] r]
set rtl [split [read $list_file] \n]
close $list_file
foreach path $rtl {
    set path [string trim $path]
    if {$path ne {}} {read_verilog -sv [list [file join $root $path]]}
}
set top quire_ppa_top
read_verilog -sv [list [file join $root tb ${top}.sv]]
read_xdc [list [file join $root syn constraints a35t_clock.xdc]]
read_xdc [list [file join $root syn constraints a35t_benchmark_100mhz.xdc]]

synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy rebuilt -max_dsp 0 -max_bram 0
set clocks [get_clocks]
if {[llength $clocks] != 1 || [get_property NAME $clocks] ne "clk" ||
    abs([get_property PERIOD $clocks] - 10.0) > 0.000001} {error "Clock contract did not load"}

report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file "$run_dir/synthesis_timing.rpt"
report_utilization -file "$run_dir/synthesis_utilization.rpt"
report_timing -delay_type max -nworst 1 -max_paths 5 -file "$run_dir/synthesis_worst_setup_all.rpt"
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type max -nworst 1 -max_paths 5 -file "$run_dir/synthesis_reg2reg_setup_clk.rpt"
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type min -nworst 1 -max_paths 5 -file "$run_dir/synthesis_reg2reg_hold_clk.rpt"
write_checkpoint -force "$run_dir/synthesis.dcp"

proc dump_stage {tag run_dir} {
    set p_all_max [get_timing_paths -delay_type max -nworst 1 -max_paths 1]
    set p_all_min [get_timing_paths -delay_type min -nworst 1 -max_paths 1]
    set p_r2r_clk_max [get_timing_paths -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type max -nworst 1 -max_paths 1]
    set p_r2r_any_max [get_timing_paths -from [all_registers -clock_pins] -to [all_registers -data_pins] -delay_type max -nworst 1 -max_paths 1]
    set p_r2r_clk_min [get_timing_paths -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type min -nworst 1 -max_paths 1]
    set fp [open "$run_dir/${tag}_metrics.txt" w]
    foreach {lbl p} [list \
        "ALL_SETUP" $p_all_max \
        "ALL_HOLD" $p_all_min \
        "REG2REG_CLK_SETUP" $p_r2r_clk_max \
        "REG2REG_ANY_SETUP" $p_r2r_any_max \
        "REG2REG_CLK_HOLD" $p_r2r_clk_min \
    ] {
        if {[llength $p] > 0} {
            set sl [get_property SLACK $p]
            set req [get_property REQUIREMENT $p]
            set dp [get_property DATAPATH_DELAY $p]
            set lv [get_property LOGIC_LEVELS $p]
            set grp [get_property GROUP $p]
            set sp [get_property STARTPOINT_PIN $p]
            set ep [get_property ENDPOINT_PIN $p]
            puts $fp "$lbl|slack=$sl|req=$req|datapath=$dp|levels=$lv|group=$grp|start=$sp|end=$ep"
        } else {
            puts $fp "$lbl|EMPTY"
        }
    }
    close $fp
}

dump_stage "synth" $run_dir

opt_design
place_design -directive Default
route_design -directive Default
write_checkpoint -force "$run_dir/routed.dcp"
write_xdc -force "$run_dir/effective_constraints_routed.xdc"
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file "$run_dir/route_timing.rpt"
report_timing -delay_type min_max -max_paths 10 -file "$run_dir/route_paths.rpt"
report_timing -delay_type max -nworst 1 -max_paths 5 -file "$run_dir/route_worst_setup_all.rpt"
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type max -nworst 1 -max_paths 5 -file "$run_dir/route_reg2reg_setup_clk.rpt"
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type min -nworst 1 -max_paths 5 -file "$run_dir/route_reg2reg_hold_clk.rpt"
report_route_status -file "$run_dir/route_status.rpt"
report_utilization -file "$run_dir/route_utilization.rpt"
report_drc -file "$run_dir/route_drc.rpt"
dump_stage "route" $run_dir

puts "QUIRE_ROUTE_COMPLETE part=$part period_ns=10"
close_project
exit
