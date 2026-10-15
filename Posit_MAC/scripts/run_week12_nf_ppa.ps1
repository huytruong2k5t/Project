param([string]$QuartusBin='C:/altera/13.0sp1/quartus/bin64')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'rtl_paths.ps1')
$project=Split-Path $PSScriptRoot -Parent
$run=Join-Path $project 'results/week12/nf_ppa'
New-Item -ItemType Directory -Force "$run/tmp" | Out-Null
$env:TEMP=Join-Path $run 'tmp'
$env:TMP=$env:TEMP
$sources=@('lod_lzd_core','dyn_left_shifter','dyn_right_shifter','posit_parser','posit_parser_comb',
    'ops_sel_comb','sac_step_comb','sbm_shift_comb','sbm_accum_comb','iter_ctrl','sbm_accum',
    'mul_iter_core','mul_prepack_norm_comb','posit_pack_prepare','posit_pack_finish',
    'posit_pack_comb','round_unpacked_comb','posit_add_align','posit_add_arith',
    'posit_add_normalize','posit_add','posit_pack','mac_nf_wrapper','posit_mac_nf')
& "$QuartusBin/quartus_sh.exe" --version | Set-Content "$run/version.log"
Set-Content -Encoding ascii "$run/status.txt" RUNNING
foreach($seed in @(1,2,3)) {
    $folder=Join-Path $run "baseline_seed$seed"
    New-Item -ItemType Directory -Force "$folder/src" | Out-Null
    foreach($name in $sources) {Copy-Item -LiteralPath (Resolve-RtlPath $name) -Destination "$folder/src/$name.sv"}
    # Quartus13 requires explicit generate delimiters accepted implicitly by SV tools.
    # Only the private copy changes; conditions, assignments and port widths are identical.
    $parser=Get-Content -LiteralPath "$folder/src/posit_parser_comb.sv" -Raw
    $parser=$parser.Replace('    if(NB<4',"    generate`n    if(NB<4")
    $parser=$parser.Replace('    typedef logic signed',"    endgenerate`n    typedef logic signed")
    $parser=$parser.Replace('    if(ES==0)',"    generate`n    if(ES==0)")
    $parser=$parser.Replace('    assign sf=',"    endgenerate`n    assign sf=")
    [IO.File]::WriteAllText("$folder/src/posit_parser_comb.sv",$parser,[Text.UTF8Encoding]::new($false))
    Copy-Item -LiteralPath "$project/rtl/posit_mac.vh" -Destination "$folder/src/posit_mac.vh"
    'QUARTUS_VERSION = "13.0"','PROJECT_REVISION = "nf"' | Set-Content -Encoding ascii "$folder/nf.qpf"
    $qsf=@('set_global_assignment -name FAMILY "Cyclone IV E"',
        'set_global_assignment -name DEVICE EP4CE30F23C6',
        'set_global_assignment -name TOP_LEVEL_ENTITY posit_mac_nf',
        'set_parameter -name NB 32','set_parameter -name ES 3','set_parameter -name FRAC_W 12',
        'set_parameter -name EXACT_EN 1','set_parameter -name OPS_EN 1',
        'set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files',
        'set_global_assignment -name SDC_FILE nf.sdc',
        "set_global_assignment -name SEED $seed",
        'set_global_assignment -name SEARCH_PATH src')
    foreach($name in $sources) {$qsf+="set_global_assignment -name SYSTEMVERILOG_FILE src/$name.sv"}
    $qsf | Set-Content -Encoding ascii "$folder/nf.qsf"
    @('create_clock -name clk -period 10.000 [get_ports clk]',
        'derive_clock_uncertainty',
        '# Provisional interface budget, not a board constraint: max 0.5ns / min 0.1ns.',
        'set_input_delay -clock clk -max 0.500 [remove_from_collection [all_inputs] [get_ports clk]]',
        'set_input_delay -clock clk -min 0.100 [remove_from_collection [all_inputs] [get_ports clk]]',
        'set_output_delay -clock clk -max 0.500 [all_outputs]',
        'set_output_delay -clock clk -min 0.100 [all_outputs]') | Set-Content -Encoding ascii "$folder/nf.sdc"
    @('project_open nf', 'create_timing_netlist', 'read_sdc', 'update_timing_netlist',
        'report_timing -setup -npaths 10 -detail full_path -file setup_paths.rpt',
        'report_timing -hold -npaths 10 -detail full_path -file hold_paths.rpt',
        'report_ucp -file unconstrained.rpt',
        'delete_timing_netlist','project_close') | Set-Content -Encoding ascii "$folder/detail.tcl"
    Push-Location $folder
    try {
        & "$QuartusBin/quartus_sh.exe" --flow compile nf *> compile.log
        if($LASTEXITCODE) {throw "NF compile failed seed$seed"}
        & "$QuartusBin/quartus_sta.exe" -t detail.tcl *> detail.log
        if($LASTEXITCODE) {throw "NF detailed STA failed seed$seed"}
    } finally {Pop-Location}
    Write-Output "W12 NF POST-ROUTE COMPLETE seed=$seed"
}
$hashes=@{}
foreach($name in @($sources|ForEach-Object {(Resolve-RtlPath $_).Substring($project.Length+1).Replace('\','/')})+@('rtl/posit_mac.vh','scripts/run_week12_nf_ppa.ps1')) {
    $hashes[$name]=(Get-FileHash -LiteralPath "$project/$name" -Algorithm SHA256).Hash.ToLowerInvariant()
}
$hashes | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 "$run/source_sha256.json"
Set-Content -Encoding ascii "$run/status.txt" COMPLETE
