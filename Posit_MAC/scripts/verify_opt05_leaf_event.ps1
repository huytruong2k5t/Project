$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$study=Join-Path $root 'results/opt05_20261017'
$run=Join-Path $study 'leaf_event'
if(Test-Path $run) {throw 'Preserve existing evidence'}
New-Item -ItemType Directory -Force "$run/source","$run/tmp" | Out-Null
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$variants=@('baseline','a','ab','abc_sub','abc_tree')
foreach($v in $variants) {
    $text=Get-Content "$study/source/$v/sac_step_comb.sv" -Raw
    $text=$text.Replace('module sac_step_comb #(',"module sac_step_$v #(")
    [IO.File]::WriteAllText("$run/source/sac_step_$v.sv",$text)
}
# ModelSim10.1d syntax adapter only for inactive group4 sized casts.
$lod=Get-Content "$study/source/baseline/lod_lzd_core.sv" -Raw
$lod=$lod.Replace("POS_W'(group_index)","pos_cast_t'(group_index)").Replace("S'(pos_tree[LEVELS][0])","count_cast_t'(pos_tree[LEVELS][0])")
$lod=$lod.Replace('assign match_bits =', 'typedef logic [POS_W-1:0] pos_cast_t; typedef logic [S-1:0] count_cast_t; assign match_bits =')
[IO.File]::WriteAllText("$run/source/lod_lzd_core.sv",$lod)
Copy-Item "$study/source/baseline/dyn_left_shifter.sv","$root/tb/opt05_sac_checker.sv" "$run/source"
$bin='C:/altera/13.0sp1/modelsim_ase/win32aloem'
Push-Location $run
try {
    & "$bin/vsim.exe" -version > version.log
    & "$bin/vlib.exe" work > library.log
    if($LASTEXITCODE) {throw 'vlib failed'}
    $sources=@(Get-ChildItem source/*.sv | ForEach-Object {$_.FullName})
    & "$bin/vlog.exe" -sv -timescale 1ns/1ps -work work @sources -l compile.log > compile_console.log
    if($LASTEXITCODE) {throw 'vlog failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run 100000 ns','quit -code 0') | Set-Content -Encoding ascii run.do
    foreach($profile in @(@(1,1),@(5,3),@(12,4),@(26,5),@(27,7))) {
        $w=$profile[0]; $sw=$profile[1]
        & "$bin/vsim.exe" -c work.opt05_sac_checker "-gW=$w" "-gS=$sw" -do run.do -l "simulate_${w}_${sw}.log" -wlf "event_${w}_${sw}.wlf" > "console_${w}_${sw}.log"
        if($LASTEXITCODE) {throw 'SAC simulation failed'}
        $log=Get-Content "simulate_${w}_${sw}.log" -Raw
        if($log -notmatch 'SAC PASS' -or $log -match '\*\*\s+(Error|Fatal):') {throw 'No PASS'}
        Write-Output ($log -split "`n" | Where-Object {$_ -match 'SAC PASS'})
    }
    'COMPLETE' | Set-Content status.txt
    Write-Output 'SAC MATRIX PASS'
} finally {Pop-Location}
