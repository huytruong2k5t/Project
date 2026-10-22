param(
    [ValidatePattern('^[A-Za-z0-9_]+$')][string]$RunLabel = 'modelsim_replay',
    [ValidatePattern('^[A-Za-z0-9_]+$')][string]$EventLabel = 'event_replay'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$studyRoot = Join-Path $projectRoot 'results/fixed32_3_20261022'
$unitRoot = Join-Path $studyRoot 'units'
$runRoot = Join-Path $unitRoot $RunLabel
if (Test-Path -LiteralPath $runRoot) { throw 'Preserve existing unit simulation' }
New-Item -ItemType Directory -Force "$runRoot/tmp" | Out-Null
$env:TEMP = "$runRoot/tmp"
$env:TMP = $env:TEMP
$bin = 'C:/altera/13.0sp1/modelsim_ase/win32aloem'
$sources = @(Get-ChildItem -LiteralPath "$studyRoot/$EventLabel/source/rtl" -Filter '*.sv' | ForEach-Object FullName)
$sources += @(Get-ChildItem -LiteralPath "$unitRoot/reference" -Filter '*.sv' | ForEach-Object FullName)
$sources += "$projectRoot/tb/tb_fixed32_3_units.sv"
Push-Location $runRoot
try {
    & "$bin/vsim.exe" -version > version.log
    & "$bin/vlib.exe" work > library.log
    & "$bin/vlog.exe" -sv -timescale 1ns/1ps "+incdir+$studyRoot/$EventLabel/source/rtl" -work work @sources -l compile.log > compile_console.log
    if ($LASTEXITCODE) { throw 'Unit compile failed' }
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') |
        Set-Content -Encoding ascii run.do
    & "$bin/vsim.exe" -c work.tb_fixed32_3_units -do run.do -l simulation.log -wlf units.wlf > console.log
    if ($LASTEXITCODE) { throw 'Unit simulation failed' }
    $text = Get-Content -LiteralPath simulation.log -Raw
    if ($text -notmatch 'FIXED32_UNITS_PASS' -or $text -match '\*\*\s+(Error|Fatal):') { throw 'Unit acceptance missing' }
    $text -split "`n" | Where-Object { $_ -match 'FIXED32_UNITS_PASS' }
    'PASS' | Set-Content status.txt
} finally { Pop-Location }
