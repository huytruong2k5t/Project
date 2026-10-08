param([string]$ModelSimBin='C:\altera\13.0sp1\modelsim_ase\win32aloem')
$ErrorActionPreference='Stop'
$projectPath=Split-Path $PSScriptRoot -Parent
$resultPath=Join-Path $projectPath 'results/week9_frontend/windows'
$generator=Join-Path $projectPath 'l1/gen_week9_frontend.exe'
if(!(Test-Path -LiteralPath $generator)) {throw 'Build l1/gen_week9_frontend.exe first.'}
New-Item -ItemType Directory -Force $resultPath | Out-Null
function Run-Tool([string]$Path,[string[]]$ToolArguments,[string]$LogName) {
    & $Path @ToolArguments 2>&1 | Tee-Object -FilePath $LogName
    if($LASTEXITCODE -ne 0) {throw "$Path failed: exit=$LASTEXITCODE; see $LogName"}
}
Push-Location $resultPath
try {
    Run-Tool $generator @('.') 'generator.log'
    if((Get-Content -Raw generator.log) -notmatch 'WEEK9 GENERATOR PASS') {throw 'Generator marker missing'}
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-version') 'version.log'
    if(!(Test-Path 'work')) {Run-Tool (Join-Path $ModelSimBin 'vlib.exe') @('work') 'library.log'}
    $sources=@('../../../rtl/lod_lzd_core.sv','../../../rtl/dyn_left_shifter.sv',
        '../../../rtl/ops_sel_comb.sv','../../../rtl/sac_step_comb.sv',
        '../../../tb/ops_frontend_checker.sv','../../../tb/sac_frontend_checker.sv',
        '../../../tb/tb_week9_frontend.sv')
    Run-Tool (Join-Path $ModelSimBin 'vlog.exe') (@('-sv','-work','work')+$sources+@('-l','compile.log')) 'compile_console.log'
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-c','work.tb_week9_frontend','-l','simulate.log','-do','run.do') 'simulate_console.log'
    $log=Get-Content -Raw simulate.log
    if($log -notmatch 'WEEK9 FRONTEND ALL PASS' -or $log -match '\*\*\s+(Error|Fatal):|WEEK9 .*FAIL|timeout') {
        throw 'Week9 frontend simulation failed'
    }
    $opsTotal=0L
    $sacTotal=0L
    $opsMatches=[regex]::Matches($log,'WEEK9 OPS PASS F=(\d+) FW=(\d+) checks=(\d+)')
    $sacMatches=[regex]::Matches($log,'WEEK9 SAC PASS W=(\d+) checks=(\d+)')
    foreach($entry in $opsMatches) {$opsTotal += [long]$entry.Groups[3].Value}
    foreach($entry in $sacMatches) {$sacTotal += [long]$entry.Groups[2].Value}
    $expected=[regex]::Match((Get-Content -Raw generator.log),'WEEK9 GENERATOR PASS ops=(\d+) sac=(\d+)')
    if($opsMatches.Count -ne 5 -or $sacMatches.Count -ne 5 -or
       $opsTotal -ne [long]$expected.Groups[1].Value -or $sacTotal -ne [long]$expected.Groups[2].Value) {
        throw 'Incomplete week9 frontend coverage'
    }
    [pscustomobject]@{date=(Get-Date -Format o);status='PASS';seed=20261008;
        opsChecks=$opsTotal;sacChecks=$sacTotal;mismatches=0;
        oracle='accepted L1 ops_swap/SacState plus independent bit-count and first-set-bit scan';
        simulator=(Get-Content -Raw version.log).Trim();
        scope='combinational OPS/SAC only; no pipeline, Gate2 or original-paper-baseline acceptance';
        command='scripts/verify_week9_frontend_modelsim.ps1'} |
        ConvertTo-Json -Depth 5 | Set-Content summary.json
    $names=@('rtl/lod_lzd_core.sv','rtl/dyn_left_shifter.sv','rtl/ops_sel_comb.sv',
        'rtl/sac_step_comb.sv','tb/ops_frontend_checker.sv','tb/sac_frontend_checker.sv',
        'tb/tb_week9_frontend.sv','l1/include/ops_sel.hpp','l1/include/sac.hpp',
        'l1/test/gen_week9_frontend.cpp','l1/gen_week9_frontend.exe',
        'scripts/verify_week9_frontend_modelsim.ps1')
    $names | ForEach-Object {(Get-FileHash -LiteralPath (Join-Path $projectPath $_) -Algorithm SHA256).Hash.ToLowerInvariant()+'  '+$_} | Set-Content sources.sha256
    Get-ChildItem -Filter '*.txt' | ForEach-Object {(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()+'  '+$_.Name} | Set-Content vectors.sha256
    Write-Output "WEEK9 MODELSIM PASS ops=$opsTotal sac=$sacTotal mismatches=0"
} finally {Pop-Location}
