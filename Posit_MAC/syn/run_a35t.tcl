# A35T-C1 flow. argv: nf|f, ip_ooc|integration, validate|synth|implement,
# optional project-relative I/O XDC. No historical driver is modified.
if {[llength $argv] < 3 || [llength $argv] > 4} {error "Expected variant profile action ?io_xdc?"}
lassign $argv variant profile action io_xdc
if {$variant ni {nf f} || $profile ni {ip_ooc integration} ||
    $action ni {validate synth implement}} {error "Unsupported flow arguments"}
set root [file normalize [file join [file dirname [info script]] ..]]
set part xc7a35tcpg236-1
set io_groups [dict create]
if {$profile eq "integration"} {
    if {$io_xdc eq {} || ![file isfile [file join $root $io_xdc]]} {
        error "A35T_IO_UNCONFIGURED: provide a configured project-relative I/O XDC"
    }
    set f [open [file join $root $io_xdc] r]; set text [read $f]; close $f
    if {[regexp {@[A-Z_]+@} $text] || ![regexp -line {^# TIMING_REFERENCE: .+} $text]} {
        error "A35T_IO_UNCONFIGURED: fill all min/max and timing-reference tokens"
    }
    foreach line [split $text \n] {
        set line [string trim $line]
        if {$line eq {} || [string index $line 0] eq "#"} {continue}
        if {![regexp {^set_(input|output)_delay -clock clk -(min|max) ([-+0-9.eE]+) \[get_ports \{([^\}]+)\}\]$} $line -> direction bound value patterns]} {
            error "A35T_IO_INVALID: use the one-command-per-line same-clock template syntax"
        }
        if {![string is double -strict $value]} {error "A35T_IO_INVALID: nonnumeric delay"}
        set key [list $direction $patterns]
        if {[dict exists $io_groups $key $bound]} {error "A35T_IO_INVALID: duplicate delay"}
        dict set io_groups $key $bound $value
    }
    if {![dict size $io_groups]} {error "A35T_IO_INVALID: no I/O delays"}
    dict for {key values} $io_groups {
        if {![dict exists $values min] || ![dict exists $values max] ||
            [dict get $values max] < [dict get $values min]} {
            error "A35T_IO_INVALID: independent min/max required, max >= min"
        }
    }
} elseif {$io_xdc ne {}} {
    error "ip_ooc must not receive integration I/O assumptions"
}
set_param general.maxThreads 4
create_project -in_memory -part $part
set_property include_dirs [list [file join $root rtl]] [current_fileset]
set f [open [file join $root rtl production.f] r]
foreach path [split [read $f] \n] {
    set path [string trim $path]
    if {$path ne {}} {read_verilog -sv [list [file join $root $path]]}
}
close $f
if {$variant eq "nf"} {
    set top prepack_nf_ppa_top
    read_verilog -sv [list [file join $root tb prepack_nf_ppa_top.sv]]
} else {
    set top week13_fused_ppa_top
    read_verilog -sv [list [file join $root tb week13_fused_ppa_top.sv]]
}
# Load constraints BEFORE synthesis, so the synthesis optimizer sees the clock.
read_xdc [list [file join $root syn constraints a35t_clock.xdc]]
if {$profile eq "integration"} {
    read_xdc [list [file join $root $io_xdc]]
}
if {$action eq "validate"} {
    synth_design -rtl -top $top -part $part
} else {
    synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy rebuilt
}
set clocks [get_clocks]
if {$profile eq "integration"} {
    set seen [dict create]
    dict for {key values} $io_groups {
        lassign $key direction patterns
        set ports [get_ports -quiet $patterns]
        if {![llength $ports]} {error "A35T_IO_INVALID: no matching ports"}
        foreach port $ports {
            set name [get_property NAME $port]
            set wanted [expr {$direction eq "input" ? "IN" : "OUT"}]
            if {$name eq "clk" || [get_property DIRECTION $port] ne $wanted || [dict exists $seen $name]} {
                error "A35T_IO_INVALID: duplicate, clock, or wrong direction: $name"
            }
            dict set seen $name 1
        }
    }
    foreach port [get_ports -filter {NAME != clk}] {
        if {![dict exists $seen [get_property NAME $port]]} {error "A35T_IO_INVALID: uncovered port $port"}
    }
}
if {[llength $clocks] != 1 || [get_property NAME $clocks] ne "clk" ||
    abs([get_property PERIOD $clocks] - 10.0) > 0.000001} {error "Clock contract did not load"}
report_clocks -file clocks.rpt
write_xdc effective_constraints.xdc
set f [open scope.txt w]
puts $f [version]
puts $f "contract=A35T-C1 part=$part variant=$variant profile=$profile action=$action"
puts $f "clock_period_ns=10 setup_uncertainty_ns=0.100 hold_uncertainty_ns=0.100"
puts $f "NF=32/3 FW12 EXACT_EN1 OPS_EN1; F=32/3 FW12 W32 EXACT_EN0 OPS_EN1"
puts $f "No paired NF/F claim: NF EXACT_EN0 comparator still needs separate verification."
if {$profile eq "ip_ooc"} {
    puts $f "IO_UNCONSTRAINED_BY_SCOPE: no input/output delays; not board/interface signoff."
    puts $f "R2R only. Port-to-first-FF/last-FF-to-port paths are NOT covered by R2R closure."
    puts $f "Wrappers have BUFG only, no added I/O FF banks; do not claim complete input-stage timing."
} else {
    puts $f "Integration budgets supplied by $io_xdc; pinout/physical interface require separate review."
}
close $f
if {$action eq "validate"} {
    set f [open status.txt w]; puts $f VALIDATED; close $f
    puts A35T_CONSTRAINTS_VALIDATED
    close_project
    exit
}
report_utilization -file synthesis_utilization.rpt
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file synthesis_timing.rpt
write_checkpoint synthesis.dcp
if {$action eq "implement"} {
    opt_design
    place_design -directive Default
    route_design -directive Default
    write_checkpoint routed.dcp
    write_xdc effective_constraints_routed.xdc
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file timing.rpt
    report_utilization -file utilization.rpt
    report_utilization -hierarchical -file hierarchy.rpt
    report_route_status -file route.rpt
    report_drc -file drc.rpt
    report_methodology -file methodology.rpt
    set targets [get_pins -of_objects [all_registers] -filter {REF_PIN_NAME == D || REF_PIN_NAME == CE}]
    report_timing -from [all_registers] -to $targets -delay_type max -max_paths 10 -file r2r_setup.rpt
    report_timing -from [all_registers] -to $targets -delay_type min -max_paths 10 -file r2r_hold.rpt
}
# COMPLETE means execution complete, not timing PASS. Inspect timing/coverage.
set f [open status.txt w]; puts $f COMPLETE; close $f
puts A35T_FLOW_COMPLETE
close_project
exit
