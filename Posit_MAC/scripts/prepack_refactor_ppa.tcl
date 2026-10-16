# OPT-01 only: whole NF32/3, same features/part/clock/directive per pair.
set root [file normalize [file join [file dirname [info script]] ..]]
set study [file join $root results prepack_refactor_20261016]
set part [lindex $argv 0]
set_param general.maxThreads 4
set f [open tool.txt w]; puts $f [version]; close $f
set csv [open metrics.csv w]
puts $csv "variant,strategy,lut,ff,carry4,dsp,bram,slack,hold,delay_ns,logic_ns,route_ns,levels,latches,unrouted,norm_slack,norm_delay_ns"
foreach variant {baseline candidate} {
    foreach strategy {default explore runtime} {
        set id ${variant}_${strategy}
        set dir [file join [pwd] $id]; file mkdir $dir
        create_project -in_memory -part $part
        set src [file join $study source baseline]
        set_property include_dirs [list $src] [current_fileset]
        foreach path [lsort [glob [file join $src *.sv]]] {
            if {$variant eq "candidate" && [file tail $path] eq "mul_prepack_norm_comb.sv"} {
                set path [file join $study source candidate mul_prepack_norm_comb.sv]
            }
            read_verilog -sv [list $path]
        }
        read_verilog -sv [list [file join $root tb prepack_nf_ppa_top.sv]]
        synth_design -top prepack_nf_ppa_top -part $part -mode out_of_context -flatten_hierarchy rebuilt
        create_clock -name clk -period 10.000 [get_ports clk]
        set_clock_uncertainty 0.100 [get_clocks clk]
        set inputs [get_ports -filter {DIRECTION == IN && NAME != clk}]
        set outputs [get_ports -filter {DIRECTION == OUT}]
        set_input_delay -clock clk -max 2.500 $inputs
        set_input_delay -clock clk -min 2.500 $inputs
        set_output_delay -clock clk -max 0.500 $outputs
        set_output_delay -clock clk -min 0.000 $outputs
        opt_design
        if {$strategy eq "explore"} {
            place_design -directive Explore; route_design -directive Explore
        } elseif {$strategy eq "runtime"} {
            place_design -directive RuntimeOptimized; route_design -directive Default
        } else {
            place_design -directive Default; route_design -directive Default
        }
        report_utilization -hierarchical -file [file join $dir hierarchy.rpt]
        report_utilization -file [file join $dir utilization.rpt]
        report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -file [file join $dir timing.rpt]
        report_route_status -file [file join $dir route.rpt]
        report_drc -file [file join $dir drc.rpt]
        report_methodology -file [file join $dir methodology.rpt]
        set regs [all_registers]
        set setup [get_timing_paths -from $regs -to $regs -delay_type max -max_paths 1]
        set hold [get_timing_paths -from $regs -to $regs -delay_type min -max_paths 1]
        set targets [get_cells -hier -filter {IS_SEQUENTIAL && (NAME =~ *product_frac_q_reg* || NAME =~ *norm_sf_q_reg*)}]
        if {![llength $targets]} {error "Missing norm/product bank"}
        set norm [get_timing_paths -from $regs -to $targets -max_paths 1]
        if {[llength $setup]!=1 || [llength $hold]!=1 || [llength $norm]!=1} {error "Missing R2R path"}
        report_timing -from $regs -to $regs -delay_type max -max_paths 10 -file [file join $dir setup.rpt]
        report_timing -from $regs -to $regs -delay_type min -max_paths 5 -file [file join $dir hold.rpt]
        report_timing -from $regs -to $targets -max_paths 5 -file [file join $dir norm_round.rpt]
        foreach {name pattern} {add_align *u_add*a1_q_reg* add_arith *u_add*a2_q_reg* pack_p1 *u_pack*p1_*_q_reg* parser *p1_cnt_q_reg* sac *u_ctrl*fx_q_reg*} {
            set stage_regs [get_cells -quiet -hier -filter "IS_SEQUENTIAL && NAME =~ $pattern"]
            if {[llength $stage_regs]} {
                report_timing -from $regs -to $stage_regs -max_paths 3 -file [file join $dir stage_${name}.rpt]
            }
        }
        set f [open [file join $dir endpoints.txt] w]
        foreach prop {STARTPOINT_PIN ENDPOINT_PIN} {
            puts $f "global_$prop=[get_property $prop $setup]"
            puts $f "norm_$prop=[get_property $prop $norm]"
        }
        close $f
        set f [open [file join $dir utilization.rpt] r]; set util [read $f]; close $f
        if {![regexp {\| Slice LUTs\s*\|\s*([0-9]+)} $util -> lut]} {error "Missing LUT"}
        if {![regexp {\| Slice Registers\s*\|\s*([0-9]+)} $util -> ff]} {error "Missing FF"}
        set carry [llength [get_cells -quiet -hier -filter {REF_NAME == CARRY4}]]
        set dsp [llength [get_cells -quiet -hier -filter {REF_NAME =~ DSP*}]]
        set bram [llength [get_cells -quiet -hier -filter {REF_NAME =~ RAMB*}]]
        set latches [llength [get_cells -quiet -hier -filter {REF_NAME =~ LD*}]]
        set unrouted [llength [get_nets -quiet -hier -filter {ROUTE_STATUS == UNROUTED}]]
        puts $csv [join [list $variant $strategy $lut $ff $carry $dsp $bram \
            [get_property SLACK $setup] [get_property SLACK $hold] [get_property DATAPATH_DELAY $setup] \
            [get_property DATAPATH_LOGIC_DELAY $setup] [get_property DATAPATH_NET_DELAY $setup] \
            [get_property LOGIC_LEVELS $setup] $latches $unrouted [get_property SLACK $norm] \
            [get_property DATAPATH_DELAY $norm]] ,]
        flush $csv
        puts "PREPACK_PPA_DONE $part $id"
        close_project
    }
}
close $csv
puts PREPACK_PPA_COMPLETE
exit
