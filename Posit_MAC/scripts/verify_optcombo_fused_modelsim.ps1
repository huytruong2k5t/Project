$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$study=Join-Path $root 'results/optcombo_20261018'
$run=Join-Path $study 'fused_event_v2'
if(Test-Path $run) {throw 'Preserve existing evidence'}
New-Item -ItemType Directory -Force "$run/tmp" | Out-Null
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$bin='C:/altera/13.0sp1/modelsim_ase/win32aloem'
$sources=@(Get-ChildItem "$study/source/combined/*.sv" | Where-Object {$_.Name -notin @('lod_lzd_core.sv','mac_f_wrapper.sv')} | ForEach-Object {$_.FullName})
# Same unsigned width in an assertion; old ModelSim rejects parameter-sized casts.
$compat=Get-Content "$study/source/combined/mac_f_wrapper.sv" -Raw
$compat=$compat.Replace('    localparam int I_W = $clog2(FRAC_W+1);',
    '    localparam int I_W = $clog2(FRAC_W+1); typedef logic [I_W-1:0] iteration_cast_t;')
$compat=$compat.Replace("I_W'(N_MAX)","iteration_cast_t'(N_MAX)")
[IO.File]::WriteAllText("$run/mac_f_wrapper.sv",$compat)
$sources+="$run/mac_f_wrapper.sv"
$sources+="$study/modelsim/compat/lod_lzd_core.sv"
$sources+="$root/tb/tb_week13_fused_event.sv"
$vectors="$study/fused/pilot.vectors"
if(!(Test-Path $vectors)) {throw 'Generate pilot vectors first'}
(Get-FileHash $vectors).Hash | Set-Content "$run/vector_sha256.txt"
Push-Location $run
try {
    & "$bin/vsim.exe" -version > version.log
    & "$bin/vlib.exe" work > library.log
    if($LASTEXITCODE) {throw 'vlib failed'}
    & "$bin/vlog.exe" -sv -timescale 1ns/1ps "+incdir+$study/source/combined" -work work @sources -l compile.log > compile_console.log
    if($LASTEXITCODE) {throw 'vlog failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    & "$bin/vsim.exe" -c work.tb_week13_fused_event "+VECTORS=$vectors" -do run.do -l simulate.log -wlf local.wlf > console.log
    if($LASTEXITCODE) {throw 'Fused event failed'}
    $log=Get-Content simulate.log -Raw
    if($log -notmatch 'W13_EVENT_PASS' -or $log -match '\*\*\s+(Error|Fatal):') {throw 'No fused event PASS'}
    Write-Output ($log -split "`n" | Where-Object {$_ -match 'W13_EVENT_PASS'})
    'COMPLETE' | Set-Content status.txt
} finally {Pop-Location}
