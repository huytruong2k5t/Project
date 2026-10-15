# Post-route stage survey; no timing exceptions or netlist/source mutation.
project_open nf
create_timing_netlist
read_sdc
update_timing_netlist
proc report_group {name from_patterns to_patterns} {
    set targets [get_registers $to_patterns]
    if {[get_collection_size $targets] == 0} {error "No register targets for $name"}
    if {[string length $from_patterns] == 0} {
        report_timing -setup -to $targets -npaths 10 -detail full_path -file "stage_${name}.rpt"
    } else {
        set sources [get_registers $from_patterns]
        if {[get_collection_size $sources] == 0} {error "No register sources for $name"}
        report_timing -setup -from $sources -to $targets -npaths 10 -detail full_path -file "stage_${name}.rpt"
    }
}
report_group ops {*p2_frac_q* *p2_sf_q* *p2_s_q*} {*u_ctrl*fx_q* *u_core*y_q*}
report_group sac {*u_ctrl*fx_q* *u_ctrl*scale_q*} {*u_ctrl*fx_q* *u_ctrl*scale_q*}
report_group accumulator {} {*u_acc*acc*}
report_group norm_round {} {*product_frac_q* *norm_sf_q*}
report_group add_align {} {*u_add*a1_q*}
report_group add_arith {} {*u_add*a2_q*}
report_group add_normalize {} {*u_add|frac* *u_add|sf*}
report_group pack_p1 {} {*u_pack*p1_*}
report_group control {} {*valid* *busy_q* *committed_q*}
delete_timing_netlist
project_close
