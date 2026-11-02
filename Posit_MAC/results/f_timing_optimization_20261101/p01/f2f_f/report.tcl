# Read-only timing queries against the already synthesized checkpoint.
if {[llength $argv]!=1} {error "Expected synthesis checkpoint"}
set_param general.maxThreads 4
open_checkpoint [lindex $argv 0]
proc classify {n} {
    if {[regexp {/(meta_sync[12]|reset_bridge_q)_reg} $n]} {return reset_sync}
    foreach operand {a b c} {
        foreach stage {1 2} {
            if {[string match "*/u_${operand}/p${stage}_*" $n]} {return parser_${operand}_p${stage}}
        }
    }
    foreach pack {product_pack pack} {
        if {[string match "*/u_${pack}/*" $n]} {
            set label [expr {$pack eq "pack" ? "final" : "product"}]
            if {[regexp {/(g_rne\.)?p1_} $n]} {return ${label}_packer_p1}
            return ${label}_packer_p2
        }
    }
    if {[string match "*/u_add/*" $n]} {
        foreach stage {1 2 3 4} {
            if {[string match "*/s${stage}_*" $n]} {return adder_s${stage}}
        }
        if {[string match "*/valid_q_reg*" $n]} {return adder_valid_control}
        return adder_s5
    }
    if {[string match "*/u_fused/*" $n]} {
        foreach stage {1 2 3 4 5} {
            if {[string match "*/f${stage}_q_reg*" $n]} {return fused_f${stage}}
        }
        return fused_control
    }
    if {[string match "*/u_core/*" $n]} {
        if {[string match "*/u_acc/*" $n] || [regexp {/(acc_q|numerical_tail_q|iterations_done_q|approx_cut_q|done_q)_reg} $n]} {return multiplier_acc_l3}
        if {[regexp {/t2_} $n]} {return multiplier_shift_l2}
        if {[regexp {/t1_} $n]} {return multiplier_sac_l1}
        if {[string match "*/u_ctrl/*" $n]} {
            if {[regexp {/(emitting_q|mode_q|fx_q|scale_q|count_q|limit_q)_reg} $n]} {return multiplier_sac_state}
            return multiplier_sac_l1
        }
        if {[regexp {/(emitting_q|fx_q|scale_q|count_q|limit_q)_reg} $n]} {return multiplier_sac_state}
        return multiplier_ops_context
    }
    if {[regexp {/(product_frac_q|norm_[a-z_]+_q)_reg} $n]} {return product_parse_bank}
    if {[regexp {/accumulator_q_reg} $n]} {return accumulator_feedback}
    if {[regexp {/(c_[a-z_]+_q|zero_q|nar_q)_reg} $n]} {return operand_c_context}
    return top_control_context
}
set groups [dict create]
set regs [all_registers]
foreach c $regs {dict lappend groups [classify [get_property NAME $c]] $c}
set csv [open stages.csv w]
puts $csv "group,register_count,target_kind,data_delay_ns,logic_delay_ns,net_delay_ns,slack_ns,levels,startpoint,endpoint"
proc query {group cells kind} {
    global csv regs
    if {$kind eq "D"} {set filter {REF_PIN_NAME == D}} else {set filter {REF_PIN_NAME == D || REF_PIN_NAME == CE}}
    set pins [get_pins -quiet -of_objects $cells -filter $filter]
    set paths [get_timing_paths -quiet -from $regs -to $pins -delay_type max -max_paths 1]
    set row [list $group [llength $cells] $kind]
    if {[llength $paths]} {
        foreach prop {DATAPATH_DELAY DATAPATH_LOGIC_DELAY DATAPATH_NET_DELAY SLACK LOGIC_LEVELS STARTPOINT_PIN ENDPOINT_PIN} {
            lappend row [get_property $prop $paths]
        }
        report_timing -from $regs -to $pins -delay_type max -max_paths 3 -file ${group}_${kind}.rpt
    } else {foreach k {1 2 3 4 5 6 7} {lappend row NA}}
    puts $csv [join $row ,];flush $csv
}
foreach group [lsort [dict keys $groups]] {
    set cells [dict get $groups $group]
    set f [open ${group}_registers.txt w];puts $f [join $cells \n];close $f
    query $group $cells D
    query $group $cells D_CE
}
query whole_f2f $regs D_CE
close $csv
set data_pins [get_pins -quiet -of_objects $regs -filter {REF_PIN_NAME == D || REF_PIN_NAME == CE}]
report_timing -from $regs -to $data_pins -delay_type max -max_paths 20 -nworst 3 -input_pins -file whole_f2f_top20.rpt
report_timing -from [all_inputs] -to $data_pins -delay_type max -max_paths 10 -input_pins -file input_to_register_top10.rpt
set bits [open parser_c_count_bits.csv w]
puts $bits "bit,data_delay_ns,logic_delay_ns,net_delay_ns,slack_ns,levels,startpoint,endpoint"
for {set k 0} {$k < 5} {incr k} {
    set name [format {u_dut/u_wrapper/u_c/p1_cnt_q_reg[%d]/D} $k]
    set pin [get_pins -quiet -hier -filter [format {NAME == "%s"} $name]]
    set path [get_timing_paths -quiet -from $regs -to $pin -delay_type max -max_paths 1]
    if {![llength $path]} {continue}
    set row [list $k]
    foreach property {DATAPATH_DELAY DATAPATH_LOGIC_DELAY DATAPATH_NET_DELAY SLACK LOGIC_LEVELS STARTPOINT_PIN ENDPOINT_PIN} {lappend row [get_property $property $path]}
    puts $bits [join $row ,]
}
close $bits
set f [open status.txt w];puts $f F2F_REPORT_COMPLETE;close $f
close_design
exit
