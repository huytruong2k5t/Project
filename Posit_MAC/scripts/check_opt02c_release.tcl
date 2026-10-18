# Query existing routed NF/F checkpoints; no synthesis/place/route rerun.
if {[llength $argv] != 2} {error "Expected NF and F routed checkpoints"}
set_param general.maxThreads 4
foreach label {nf f} path $argv {
    open_checkpoint $path
    report_cdc -details -file ${label}_cdc.rpt
    report_methodology -file ${label}_methodology.rpt
    report_drc -file ${label}_drc.rpt
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file ${label}_timing.rpt
    set f [open ${label}_structure.txt w]
    puts $f "clocks=[llength [get_clocks]]"
    puts $f "registers=[llength [all_registers]]"
    puts $f "latches=[llength [get_cells -quiet -hier -filter {REF_NAME =~ LD*}]]"
    puts $f "unrouted=[llength [get_nets -quiet -hier -filter {ROUTE_STATUS == UNROUTED}]]"
    puts $f "async_reg=[llength [get_cells -quiet -hier -filter {ASYNC_REG == 1}]]"
    close $f
    close_design
}
set f [open status.txt w]; puts $f COMPLETE; close $f
exit
