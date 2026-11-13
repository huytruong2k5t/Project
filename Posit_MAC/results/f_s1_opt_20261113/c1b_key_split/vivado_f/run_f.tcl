# Exact 100 MHz OOC Synth + Place + Route recipe matching route_mac_100mhz.tcl plus reg2reg setup reports
set root {C:/HCMUT/HK261/Do an 2/Posit_MAC/results/f_s1_opt_20261113/c1b_key_split/source}
set part xc7a35tcpg236-1
set_param general.maxThreads 4
create_project -in_memory -part $part
set_property include_dirs [list [file join $root rtl]] [current_fileset]
set list_file [open [file join $root rtl mac_active.f] r]
set rtl [split [read $list_file] \n]
close $list_file
foreach path $rtl {
    set path [string trim $path]
    if {$path ne {}} {read_verilog -sv [list [file join $root $path]]}
}
set top week13_fused_ppa_top
read_verilog -sv [list [file join $root tb ${top}.sv]]
read_xdc [list [file join $root syn constraints a35t_clock.xdc]]
read_xdc [list [file join $root syn constraints a35t_benchmark_100mhz.xdc]]
synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy rebuilt -max_dsp 0 -max_bram 0
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file synthesis_timing.rpt
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type max -nworst 1 -max_paths 10 -file synthesis_reg2reg.rpt
report_utilization -file synthesis_utilization.rpt
write_checkpoint synthesis.dcp
opt_design
place_design -directive Default
route_design -directive Default
write_checkpoint routed.dcp
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file route_timing.rpt
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type max -nworst 1 -max_paths 15 -file route_reg2reg.rpt
report_route_status -file route_status.rpt
report_utilization -file route_utilization.rpt
report_drc -file route_drc.rpt
puts "OPT_ROUTE_COMPLETE cand=c1b_key_split"
close_project
exit
