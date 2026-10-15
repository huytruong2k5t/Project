param([string]$QuartusTool='C:/altera/13.0sp1/quartus/bin64/quartus_sh.exe')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$run=Join-Path $project 'results/ops_refactor_20261014/ppa'
New-Item -ItemType Directory -Force $run | Out-Null
& $QuartusTool --version | Set-Content (Join-Path $run 'version.log')
Set-Content -Encoding ascii (Join-Path $run 'status.txt') RUNNING
$rows=@()
foreach($variant in @('before','after')) {
    foreach($seed in @(1,2,3)) {
        $folder=Join-Path $run "${variant}_seed${seed}"
        New-Item -ItemType Directory -Force $folder | Out-Null
        $source=if($variant -eq 'before') {Join-Path $project 'results/ops_refactor_20261014/before/ops_sel_comb.sv'} else {Join-Path $project 'rtl/multiplier/ops_sel_comb.sv'}
        'QUARTUS_VERSION = "13.0"','PROJECT_REVISION = "ops"' | Set-Content -Encoding ascii (Join-Path $folder 'ops.qpf')
        $qsf=@('set_global_assignment -name FAMILY "Cyclone IV E"',
            'set_global_assignment -name DEVICE EP4CE30F23C6',
            'set_global_assignment -name TOP_LEVEL_ENTITY ops_ppa_top',
            'set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files',
            'set_global_assignment -name SDC_FILE ops.sdc',
            "set_global_assignment -name SEED $seed",
            'set_global_assignment -name NUM_PARALLEL_PROCESSORS 2')
        foreach($file in @($source,(Join-Path $project 'rtl/benchmarks/ops_ppa_boundary.sv'),(Join-Path $project 'rtl/benchmarks/ops_ppa_top.sv'))) {
            $qsf+='set_global_assignment -name SYSTEMVERILOG_FILE "'+$file.Replace('\','/')+'"'
        }
        $qsf+='set_global_assignment -name SEARCH_PATH "'+(Join-Path $project 'rtl').Replace('\','/')+'"'
        $qsf | Set-Content -Encoding ascii (Join-Path $folder 'ops.qsf')
        @('create_clock -name clk -period 10.000 [get_ports clk]','derive_clock_uncertainty') |
            Set-Content -Encoding ascii (Join-Path $folder 'ops.sdc')
        Push-Location $folder
        try {
            & $QuartusTool --flow compile ops *> compile.log
            if($LASTEXITCODE) {throw "Quartus failed $variant seed$seed"}
        } finally {Pop-Location}
        $fit=Get-Content -Raw (Join-Path $folder 'output_files/ops.fit.summary')
        $sta=Get-Content -Raw (Join-Path $folder 'output_files/ops.sta.rpt')
        $lut=[regex]::Match($fit,'Total combinational functions\s*:\s*([\d,]+)')
        $ff=[regex]::Match($fit,'Total registers\s*:\s*([\d,]+)')
        $fmax=[regex]::Match($sta,'(?s)Slow 1200mV 85C Model Fmax Summary\s*;.*?;\s*([0-9.]+) MHz')
        $setup=[regex]::Match($sta,'(?s)Slow 1200mV 85C Model Setup Summary\s*;.*?;\s*clk\s*;\s*(-?[0-9.]+)\s*;')
        if(!$lut.Success -or !$ff.Success -or !$fmax.Success -or !$setup.Success) {throw 'Missing real PPA result'}
        $rows+=[pscustomobject]@{variant=$variant;seed=$seed;LUT4=[int]$lut.Groups[1].Value.Replace(',','');
            registers=[int]$ff.Groups[1].Value.Replace(',','');
            fmax_MHz=[double]::Parse($fmax.Groups[1].Value,[cultureinfo]::InvariantCulture);
            setup_wns_ns=[double]::Parse($setup.Groups[1].Value,[cultureinfo]::InvariantCulture)}
        Write-Output "OPS PPA $variant seed$seed LUT4=$($rows[-1].LUT4) Fmax=$($rows[-1].fmax_MHz)"
    }
}
$hashes=@{}
foreach($name in @('rtl/multiplier/ops_sel_comb.sv','rtl/benchmarks/ops_ppa_boundary.sv','rtl/benchmarks/ops_ppa_top.sv',
    'results/ops_refactor_20261014/before/ops_sel_comb.sv','scripts/run_ops_refactor_ppa.ps1')) {
    $hashes[$name]=(Get-FileHash -LiteralPath (Join-Path $project $name) -Algorithm SHA256).Hash.ToLowerInvariant()
}
[pscustomobject]@{status='PASS';date='2026-10-14';device='EP4CE30F23C6';clock_ns=10;
    profile='F26 FW12 SF_W11 EXACT_EN=OPS_EN=1, dynamic cfg_mode/cfg_ops';
    source_sha256=$hashes;rows=$rows;
    limits='Standalone complete OPS OOC benchmark with identical register banks and physical data I/O, LUT4; not full MAC or Xilinx LUT6. Register-register STA; external I/O delay not constrained, no board/system signoff or power claim.'} |
    ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $run 'summary.json')
Set-Content -Encoding ascii (Join-Path $run 'status.txt') COMPLETE
