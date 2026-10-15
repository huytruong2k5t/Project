param([string]$QuartusTool='C:/altera/13.0sp1/quartus/bin64/quartus_sh.exe')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'rtl_paths.ps1')
$project=Split-Path $PSScriptRoot -Parent
$run=Join-Path $project 'results/normalize_refactor_20261015/ppa'
New-Item -ItemType Directory -Force $run | Out-Null
& $QuartusTool --version | Set-Content (Join-Path $run 'version.log')
Set-Content -Encoding ascii (Join-Path $run 'status.txt') RUNNING
$rows=@()
foreach($variant in @('before','zero','shared')) {
    foreach($seed in @(1,2,3)) {
        $folder=Join-Path $run "${variant}_seed${seed}"
        $src=Join-Path $folder 'src'
        New-Item -ItemType Directory -Force $src | Out-Null
        $source=if($variant -eq 'before') {'results/normalize_refactor_20261015/before/posit_add_normalize.sv'} else {"rtl/candidates/adder/posit_add_normalize_${variant}.sv"}
        $code=Get-Content -LiteralPath (Join-Path $project $source) -Raw
        if($variant -ne 'before') {$code=$code.Replace("module posit_add_normalize_${variant} #(",'module posit_add_normalize #(')}
        [IO.File]::WriteAllText((Join-Path $src 'posit_add_normalize.sv'),$code,[Text.UTF8Encoding]::new($false))
        foreach($name in @('lod_lzd_core.sv','dyn_left_shifter.sv','normalize_ppa_boundary.sv','normalize_ppa_top.sv','posit_mac.vh')) {
            Copy-Item -LiteralPath (Resolve-RtlPath $name) -Destination (Join-Path $src $name)
        }
        'QUARTUS_VERSION = "13.0"','PROJECT_REVISION = "normalize"' | Set-Content -Encoding ascii (Join-Path $folder 'normalize.qpf')
        $qsf=@('set_global_assignment -name FAMILY "Cyclone IV E"',
            'set_global_assignment -name DEVICE EP4CE30F23C6',
            'set_global_assignment -name TOP_LEVEL_ENTITY normalize_ppa_top',
            'set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files',
            'set_global_assignment -name SDC_FILE normalize.sdc',
            "set_global_assignment -name SEED $seed",
            'set_global_assignment -name NUM_PARALLEL_PROCESSORS 2',
            'set_global_assignment -name SEARCH_PATH src')
        foreach($name in @('lod_lzd_core','dyn_left_shifter','posit_add_normalize','normalize_ppa_boundary','normalize_ppa_top')) {
            $qsf+='set_global_assignment -name SYSTEMVERILOG_FILE src/'+$name+'.sv'
        }
        $qsf | Set-Content -Encoding ascii (Join-Path $folder 'normalize.qsf')
        @('create_clock -name clk -period 10.000 [get_ports clk]','derive_clock_uncertainty') |
            Set-Content -Encoding ascii (Join-Path $folder 'normalize.sdc')
        Push-Location $folder
        try {
            & $QuartusTool --flow compile normalize *> compile.log
            if($LASTEXITCODE) {throw "Quartus failed $variant seed$seed"}
        } finally {Pop-Location}
        $fit=Get-Content -Raw (Join-Path $folder 'output_files/normalize.fit.summary')
        $sta=Get-Content -Raw (Join-Path $folder 'output_files/normalize.sta.rpt')
        $lut=[regex]::Match($fit,'Total combinational functions\s*:\s*([\d,]+)')
        $ff=[regex]::Match($fit,'Total registers\s*:\s*([\d,]+)')
        $fmax=[regex]::Match($sta,'(?s);\s*Slow 1200mV 85C Model Fmax Summary.*?;\s*([0-9.]+) MHz')
        $setup=[regex]::Match($sta,'(?s);\s*Slow 1200mV 85C Model Setup Summary.*?;\s*clk\s*;\s*(-?[0-9.]+)\s*;')
        if(!$lut.Success -or !$ff.Success -or !$fmax.Success -or !$setup.Success) {throw 'Missing physical PPA result'}
        $rows+=[pscustomobject]@{variant=$variant;seed=$seed;LUT4=[int]$lut.Groups[1].Value.Replace(',','');
            registers=[int]$ff.Groups[1].Value.Replace(',','');
            fmax_MHz=[double]::Parse($fmax.Groups[1].Value,[cultureinfo]::InvariantCulture);
            setup_wns_ns=[double]::Parse($setup.Groups[1].Value,[cultureinfo]::InvariantCulture)}
        # Preserve partial measurements if a subsequent compile cannot finish.
        $rows | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $run 'rows.json')
        Write-Output "NORM PPA $variant seed$seed LUT4=$($rows[-1].LUT4) FF=$($rows[-1].registers) Fmax=$($rows[-1].fmax_MHz) WNS=$($rows[-1].setup_wns_ns)"
    }
}
$hashes=@{}
foreach($name in @('rtl/adder/posit_add_normalize.sv','rtl/candidates/adder/posit_add_normalize_zero.sv','rtl/candidates/adder/posit_add_normalize_shared.sv',
    'rtl/common/lod_lzd_core.sv','rtl/common/dyn_left_shifter.sv','rtl/benchmarks/normalize_ppa_boundary.sv','rtl/benchmarks/normalize_ppa_top.sv','rtl/posit_mac.vh',
    'results/normalize_refactor_20261015/before/posit_add_normalize.sv','scripts/run_normalize_refactor_ppa.ps1')) {
    $hashes[$name]=(Get-FileHash -LiteralPath (Join-Path $project $name) -Algorithm SHA256).Hash.ToLowerInvariant()
}
[pscustomobject]@{status='MEASURED';date='2026-10-15';device='EP4CE30F23C6';clock_ns=10;
    profile='NB32/ES3 F26 SF_W11; full raw normalization I/O; identical input/output banks';
    source_sha256=$hashes;rows=$rows;
    limits='Standalone normalization OOC physical LUT4 benchmark, not full adder/MAC or Xilinx LUT6. Register-register STA; no external I/O delays, board signoff or power claim.'} |
    ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $run 'summary.json')
Set-Content -Encoding ascii (Join-Path $run 'status.txt') COMPLETE
