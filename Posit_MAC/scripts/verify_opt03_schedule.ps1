param([ValidatePattern('^results/[a-zA-Z0-9_/-]+$')][string]$RunRoot='results/opt03_20261017')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if($RunRoot.Contains('..')) {throw 'Invalid RunRoot'}
$run=Join-Path $root "$RunRoot/modelsim"
$bin='C:/altera/13.0sp1/modelsim_ase/win32aloem'
if(!(Test-Path "$run/status.txt")) {throw 'Run verify_opt03_modelsim.ps1 first'}
if(Test-Path "$run/schedule_status.txt") {throw 'Preserve prior evidence'}
$env:TMP="$run/tmp"; $env:TEMP=$env:TMP
Push-Location $run
try {
    & "$bin/vlog.exe" -sv -timescale 1ns/1ps -work work "$root/tb/tb_opt03_schedule.sv" -l schedule_compile.log > schedule_compile_console.log
    if($LASTEXITCODE) {throw 'Schedule compile failed'}
    foreach($profile in @(@(8,0),@(16,1),@(32,2),@(32,3))) {
        $nb=$profile[0]; $es=$profile[1]
        & "$bin/vsim.exe" -c work.tb_opt03_schedule "-gNB=$nb" "-gES=$es" -l "schedule_${nb}_${es}.log" -wlf "schedule_${nb}_${es}.wlf" -do run.do > "schedule_console_${nb}_${es}.log"
        $log=Get-Content "schedule_${nb}_${es}.log" -Raw
        if($LASTEXITCODE -or $log -notmatch 'OPT03 SCHEDULE PASS' -or $log -match '\*\*\s+(Fatal|Error):') {throw "Schedule FAIL $nb/$es"}
        Write-Output ($log -split "`n" | Where-Object {$_ -match 'OPT03 SCHEDULE PASS'})
    }
    'COMPLETE' | Set-Content schedule_status.txt
} finally {Pop-Location}
