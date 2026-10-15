param([string]$ModelSimBin='C:/altera/13.0sp1/modelsim_ase/win32aloem',[switch]$SummarizeOnly)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$run=Join-Path $project 'results/normalize_refactor_20261015/modelsim'
New-Item -ItemType Directory -Force $run | Out-Null
$sources=@('rtl/common/lod_lzd_core.sv','rtl/common/dyn_left_shifter.sv','rtl/adder/posit_add_normalize.sv',
    'rtl/candidates/adder/posit_add_normalize_zero.sv','rtl/candidates/adder/posit_add_normalize_shared.sv',
    'tb/normalize_refactor_checker.sv','tb/tb_normalize_refactor.sv')
Push-Location $run
try {
    if (!$SummarizeOnly) {
        Set-Content -Encoding ascii status.txt RUNNING
        & (Join-Path $ModelSimBin 'vsim.exe') -version | Set-Content version.log
        & (Join-Path $ModelSimBin 'vlib.exe') work | Set-Content library.log
        if($LASTEXITCODE) {throw 'vlib failed'}
        $paths=@($sources|ForEach-Object {Join-Path $project $_})
        & (Join-Path $ModelSimBin 'vlog.exe') -sv -timescale 1ns/1ps -work work @paths -l compile.log | Set-Content compile_console.log
        if($LASTEXITCODE) {throw 'vlog failed'}
        @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
        & (Join-Path $ModelSimBin 'vsim.exe') -c work.tb_normalize_refactor -l simulate.log -wlf local.wlf -do run.do | Set-Content console.log
        if($LASTEXITCODE) {throw 'vsim failed'}
    }
    $transcript=Get-Content -Raw simulate.log
    $profileMatches=[regex]::Matches($transcript,'NORM PASS NB=(\d+) ES=(\d+) SW=(\d+) checks=(\d+) mismatch=0 shifts=(\d+) zero_clean=(\d+) zero_prior=(\d+) nar_zero=(\d+) carry=(\d+) retained_only=(\d+) tail_only=(\d+)')
    if($profileMatches.Count -ne 11 -or $transcript -notmatch 'NORM MATRIX PASS' -or $transcript -match '\*\*\s+(Error|Fatal):') {throw 'Incomplete/failed matrix'}
    $profiles=@($profileMatches|ForEach-Object {
        [pscustomobject]@{NB=[int]$_.Groups[1].Value;ES=[int]$_.Groups[2].Value;SF_W=[int]$_.Groups[3].Value;
            checks=[long]$_.Groups[4].Value;shift_bins=[int]$_.Groups[5].Value;
            zero_clean=[long]$_.Groups[6].Value;zero_prior_inexact=[long]$_.Groups[7].Value;
            nar_zero=[long]$_.Groups[8].Value;carry=[long]$_.Groups[9].Value;
            retained_only=[long]$_.Groups[10].Value;tail_only=[long]$_.Groups[11].Value}
    })
    $hashes=@{}
    foreach($file in @($sources)+@('scripts/verify_normalize_refactor_modelsim.ps1')) {$hashes[$file]=(Get-FileHash -LiteralPath (Join-Path $project $file) -Algorithm SHA256).Hash.ToLowerInvariant()}
    [pscustomobject]@{status='PASS';date='2026-10-15';seed_base=20261015;rng='xorshift32 per profile';
        profiles=$profiles;checks=($profiles|Measure-Object checks -Sum).Sum;candidates=2;mismatches=0;source_sha256=$hashes;
        limits='Known binary inputs; every leading position, full raw signed scale boundaries and dirty special payloads. Small F2/SF_W<=8 enumerates magnitude/scale domain with distributed metadata, not full cross-product formal equivalence.'} |
        ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 summary.json
    Set-Content -Encoding ascii status.txt COMPLETE
    Write-Output "NORM MATRIX PASS checks=$(($profiles|Measure-Object checks -Sum).Sum) candidates=2 mismatch=0"
} finally {Pop-Location}
