# Supplemental reports only: no synthesis, implementation, or constraint changes.
# Each sequential cell is assigned once. Endpoints include payload, metadata,
# valid, and enables. Startpoints are all register clock pins in the design.
proc classify_stage {name} {
    if {[regexp {/(meta_sync[12]|reset_bridge_q)_reg} $name]} {return reset_sync}
    if {[regexp {/u_([abc])/(p[12])_} $name -> operand stage]} {
        return parser_${operand}_${stage}
    }
    if {[regexp {/u_add/(.*)} $name -> local]} {
        if {[regexp {^s([1-4])_} $local -> index]} {return adder_s${index}}
        if {[regexp {^valid_q_reg\[([0-4])\]$} $local -> index]} {
            return adder_s[expr {$index + 1}]
        }
        if {[regexp {^(sign|is_zero|is_nar|sf|frac_hi_q|sticky|flags_out)_reg} $local]} {
            return adder_s5
        }
        return adder_other
    }
    foreach {block label} {u_pack final_pack u_product_pack product_pack} {
        if {[regexp "/${block}/(.*)" $name -> local]} {
            if {[string match p1_* $local]} {return ${label}_p1}
            if {[regexp {^(p2_valid_q|d_q|flags_q)_reg} $local]} {return ${label}_p2}
            return ${label}_other
        }
    }
    if {[regexp {/u_core/(.*)} $name -> local]} {
        if {[string match t1_* $local]} {return multiplier_t1}
        if {[string match t2_* $local]} {return multiplier_t2}
        if {[regexp {^(fx_q|scale_q|count_q|limit_q|emitting_q)_reg} $local]} {return multiplier_sac}
        if {[regexp {^(acc_q|iterations_done_q|approx_cut_q|done_q)_reg} $local]} {return multiplier_acc}
        if {[regexp {^(y_q|sign_o|sf_o|input_cut_o|busy_q)_reg} $local]} {return multiplier_context}
        return multiplier_other
    }
    if {[string match */u_wrapper/* $name]} {return wrapper_control_context}
    return other_registers
}

set groups [dict create]
set inventory [open stage_register_inventory.csv w]
puts $inventory "group,register"
foreach cell $regs {
    set name [get_property NAME $cell]
    set group [classify_stage $name]
    dict lappend groups $group $cell
    puts $inventory "$group,$name"
}
close $inventory
set count 0
dict for {group cells} $groups {incr count [llength $cells]}
if {$count != [llength $regs]} {error "Register grouping lost or duplicated cells"}

# Reuse the original path emitter and its C->D / C->D,CE definitions.
set csv [open f2f_full_stages.csv w]
puts $csv "group,register_count,target_kind,data_delay_ns,logic_delay_ns,net_delay_ns,slack_ns,levels,startpoint,endpoint"
foreach group [lsort [dict keys $groups]] {
    set cells [dict get $groups $group]
    set pins [get_pins -of_objects $cells -filter {REF_PIN_NAME == D}]
    emit_paths full_${group} $cells $pins D
    set pins [get_pins -of_objects $cells -filter {REF_PIN_NAME == D || REF_PIN_NAME == CE}]
    emit_paths full_${group} $cells $pins D_CE
}
close $csv
set f [open full_stage_coverage.txt w]
puts $f "ALL_REGISTERS_GROUPED=$count"
puts $f "GROUPS=[dict size $groups]"
puts $f "Startpoints=all_registers_clock_pins; endpoints=D_and_CE; asynchronous_reset_paths_not_included"
puts $f "Each group is defined by destination registers, not a fixed adjacent-stage launch group."
close $f
