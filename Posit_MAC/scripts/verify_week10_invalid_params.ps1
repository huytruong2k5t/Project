param([string]$ModelSimBin = 'C:\altera\13.0sp1\modelsim_ase\win32aloem')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$run=Join-Path $root 'results/week10_adder/invalid_params'
New-Item -ItemType Directory -Force $run | Out-Null
Push-Location $run
try {
    Set-Content -Encoding ascii run_status.txt RUNNING
    & (Join-Path $ModelSimBin 'vlib.exe') work | Set-Content library.log
    if($LASTEXITCODE) {throw 'vlib failed'}
    $sources=@('lod_lzd_core','dyn_left_shifter','dyn_right_shifter','posit_add_align','posit_add_arith','posit_add_normalize','posit_add_comb') | ForEach-Object {Join-Path $root "rtl/$_.sv"}
    $sources+=Join-Path $root 'tb/tb_week10_invalid_params.sv'
    $sourceHashes = @{}
    foreach ($source in $sources) {
        $key = $source.Substring($root.Length + 1).Replace('\','/')
        $sourceHashes[$key] = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $sourceHashes['rtl/posit_mac.vh'] = (Get-FileHash -LiteralPath (Join-Path $root 'rtl/posit_mac.vh') -Algorithm SHA256).Hash.ToLowerInvariant()
    $sourceHashes | ConvertTo-Json | Set-Content -Encoding utf8 source_sha256.json
    & (Join-Path $ModelSimBin 'vlog.exe') -sv -timescale 1ns/1ps "+incdir+$root/rtl" -work work @sources -l compile.log | Set-Content compile_console.log
    if($LASTEXITCODE) {throw 'vlog failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    foreach($case in 0..2) {
        & (Join-Path $ModelSimBin 'vsim.exe') -c work.tb_week10_invalid_params "-gCASE=$case" -l "case_$case.log" -wlf "case_$case.wlf" -do run.do | Set-Content "console_$case.log"
        $text=Get-Content "case_$case.log" -Raw
        if($text -notmatch 'unsupported parameters' -or $text -match 'INVALID CONFIG WAS NOT REJECTED') {throw "Invalid case not rejected: $case"}
        Write-Output "W10 INVALID PARAM PASS case=$case rejected at initialization"
    }
    Set-Content -Encoding ascii run_status.txt COMPLETE
} finally {Pop-Location}
