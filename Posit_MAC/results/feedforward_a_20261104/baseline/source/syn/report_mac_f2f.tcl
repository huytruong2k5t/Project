# Post-synthesis unplaced same-clock C -> D/CE estimates, not routed Fmax.
set launch [all_registers -clock_pins]
set regs [all_registers -cells]
set allpins [get_pins -of_objects $regs]
set dpins [filter $allpins {REF_PIN_NAME == D}]
set dcepins [filter $allpins {REF_PIN_NAME == D || REF_PIN_NAME == CE}]
set csv [open f2f_stages.csv w]
puts $csv "group,register_count,target_kind,data_delay_ns,logic_delay_ns,net_delay_ns,slack_ns,levels,startpoint,endpoint"
proc emit_paths {label cells pins kind} {
    global launch csv
    if {[llength $pins] == 0} {return}
    set paths [get_timing_paths -from $launch -to $pins -delay_type max -max_paths 20 -nworst 1]
    if {[llength $paths] == 0} {return}
    report_timing -from $launch -to $pins -delay_type max -max_paths 20 -nworst 1 -input_pins -file ${label}_${kind}.rpt
    set best [lindex $paths 0]
    foreach path $paths {
        if {[get_property DATAPATH_DELAY $path] > [get_property DATAPATH_DELAY $best]} {set best $path}
    }
    puts $csv "$label,[llength $cells],$kind,[get_property DATAPATH_DELAY $best],[get_property LOGIC_DELAY $best],[get_property NET_DELAY $best],[get_property SLACK $best],[get_property LOGIC_LEVELS $best],[get_property STARTPOINT_PIN $best],[get_property ENDPOINT_PIN $best]"
}
emit_paths whole $regs $dpins D
emit_paths whole $regs $dcepins D_CE
foreach {label pattern} {
    feedback {*accumulator_q_reg*}
    parser_a_p1 {*u_a/p1_*reg*} parser_a_p2 {*u_a/*out*reg*}
    parser_b_p1 {*u_b/p1_*reg*} parser_b_p2 {*u_b/*out*reg*}
    parser_c_p1 {*u_c/p1_*reg*} parser_c_p2 {*u_c/*out*reg*}
    multiplier_context {*u_core/*_hold_q_reg*}
    multiplier_sac {*u_core/sac_*reg*}
    multiplier_t2 {*u_core/t2_*reg*}
    multiplier_acc {*u_core/acc*reg*}
    adder_s1 {*u_add/s1_*reg*} adder_s2 {*u_add/s2_*reg*}
    adder_s3 {*u_add/s3_*reg*} adder_s4 {*u_add/s4_*reg*}
    adder_s5 {*u_add/frac_hi_q_reg*}
    final_pack_p1 {*u_pack/*p1*reg*} final_pack_p2 {*u_pack/*p2*reg*}
    product_pack {*u_product_pack/*reg*}
} {
    set cells [filter $regs "NAME =~ $pattern"]
    if {[llength $cells] == 0} {continue}
    set pins [get_pins -of_objects $cells -filter {REF_PIN_NAME == D || REF_PIN_NAME == CE}]
    emit_paths $label $cells $pins D_CE
}
close $csv
report_timing -from [get_ports c*] -to $dcepins -delay_type max -max_paths 10 -input_pins -file input_c_to_register.rpt
set timing [get_timing_paths -delay_type max -max_paths 1]
set hold [get_timing_paths -delay_type min -max_paths 1]
set metrics [open timing_metrics.csv w]
puts $metrics "wns_ns,whs_ns,period_ns,feedback_registers"
puts $metrics "[get_property SLACK $timing],[get_property SLACK $hold],10.000,[llength [filter $regs {NAME =~ *accumulator_q_reg*}]]"
close $metrics
