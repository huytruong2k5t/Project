# Same OOC clock and fixed I/O assumptions for all OPT-17 variants.
create_clock -name clk -period 8.300 [get_ports clk]
set_clock_uncertainty -setup 0.100 [get_clocks clk]
set_clock_uncertainty -hold 0.100 [get_clocks clk]
set inputs [get_ports -filter {DIRECTION == IN && NAME != clk}]
set outputs [get_ports -filter {DIRECTION == OUT}]
set_input_delay -clock clk -max 2.500 $inputs
set_input_delay -clock clk -min 2.500 $inputs
set_output_delay -clock clk -max 0.500 $outputs
set_output_delay -clock clk -min 0.000 $outputs
