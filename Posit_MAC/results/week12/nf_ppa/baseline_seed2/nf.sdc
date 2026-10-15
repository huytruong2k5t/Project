create_clock -name clk -period 10.000 [get_ports clk]
derive_clock_uncertainty
# Provisional interface budget, not a board constraint: max 0.5ns / min 0.1ns.
set_input_delay -clock clk -max 0.500 [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay -clock clk -min 0.100 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk -max 0.500 [all_outputs]
set_output_delay -clock clk -min 0.100 [all_outputs]
