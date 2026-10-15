param([string]$QuartusBin='C:/altera/13.0sp1/quartus/bin64')
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$run=Join-Path $project 'results/week12/nf_ppa'
$script=Join-Path $project 'scripts/detail_week12_nf.tcl'
$env:TEMP=Join-Path $run 'tmp'
$env:TMP=$env:TEMP
foreach($seed in @(1,2,3)) {
    Push-Location "$run/baseline_seed$seed"
    try {
        & "$QuartusBin/quartus_sta.exe" -t $script *> stages.log
        if($LASTEXITCODE) {throw "Stage survey failed seed$seed"}
    } finally {Pop-Location}
    Write-Output "W12 NF STAGE SURVEY PASS seed=$seed"
}
