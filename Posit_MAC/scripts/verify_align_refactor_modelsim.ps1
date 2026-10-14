param([string]$ModelSimBin='C:/altera/13.0sp1/modelsim_ase/win32aloem',[switch]$SummarizeOnly)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$run=Join-Path $project 'results/align_refactor_20261015/modelsim'
New-Item -ItemType Directory -Force $run | Out-Null
$sources=@('rtl/dyn_right_shifter.sv','rtl/posit_add_align.sv',
    'rtl/posit_add_align_candidate.sv','tb/align_refactor_checker.sv','tb/tb_align_refactor.sv')
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
    & (Join-Path $ModelSimBin 'vsim.exe') -c work.tb_align_refactor -l simulate.log -wlf local.wlf -do run.do | Set-Content console.log
    if($LASTEXITCODE) {throw 'vsim failed'}
    }
    $text=Get-Content -Raw simulate.log
    $profileMatches=[regex]::Matches($text,'ALIGN PASS NB=(\d+) ES=(\d+) SW=(\d+) checks=(\d+) mismatch=0 nar_zero=(\d+) clamp=(\d+) threshold=(\d+) tie=(\d+)')
    if($profileMatches.Count -ne 11 -or $text -notmatch 'ALIGN MATRIX PASS' -or $text -match '\*\*\s+(Error|Fatal):') {throw 'Incomplete/failed matrix'}
    $profiles=@($profileMatches|ForEach-Object {
        [pscustomobject]@{NB=[int]$_.Groups[1].Value;ES=[int]$_.Groups[2].Value;SF_W=[int]$_.Groups[3].Value;
            checks=[long]$_.Groups[4].Value;nar_zero=[long]$_.Groups[5].Value;clamp=[long]$_.Groups[6].Value;
            threshold=[long]$_.Groups[7].Value;tie=[long]$_.Groups[8].Value}
    })
    $hashes=@{}
    foreach($file in @($sources)+@('scripts/verify_align_refactor_modelsim.ps1')) {$hashes[$file]=(Get-FileHash -LiteralPath (Join-Path $project $file) -Algorithm SHA256).Hash.ToLowerInvariant()}
    [pscustomobject]@{status='PASS';date='2026-10-15';seed_base=20261015;rng='xorshift32 per profile';
        profiles=$profiles;checks=($profiles|Measure-Object checks -Sum).Sum;mismatches=0;source_sha256=$hashes;
        limits='Known binary inputs; raw full signed scale range, dirty special payloads; not formal exhaustive HDL proof'} |
        ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 summary.json
    Set-Content -Encoding ascii status.txt COMPLETE
    Write-Output "ALIGN MATRIX PASS checks=$(($profiles|Measure-Object checks -Sum).Sum) mismatch=0"
} finally {Pop-Location}
