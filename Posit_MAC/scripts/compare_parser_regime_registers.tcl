# Compare only synthesis resources. No placement/routing or fmax claim.
# Run from Posit_MAC/results/parser_regime_retime.
set project_root [file normalize ../..]
set part xc7a100tcsg324-1
set output [open register_comparison.csv w]
puts $output "variant,NB,ES,part,FF,LUT"
puts "PARSER_COMPARE Vivado=[version -short] part=$part"

foreach es {2 3} {
    foreach variant {before after} {
        create_project -in_memory -part $part
        set_property include_dirs [list "$project_root/rtl"] [current_fileset]
        read_verilog -sv "$project_root/rtl/lod_lzd_core.sv"
        read_verilog -sv "$project_root/rtl/dyn_left_shifter.sv"

        if {$variant eq "before"} {
            read_verilog -sv before/posit_parser.sv
        } else {
            read_verilog -sv "$project_root/rtl/posit_parser.sv"
        }

        synth_design -top posit_parser -part $part -mode out_of_context \
            -flatten_hierarchy none -generic [list NB=32 ES=$es]
        report_utilization -hierarchical -file "${variant}_es${es}_utilization.rpt"
        set ff [llength [get_cells -hier -filter {REF_NAME =~ FD*}]]
        set lut [llength [get_cells -hier -filter {REF_NAME =~ LUT*}]]
        puts $output "$variant,32,$es,$part,$ff,$lut"
        flush $output
        puts "PARSER_COMPARE variant=$variant ES=$es FF=$ff LUT=$lut"
        close_project
    }
}
close $output
puts "PARSER_REGISTER_COMPARE DONE"
