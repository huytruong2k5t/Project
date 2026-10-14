param([string]$QuartusTool='C:/altera/13.0sp1/quartus/bin64/quartus_sh.exe')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$run=Join-Path $project 'results/align_refactor_20261015/ppa'
New-Item -ItemType Directory -Force $run | Out-Null
& $QuartusTool --version | Set-Content (Join-Path $run 'version.log')
Set-Content -Encoding ascii (Join-Path $run 'status.txt') RUNNING
$rows=@()
foreach($variant in @('before','candidate')) {
    foreach($seed in @(1,2,3)) {
        $folder=Join-Path $run "${variant}_seed${seed}"
        $src=Join-Path $folder 'src'
        New-Item -ItemType Directory -Force $src | Out-Null
        $source=if($variant -eq 'before') {Join-Path $project 'results/align_refactor_20261015/before/posit_add_align.sv'} else {Join-Path $project 'rtl/posit_add_align_candidate.sv'}
        $text=Get-Content -LiteralPath $source -Raw
        $text=$text.Replace('module posit_add_align_candidate #(','module posit_add_align #(')
        [IO.File]::WriteAllText((Join-Path $src 'posit_add_align.sv'),$text,[Text.UTF8Encoding]::new($false))
        foreach($name in @('dyn_right_shifter.sv','align_ppa_boundary.sv','align_ppa_top.sv','posit_mac.vh')) {
            Copy-Item -LiteralPath (Join-Path $project "rtl/$name") -Destination (Join-Path $src $name)
        }
        'QUARTUS_VERSION = "13.0"','PROJECT_REVISION = "align"' | Set-Content -Encoding ascii (Join-Path $folder 'align.qpf')
        $qsf=@('set_global_assignment -name FAMILY "Cyclone IV E"',
            'set_global_assignment -name DEVICE EP4CE30F23C6',
            'set_global_assignment -name TOP_LEVEL_ENTITY align_ppa_top',
            'set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files',
            'set_global_assignment -name SDC_FILE align.sdc',
            "set_global_assignment -name SEED $seed",
            'set_global_assignment -name NUM_PARALLEL_PROCESSORS 2',
            'set_global_assignment -name SEARCH_PATH src')
        foreach($name in @('dyn_right_shifter','posit_add_align','align_ppa_boundary','align_ppa_top')) {
            $qsf+='set_global_assignment -name SYSTEMVERILOG_FILE src/'+$name+'.sv'
        }
        $qsf | Set-Content -Encoding ascii (Join-Path $folder 'align.qsf')
        @('create_clock -name clk -period 10.000 [get_ports clk]','derive_clock_uncertainty') |
            Set-Content -Encoding ascii (Join-Path $folder 'align.sdc')
        Push-Location $folder
        try {
            & $QuartusTool --flow compile align *> compile.log
            if($LASTEXITCODE) {throw "Quartus failed $variant seed$seed"}
        } finally {Pop-Location}
        $fit=Get-Content -Raw (Join-Path $folder 'output_files/align.fit.summary')
        $sta=Get-Content -Raw (Join-Path $folder 'output_files/align.sta.rpt')
        $lut=[regex]::Match($fit,'Total combinational functions\s*:\s*([\d,]+)')
        $ff=[regex]::Match($fit,'Total registers\s*:\s*([\d,]+)')
        $fmax=[regex]::Match($sta,'(?s)Slow 1200mV 85C Model Fmax Summary\s*;.*?;\s*([0-9.]+) MHz')
        $setup=[regex]::Match($sta,'(?s)Slow 1200mV 85C Model Setup Summary\s*;.*?;\s*clk\s*;\s*(-?[0-9.]+)\s*;')
        if(!$lut.Success -or !$ff.Success -or !$fmax.Success -or !$setup.Success) {throw 'Missing physical PPA result'}
        $rows+=[pscustomobject]@{variant=$variant;seed=$seed;LUT4=[int]$lut.Groups[1].Value.Replace(',','');
            registers=[int]$ff.Groups[1].Value.Replace(',','');
            fmax_MHz=[double]::Parse($fmax.Groups[1].Value,[cultureinfo]::InvariantCulture);
            setup_wns_ns=[double]::Parse($setup.Groups[1].Value,[cultureinfo]::InvariantCulture)}
        Write-Output "ALIGN PPA $variant seed$seed LUT4=$($rows[-1].LUT4) FF=$($rows[-1].registers) Fmax=$($rows[-1].fmax_MHz) WNS=$($rows[-1].setup_wns_ns)"
    }
}
$hashes=@{}
foreach($name in @('rtl/posit_add_align.sv','rtl/posit_add_align_candidate.sv','rtl/dyn_right_shifter.sv',
    'rtl/align_ppa_boundary.sv','rtl/align_ppa_top.sv','rtl/posit_mac.vh',
    'results/align_refactor_20261015/before/posit_add_align.sv','scripts/run_align_refactor_ppa.ps1')) {
    $hashes[$name]=(Get-FileHash -LiteralPath (Join-Path $project $name) -Algorithm SHA256).Hash.ToLowerInvariant()
}
[pscustomobject]@{status='MEASURED';date='2026-10-15';device='EP4CE30F23C6';clock_ns=10;
    profile='NB32/ES3 F26 SF_W11; full raw alignment I/O; identical input/output banks';
    source_sha256=$hashes;rows=$rows;
    limits='Standalone alignment OOC physical LUT4 benchmark, not complete adder/MAC or Xilinx LUT6. Register-register STA; no external I/O delays, board signoff or power claim.'} |
    ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $run 'summary.json')
Set-Content -Encoding ascii (Join-Path $run 'status.txt') COMPLETE
