set out_dir [file normalize [file dirname [info script]]]
set src_dir [file normalize "$out_dir/../route_nf_f_20261112"]

proc dump_metrics {tag dcp_path out_dir} {
    open_checkpoint $dcp_path

    report_utilization -file "$out_dir/${tag}_utilization.rpt"
    report_timing_summary -delay_type min_max -max_paths 5 -file "$out_dir/${tag}_timing_summary.rpt"
    report_timing -delay_type max -nworst 1 -max_paths 5 -file "$out_dir/${tag}_worst_setup_all.rpt"
    report_timing -delay_type min -nworst 1 -max_paths 5 -file "$out_dir/${tag}_worst_hold_all.rpt"
    report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type max -nworst 1 -max_paths 5 -file "$out_dir/${tag}_reg2reg_setup_clk.rpt"
    report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type min -nworst 1 -max_paths 5 -file "$out_dir/${tag}_reg2reg_hold_clk.rpt"
    report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -delay_type max -nworst 1 -max_paths 5 -file "$out_dir/${tag}_reg2reg_setup_any.rpt"

    set p_all_max [get_timing_paths -delay_type max -nworst 1 -max_paths 1]
    set p_all_min [get_timing_paths -delay_type min -nworst 1 -max_paths 1]
    set p_r2r_clk_max [get_timing_paths -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type max -nworst 1 -max_paths 1]
    set p_r2r_any_max [get_timing_paths -from [all_registers -clock_pins] -to [all_registers -data_pins] -delay_type max -nworst 1 -max_paths 1]
    set p_r2r_clk_min [get_timing_paths -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type min -nworst 1 -max_paths 1]

    set fp [open "$out_dir/${tag}_metrics.txt" w]
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
    close_design
}

dump_metrics "nf_synth" "$src_dir/nf/synthesis.dcp" $out_dir
dump_metrics "nf_route" "$src_dir/nf/routed.dcp" $out_dir
dump_metrics "f_synth"  "$src_dir/f/synthesis.dcp"  $out_dir
dump_metrics "f_route"  "$src_dir/f/routed.dcp"  $out_dir
puts "QUERY_INTERNAL_DONE"
