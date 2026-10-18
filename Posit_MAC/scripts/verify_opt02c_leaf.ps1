$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root 'results/opt02c_20261018'
$run=Join-Path $out 'leaf'
if(Test-Path $run) {throw 'Preserve prior leaf evidence'}
New-Item -ItemType Directory -Force "$run/tmp" | Out-Null
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$bin='C:/altera/13.0sp1/modelsim_ase/win32aloem'
$before=Get-Content "$out/source/production/posit_add_align.sv" -Raw
$before=$before.Replace('module posit_add_align #(', 'module posit_add_align_before #(')
[IO.File]::WriteAllText("$out/posit_add_align_before.sv",$before)
$sources=@("$out/source/production/dyn_right_shifter.sv", "$out/posit_add_align_before.sv",
    "$out/source/candidate/posit_add_align.sv", "$root/tb/opt02b_align_checker.sv", "$root/tb/tb_opt02b_align.sv")
Push-Location $run
try {
    & "$bin/vsim.exe" -version > version.log
    & "$bin/vlib.exe" work > library.log
    if($LASTEXITCODE) {throw 'vlib failed'}
    & "$bin/vlog.exe" -sv -timescale 1ns/1ps -work work @sources -l compile.log > compile_console.log
    if($LASTEXITCODE) {throw 'vlog failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    & "$bin/vsim.exe" -c work.tb_opt02b_align -do run.do -l simulate.log -wlf local.wlf > console.log
    if($LASTEXITCODE) {throw 'leaf simulation failed'}
    $text=Get-Content simulate.log -Raw
    if($text -notmatch 'ALIGN MATRIX PASS' -or $text -match '\*\*\s+(Error|Fatal):') {throw 'Missing leaf PASS'}
    Write-Output ($text -split "`n" | Where-Object {$_ -match 'ALIGN PASS|ALIGN MATRIX PASS'})
    'COMPLETE' | Set-Content status.txt
} finally {Pop-Location}
