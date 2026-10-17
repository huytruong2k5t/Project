# One whole-NF implementation, then report every physical register bank.
# Input paths are included; asynchronous reset pins are reported separately.
set part xc7a35tcpg236-1
set_param general.maxThreads 4
set f [open tool.txt w]; puts $f [version]; close $f
create_project -in_memory -part $part
set src [file join [pwd] source]
set_property include_dirs [list $src] [current_fileset]
foreach path [lsort [glob [file join $src *.sv]]] {
    read_verilog -sv [list $path]
}
read_verilog -sv [list [file join [pwd] driver prepack_nf_ppa_top.sv]]
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
place_design -directive Default
route_design -directive Default
# Preserve the routed design before querying stage names.
write_checkpoint routed.dcp
report_utilization -file utilization.rpt
report_utilization -hierarchical -file hierarchy.rpt
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -file timing.rpt
report_route_status -file route.rpt
report_drc -file drc.rpt
report_methodology -file methodology.rpt
write_xdc measured_constraints.xdc

proc classify {name} {
    if {[regexp {/(meta_sync[12]|reset_bridge_q)_reg} $name]} {return reset_sync}
    foreach operand {a b c} {
        foreach stage {1 2} {
            if {[string match "*/u_${operand}/p${stage}_*" $name]} {return parser_${operand}_p${stage}}
        }
    }
    if {[string match "*/u_core/u_ctrl/*" $name]} {
        if {[regexp {/(emitting_q|mode_q|fx_q|scale_q|count_q|limit_q)_reg} $name]} {return sac_state}
        return sac_token_l1
    }
    if {[string match "*/u_core/u_acc/*" $name]} {return accumulator_l3}
    if {[string match "*/u_core/t2_*" $name]} {return sbm_shift_l2}
    if {[string match "*/u_core/*" $name]} {return ops_m0_core_context}
    foreach pack {product_pack pack} {
        set label [expr {$pack eq "pack" ? "final" : "product"}]
        if {[string match "*/u_${pack}/g_rne.p1_*" $name]} {return ${label}_packer_p1}
        if {[string match "*/u_${pack}/*" $name]} {return ${label}_packer_p2}
    }
    if {[string match "*/u_add/*" $name]} {
        if {[regexp {/(a1_q|valid1_q)_reg} $name]} {return adder_a1}
        if {[regexp {/(a2_q|valid2_q)_reg} $name]} {return adder_a2}
        return adder_a3
    }
    if {[regexp {/(product_frac_q|norm_[a-z_]+_q)_reg} $name]} {return product_parse_bank}
    if {[regexp {/(c_[a-z_]+_q|zero_q|nar_q)_reg} $name]} {return c_context}
    if {[regexp {/accumulator_q_reg} $name]} {return accumulator_feedback}
    if {[regexp {/(mode_q|acc_mode_q|n_q|ops_q|busy_q|committed_q)_reg} $name]} {return transaction_control}
    return unclassified
}

set groups [dict create]
foreach cell [all_registers] {
    dict lappend groups [classify [get_property NAME $cell]] $cell
}
set csv [open stages.csv w]
puts $csv "group,register_count,setup_slack_ns,hold_slack_ns,data_delay_ns,logic_delay_ns,route_delay_ns,levels,startpoint,endpoint,hold_startpoint,hold_endpoint"
proc report_bank {name targets} {
    global csv
    set f [open ${name}_registers.txt w]
    foreach cell $targets {puts $f [get_property NAME $cell]}
    close $f
    # Data and synchronous enable only: exclude CLR/PRE recovery/removal.
    set pins [get_pins -quiet -of_objects $targets -filter {REF_PIN_NAME == D || REF_PIN_NAME == CE}]
    set row [list $name [llength $targets]]
    set setup [get_timing_paths -quiet -to $pins -delay_type max -max_paths 1]
    set hold [get_timing_paths -quiet -to $pins -delay_type min -max_paths 1]
    if {[llength $setup] && [llength $hold]} {
        foreach prop {SLACK} {lappend row [get_property $prop $setup]}
        lappend row [get_property SLACK $hold]
        foreach prop {DATAPATH_DELAY DATAPATH_LOGIC_DELAY DATAPATH_NET_DELAY LOGIC_LEVELS STARTPOINT_PIN ENDPOINT_PIN} {
            lappend row [get_property $prop $setup]
        }
        lappend row [get_property STARTPOINT_PIN $hold] [get_property ENDPOINT_PIN $hold]
        report_timing -to $pins -delay_type max -max_paths 3 -file ${name}_setup.rpt
        report_timing -to $pins -delay_type min -max_paths 3 -file ${name}_hold.rpt
    } else {
        for {set k 0} {$k < 10} {incr k} {lappend row NA}
    }
    puts $csv [join $row ,]
    flush $csv
}
foreach name [lsort [dict keys $groups]] {report_bank $name [dict get $groups $name]}
report_bank whole_data [all_registers]
close $csv
report_timing -to $outputs -delay_type max -max_paths 3 -file output_setup.rpt
report_timing -to $outputs -delay_type min -max_paths 3 -file output_hold.rpt
set f [open structural.txt w]
puts $f "registers=[llength [all_registers]]"
puts $f "latches=[llength [get_cells -quiet -hier -filter {REF_NAME =~ LD*}]]"
puts $f "unrouted=[llength [get_nets -quiet -hier -filter {ROUTE_STATUS == UNROUTED}]]"
puts $f "unclassified=[expr {[dict exists $groups unclassified] ? [llength [dict get $groups unclassified]] : 0}]"
close $f
set f [open status.txt w]; puts $f COMPLETE; close $f
puts NF_ALL_STAGES_COMPLETE
close_project
exit
