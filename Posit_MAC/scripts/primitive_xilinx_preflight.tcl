# Read-only installation probe. Run with the working directory in Posit_MAC.
puts "PROBE_VERSION [version -short]"
foreach part {xc7a35tcpg236-1 xc7a100tcsg324-1 xc7z020clg400-1} {
    puts "PROBE_PART $part [get_parts -quiet $part]"
}
puts "PROBE_ZYNQ [get_parts -quiet *7z020*]"
puts "PROBE_ARTIX [get_parts -quiet *7a100t*]"
help place_design
help route_design
exit
