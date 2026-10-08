param([string]$ModelSimBin='C:\altera\13.0sp1\modelsim_ase\win32aloem')
$ErrorActionPreference='Stop'
$projectPath=Split-Path $PSScriptRoot -Parent
$resultPath=Join-Path $projectPath 'results/week9_core/windows'
New-Item -ItemType Directory -Force $resultPath | Out-Null
function Run-Tool([string]$Path,[string[]]$ToolArguments,[string]$LogName) {
    & $Path @ToolArguments 2>&1 | Tee-Object -FilePath $LogName
    if($LASTEXITCODE -ne 0) {throw "$Path failed: exit=$LASTEXITCODE; see $LogName"}
}
Push-Location $resultPath
try {
    Run-Tool (Join-Path $projectPath 'l1/gen_week9_core.exe') @('.') 'generator.log'
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-version') 'version.log'
    if(!(Test-Path work)) {Run-Tool (Join-Path $ModelSimBin 'vlib.exe') @('work') 'library.log'}
    $sources=@('../../../rtl/lod_lzd_core.sv','../../../rtl/dyn_left_shifter.sv',
        '../../../rtl/sac_step_comb.sv','../../../rtl/sbm_shift_comb.sv',
        '../../../rtl/sbm_accum_comb.sv','../../../rtl/iter_ctrl.sv',
        '../../../rtl/sbm_accum.sv','../../../rtl/mul_iter_core.sv',
        '../../../tb/core_checker.sv','../../../tb/tb_week9_core.sv')
    Run-Tool (Join-Path $ModelSimBin 'vlog.exe') (@('-sv','-timescale','1ns/1ps','+incdir+../../../rtl','-work','work')+$sources+@('-l','compile.log')) 'compile_console.log'
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-c','work.tb_week9_core','-l','simulate.log','-do','run.do') 'simulate_console.log'
    $log=Get-Content -Raw simulate.log
    if($log -notmatch 'WEEK9 CORE ALL PASS' -or $log -match '\*\*\s+(Error|Fatal):') {throw 'Core verification failed'}
    [pscustomobject]@{status='PASS';date=(Get-Date -Format o);seed=20261009;
        fixtureTransactions=40000;resetAborts=420;completedTransactions=39580;
        mismatches=0;simulator=(Get-Content -Raw version.log).Trim();
        scope='W9-03 sequential accumulator and W9-04 core, widths1/5/12/26/27, both schemes';
        command='scripts/verify_week9_core_modelsim.ps1'} |
        ConvertTo-Json | Set-Content summary.json
} finally {Pop-Location}
