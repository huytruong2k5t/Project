# Shared synthesis/implementation clock contract, version A35T-C1.
# Target part is fixed by syn/run_a35t.tcl: xc7a35tcpg236-1.
# No I/O arrival assumptions, false paths, or multicycle paths here.
create_clock -name clk -period 10.000 [get_ports clk]
set_clock_uncertainty -setup 0.100 [get_clocks clk]
set_clock_uncertainty -hold 0.100 [get_clocks clk]
