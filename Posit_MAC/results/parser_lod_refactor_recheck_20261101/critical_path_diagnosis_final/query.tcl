# Read-only netlist/timing diagnosis; arguments are label/checkpoint pairs.
set_param general.maxThreads 4
if {[llength $argv] % 2} {error "Expected label/checkpoint pairs"}
proc prop {obj name} {
    if {[llength $obj] && [lsearch -exact [list_property $obj] $name] >= 0} {
        return [get_property $name $obj]
    }
    return {}
}
proc csvline {handle values} {
    set row {}
    foreach value $values {lappend row "\"[string map [list \" \"\"] $value]\""}
    puts $handle [join $row ,]
}
proc exactpin {n} {return [get_pins -quiet -hier -filter [format {NAME == "%s"} $n]]}
proc dump_path {prefix path} {
    global interest_nets
    if {![llength $path]} {return}
    report_property -all $path -file ${prefix}_path_properties.txt
    set timing [report_timing -from [get_property STARTPOINT_PIN $path] -to [get_property ENDPOINT_PIN $path] -delay_type max -max_paths 1 -input_pins -return_string]
    set report [open ${prefix}_detailed.rpt w];puts $report $timing;close $report
    set points {}
    foreach line [split $timing \n] {
        if {[regexp {(u_dut/\S+)\s*$} $line -> name]} {
            set pin [exactpin $name]
            if {[llength $pin]} {lappend points $pin}
        }
    }
    set f [open ${prefix}_points.csv w]
    csvline $f {pin cell ref_name fanout net}
    set details [open ${prefix}_cells.txt w]
    set connections [open ${prefix}_connections.csv w]
    csvline $connections {cell ref_name init pin direction net net_driver net_load_count}
    set seen [dict create]
    foreach pin $points {
        set cell [get_cells -quiet -of_objects $pin -filter {IS_PRIMITIVE == 1}]
        if {![llength $cell]} {continue}
        set nets [get_nets -quiet -of_objects $pin]
        foreach net $nets {dict set interest_nets $net 1}
        set loads [get_pins -quiet -leaf -of_objects $nets -filter {DIRECTION == IN}]
        csvline $f [list $pin $cell [prop $cell REF_NAME] [llength $loads] $nets]
        if {[llength $cell] && ![dict exists $seen $cell]} {
            dict set seen $cell 1
            puts $details "CELL $cell"
            foreach property {REF_NAME ORIG_REF_NAME ORIG_CELL_NAME INIT LOC BEL} {
                puts $details "$property=[prop $cell $property]"
            }
            foreach cp [get_pins -quiet -of_objects $cell] {
                set ns [get_nets -quiet -of_objects $cp]
                set drivers [get_pins -quiet -leaf -of_objects $ns -filter {DIRECTION == OUT}]
                set sinks [get_pins -quiet -leaf -of_objects $ns -filter {DIRECTION == IN}]
                csvline $connections [list $cell [prop $cell REF_NAME] [prop $cell INIT] $cp [prop $cp DIRECTION] $ns $drivers [llength $sinks]]
            }
        }
    }
    close $f;close $details;close $connections
}
foreach {label checkpoint} $argv {
    file mkdir $label
    cd $label
    open_checkpoint $checkpoint
    set interest_nets [dict create]
    set regs [all_registers]
    set dpins [get_pins -quiet -of_objects $regs -filter {REF_PIN_NAME == D || REF_PIN_NAME == CE}]
    report_timing -from $regs -to $dpins -delay_type max -max_paths 20 -nworst 3 -input_pins -file top20_f2f.rpt
    set path [get_timing_paths -from $regs -to $dpins -delay_type max -max_paths 1]
    dump_path critical $path
    set cp [exactpin {u_dut/u_wrapper/u_c/p1_cnt_q_reg[0]/D}]
    set parserpath [get_timing_paths -from $regs -to $cp -delay_type max -max_paths 1]
    if {[get_property NAME $path] ne [get_property NAME $parserpath]} {dump_path parser_c_p1 $parserpath}
    set bitf [open parser_count_bits.csv w]
    csvline $bitf {bit data_delay_ns logic_delay_ns net_delay_ns levels startpoint endpoint}
    for {set k 0} {$k < 5} {incr k} {
        set dest [exactpin [format {u_dut/u_wrapper/u_c/p1_cnt_q_reg[%d]/D} $k]]
        set p [get_timing_paths -from $regs -to $dest -delay_type max -max_paths 1]
        set row [list $k]
        foreach property {DATAPATH_DELAY DATAPATH_LOGIC_DELAY DATAPATH_NET_DELAY LOGIC_LEVELS STARTPOINT_PIN ENDPOINT_PIN} {lappend row [get_property $property $p]}
        csvline $bitf $row
    }
    close $bitf
    set fanouts {}
    foreach net [dict keys $interest_nets] {
        set drivers [get_pins -quiet -leaf -of_objects $net -filter {DIRECTION == OUT}]
        if {![llength $drivers] || [llength $drivers] > 1} {continue}
        set dtype [prop [get_cells -quiet -of_objects $drivers] REF_NAME]
        if {[regexp {^(BUFG|VCC|GND)} $dtype]} {continue}
        set loads [get_pins -quiet -leaf -of_objects $net -filter {DIRECTION == IN}]
        if {[llength $loads] < 8} {continue}
        lappend fanouts [list [llength $loads] $net $drivers $dtype $loads]
    }
    set f [open high_fanout.csv w]
    csvline $f {fanout net driver driver_ref sinks}
    foreach row [lsort -integer -decreasing -index 0 $fanouts] {csvline $f $row}
    close $f
    set cone [all_fanin -flat -only_cells -to $cp]
    set hist [dict create]
    foreach cell $cone {dict incr hist [prop $cell REF_NAME]}
    set f [open parser_count0_cone_histogram.txt w]
    foreach type [lsort [dict keys $hist]] {puts $f "$type [dict get $hist $type]"}
    close $f
    set cone_nets [get_nets -quiet -of_objects [get_pins -quiet -of_objects $cone -filter {DIRECTION == OUT}]]
    set f [open cone_net_properties.txt w]
    # Save available net properties to avoid assuming a physical route exists.
    if {[llength $cone_nets]} {puts $f [report_property -all -return_string [lindex $cone_nets 0]]}
    close $f
    close_design
    set f [open status.txt w];puts $f QUERY_COMPLETE;close $f
    cd ..
    puts "QUERY_COMPLETE $label"
}
exit
