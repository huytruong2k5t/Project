param([string]$ModelSimBin='C:/altera/13.0sp1/modelsim_ase/win32aloem')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$run=Join-Path $project 'results/ops_refactor_20261014'
$model=Join-Path $run 'modelsim'
New-Item -ItemType Directory -Force $model | Out-Null
$old=Get-Content -LiteralPath (Join-Path $run 'before/ops_sel_comb.sv') -Raw
$reference=Join-Path $model 'ops_sel_before.sv'
[IO.File]::WriteAllText($reference,$old.Replace('module ops_sel_comb #(','module ops_sel_before #('),[Text.UTF8Encoding]::new($false))
$sources=@((Join-Path $project 'rtl/ops_sel_comb.sv'),$reference,
    (Join-Path $project 'tb/ops_refactor_checker.sv'),(Join-Path $project 'tb/tb_ops_refactor.sv'))
Push-Location $model
try {
    Set-Content -Encoding ascii run_status.txt RUNNING
    & (Join-Path $ModelSimBin 'vsim.exe') -version | Set-Content version.log
    & (Join-Path $ModelSimBin 'vlib.exe') work | Set-Content library.log
    if($LASTEXITCODE) {throw 'vlib failed'}
    & (Join-Path $ModelSimBin 'vlog.exe') -sv -timescale 1ns/1ps -work work @sources -l compile.log | Set-Content compile_console.log
    if($LASTEXITCODE) {throw 'vlog failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    $text=''
    foreach($full in 1..27) {
        & (Join-Path $ModelSimBin 'vsim.exe') -c work.tb_ops_refactor "-gFULL_TEST=$full" -l "simulate_$full.log" -wlf "matrix_$full.wlf" -do run.do | Set-Content "console_$full.log"
        if($LASTEXITCODE) {throw "vsim failed F=$full"}
        $part=Get-Content -Raw "simulate_$full.log"
        if($part -notmatch "OPS REFACTOR BATCH PASS F=$full mismatch=0") {throw "batch failed F=$full"}
        $text+=$part
        Write-Output "OPS matrix batch F=$full PASS"
    }
    $text | Set-Content -Encoding utf8 simulate.log
    $matches=[regex]::Matches($text,'OPS REFACTOR PASS F=(\d+) FW=(\d+) SW=(\d+) WW=(\d+) checks=(\d+) mismatch=0')
    if($matches.Count -ne 382 -or $text -match '\*\*\s+(Error|Fatal):') {throw 'incomplete or failed matrix'}
    $profiles=@($matches | ForEach-Object {
        [pscustomobject]@{F=[int]$_.Groups[1].Value;FW=[int]$_.Groups[2].Value;
            SF_W=[int]$_.Groups[3].Value;WIDTH_W=[int]$_.Groups[4].Value;checks=[long]$_.Groups[5].Value}
    })
    $hashes=@{}
    foreach($source in $sources) {
        $key=$source.Substring($project.Length+1).Replace('\','/')
        $hashes[$key]=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $hashes['results/ops_refactor_20261014/before/ops_sel_comb.sv']=(Get-FileHash -LiteralPath (Join-Path $run 'before/ops_sel_comb.sv') -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject]@{status='PASS';date='2026-10-14';fraction_pairs=378;extra_width_profiles=4;
        feature_combinations=4;checks=($profiles|Measure-Object -Property checks -Sum).Sum;mismatches=0;
        seed_base=20261014;rng='per-profile xorshift32';profiles=$profiles;source_sha256=$hashes;
        limits='Binary controls/data; exhaustive fraction pairs for F<=5; directed/random for F>5; no formal solver available'} |
        ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 summary.json
    Set-Content -Encoding ascii run_status.txt COMPLETE
    Write-Output "OPS MATRIX PASS profiles=382 checks=$(($profiles|Measure-Object -Property checks -Sum).Sum) mismatch=0"
} finally {Pop-Location}
