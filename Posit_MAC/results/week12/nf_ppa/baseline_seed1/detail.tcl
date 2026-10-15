project_open nf
create_timing_netlist
read_sdc
update_timing_netlist
report_timing -setup -npaths 10 -detail full_path -file setup_paths.rpt
report_timing -hold -npaths 10 -detail full_path -file hold_paths.rpt
report_ucp -file unconstrained.rpt
delete_timing_netlist
project_close
