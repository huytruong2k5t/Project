# A35T-C2: fixed historical I/O budget for every 10.000 ns benchmark.
# This is an assumed benchmark interface, NOT measured board timing.
# Clock and setup/hold uncertainty come from a35t_clock.xdc.
set inputs [get_ports -filter {DIRECTION == IN && NAME != clk}]
set outputs [get_ports -filter {DIRECTION == OUT}]
set_input_delay -clock clk -max 2.500 $inputs
set_input_delay -clock clk -min 2.500 $inputs
set_output_delay -clock clk -max 0.500 $outputs
set_output_delay -clock clk -min 0.000 $outputs
