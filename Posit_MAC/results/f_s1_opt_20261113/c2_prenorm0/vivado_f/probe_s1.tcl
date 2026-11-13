open_checkpoint {Posit_MAC\results\f_s1_opt_20261113\c2_prenorm0\vivado_f/routed.dcp}
puts "=== WORST -> s1_* ==="
report_timing -to [get_pins -hier -filter {NAME =~ *u_add*s1_*_q_reg*/D}] -delay_type max -max_paths 5 -nworst 1
close_design
exit
