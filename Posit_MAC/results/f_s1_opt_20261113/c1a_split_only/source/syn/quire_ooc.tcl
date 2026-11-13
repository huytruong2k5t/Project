# Fixed A35T Q12-1024 recipe. Call with source root, run in a fresh project subdir.
if {$argc == 1} {
    set source_root [file normalize [lindex $argv 0]]
} elseif {[info exists ::env(QUIRE_SOURCE_ROOT)]} {
    set source_root [file normalize $::env(QUIRE_SOURCE_ROOT)]
} else {error "source root required"}
create_project -in_memory -part xc7a35tcpg236-1
set_property include_dirs [list "$source_root/rtl"] [current_fileset]
set file_handle [open "$source_root/rtl/quire_active.f" r]
set sources {}
foreach path [split [read $file_handle] "\n"] {
    set path [string trim $path]
    if {$path ne ""} {lappend sources "$source_root/$path"}
}
close $file_handle
foreach source $sources {read_verilog -sv [list $source]}
read_verilog -sv [list "$source_root/tb/quire_ppa_top.sv"]
# Load deferred XDC before synthesis, so clock goals apply during optimization.
read_xdc [list [file join $source_root syn constraints a35t_clock.xdc]]
read_xdc [list [file join $source_root syn constraints a35t_benchmark_100mhz.xdc]]
synth_design -top quire_ppa_top -part xc7a35tcpg236-1 -mode out_of_context -flatten_hierarchy rebuilt
report_utilization -file synthesis_utilization.rpt
report_timing_summary -delay_type min_max -file synthesis_timing.rpt
opt_design
place_design
phys_opt_design
route_design
report_route_status -file route_status.rpt
report_utilization -file route_utilization.rpt
report_timing_summary -delay_type min_max -report_unconstrained -file route_timing.rpt
report_timing -delay_type max -max_paths 10 -file setup_paths.rpt
report_timing -delay_type min -max_paths 10 -file hold_paths.rpt
set setup_path [get_timing_paths -delay_type max -max_paths 1]
set hold_path [get_timing_paths -delay_type min -max_paths 1]
set setup_slack [get_property SLACK $setup_path]
set hold_slack [get_property SLACK $hold_path]
set result [open result.json w]
puts $result "{\"scope\":\"single A35T OOC route; not board or Fmax sweep\",\"period_ns\":10.0,\"setup_slack_ns\":$setup_slack,\"hold_slack_ns\":$hold_slack,\"vivado\":\"[version -short]\"}"
close $result
puts "QUIRE_PPA_DONE setup=$setup_slack hold=$hold_slack"
