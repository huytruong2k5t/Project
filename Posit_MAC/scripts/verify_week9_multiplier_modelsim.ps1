param([string]$ModelSimBin='C:\altera\13.0sp1\modelsim_ase\win32aloem',
      [long]$PerProfile=2000,[string]$RunName='pilot')
$ErrorActionPreference='Stop'
if($RunName -notmatch '^[a-z0-9_-]+$' -or $PerProfile -lt 100) {throw 'Invalid run arguments'}
$projectPath=Split-Path $PSScriptRoot -Parent
$resultPath=Join-Path $projectPath "results/week9_multiplier/$RunName"
New-Item -ItemType Directory -Force $resultPath | Out-Null
function Run-Tool([string]$Path,[string[]]$ToolArguments,[string]$LogName) {
    & $Path @ToolArguments 2>&1 | Tee-Object -FilePath $LogName
    if($LASTEXITCODE -ne 0) {throw "$Path failed: exit=$LASTEXITCODE; see $LogName"}
}
Push-Location $resultPath
try {
    Run-Tool (Join-Path $projectPath 'l1/gen_week9_multiplier.exe') @('.',[string]$PerProfile) 'generator.log'
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-version') 'version.log'
    if(!(Test-Path work)) {Run-Tool (Join-Path $ModelSimBin 'vlib.exe') @('work') 'library.log'}
    $sources=@('lod_lzd_core','dyn_left_shifter','dyn_right_shifter','posit_parser',
        'ops_sel_comb','sac_step_comb','sbm_shift_comb','sbm_accum_comb','iter_ctrl','sbm_accum',
        'mul_iter_core','mul_norm_comb','posit_pack_prepare','posit_pack_finish','posit_pack',
        'mul_iter_wrapper','posit_mul_iter') | ForEach-Object {"../../../rtl/$_.sv"}
    $sources+=@('../../../tb/multiplier_checker.sv','../../../tb/tb_week9_multiplier.sv')
    Run-Tool (Join-Path $ModelSimBin 'vlog.exe') (@('-sv','-timescale','1ns/1ps','+incdir+../../../rtl','-work','work')+$sources+@('-l','compile.log')) 'compile_console.log'
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-c','work.tb_week9_multiplier','-l','simulate.log','-do','run.do') 'simulate_console.log'
    $log=Get-Content -Raw simulate.log
    if($log -notmatch 'WEEK9 MULTIPLIER ALL PASS' -or $log -match '\*\*\s+(Error|Fatal):') {throw 'Multiplier verification failed'}
    $matches=[regex]::Matches($log,'MULTIPLIER PASS NB=(\d+) ES=(\d+) scheme=(\d+) rounding=(\d+) rows=(\d+) completed=(\d+) reset_aborts=(\d+)')
    $rows=0L; $completed=0L; $aborts=0L
    foreach($entry in $matches) {
        $rows += [long]$entry.Groups[5].Value
        $completed += [long]$entry.Groups[6].Value
        $aborts += [long]$entry.Groups[7].Value
    }
    if($matches.Count -ne 16 -or $rows -ne 16*$PerProfile -or $rows -ne $completed+$aborts) {throw 'Incomplete coverage'}
    [pscustomobject]@{status='PASS';date=(Get-Date -Format o);seed=20261009;
        fixtureRows=$rows;comparedTransactions=$completed;resetAborts=$aborts;
        mismatches=0;simulator=(Get-Content -Raw version.log).Trim();
        Gate2=if($completed -ge 10000000){'numerical threshold reached; lint and coverage review still required'}else{'not accepted: less than 10^7 compared transactions'};
        scope='integrated standalone multiplier, four formats, two schemes, RNE/TRUNC, reset/stall/order/latency';
        command="scripts/verify_week9_multiplier_modelsim.ps1 -PerProfile $PerProfile -RunName $RunName"} |
        ConvertTo-Json | Set-Content summary.json
} finally {Pop-Location}
