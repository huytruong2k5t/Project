# A35T-C1 SYSTEM-SYNCHRONOUS I/O TEMPLATE. NOT BOARD TIMING.
# Copy inside this project and replace ALL @...@ tokens with real facts.
# One command per line; clk is defined by a35t_clock.xdc.
# Values are ns at the IP boundary, including the source/receiver and relative
# data/clock connection timing. Do not choose min to remove hold violations.
# Output min may be negative. Another clock/phase needs another interface flow.
# Pinout/IOSTANDARD are separate; this file does not establish board signoff.
# TIMING_REFERENCE: @DATASHEET_OR_INTERFACE_CONTRACT@
# INPUT_DATA_REFERENCE: @INPUT_DATA_REFERENCE@
# INPUT_CONTROL_REFERENCE: @INPUT_CONTROL_REFERENCE@
# OUTPUT_DATA_REFERENCE: @OUTPUT_DATA_REFERENCE@
# OUTPUT_CONTROL_REFERENCE: @OUTPUT_CONTROL_REFERENCE@
set_input_delay -clock clk -min @INPUT_DATA_MIN@ [get_ports {a[*] b[*] c[*]}]
set_input_delay -clock clk -max @INPUT_DATA_MAX@ [get_ports {a[*] b[*] c[*]}]
set_input_delay -clock clk -min @INPUT_CONTROL_MIN@ [get_ports {rst_n in_valid acc_mode acc_clr cfg_mode cfg_n[*] cfg_ops[*] out_ready}]
set_input_delay -clock clk -max @INPUT_CONTROL_MAX@ [get_ports {rst_n in_valid acc_mode acc_clr cfg_mode cfg_n[*] cfg_ops[*] out_ready}]
set_output_delay -clock clk -min @OUTPUT_DATA_MIN@ [get_ports {d[*] flags[*]}]
set_output_delay -clock clk -max @OUTPUT_DATA_MAX@ [get_ports {d[*] flags[*]}]
set_output_delay -clock clk -min @OUTPUT_CONTROL_MIN@ [get_ports {in_ready out_valid}]
set_output_delay -clock clk -max @OUTPUT_CONTROL_MAX@ [get_ports {in_ready out_valid}]
