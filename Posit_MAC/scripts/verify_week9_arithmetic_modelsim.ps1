param([string]$ModelSimBin='C:\altera\13.0sp1\modelsim_ase\win32aloem')
$ErrorActionPreference='Stop'
$projectPath=Split-Path $PSScriptRoot -Parent
$resultPath=Join-Path $projectPath 'results/week9_arithmetic/windows'
New-Item -ItemType Directory -Force $resultPath | Out-Null
function Run-Tool([string]$Path,[string[]]$ToolArguments,[string]$LogName) {
    & $Path @ToolArguments 2>&1 | Tee-Object -FilePath $LogName
    if($LASTEXITCODE -ne 0) {throw "$Path failed: exit=$LASTEXITCODE; see $LogName"}
}
Push-Location $resultPath
try {
    Run-Tool (Join-Path $projectPath 'l1/gen_week9_arithmetic.exe') @('.') 'generator.log'
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-version') 'version.log'
    if(!(Test-Path work)) {Run-Tool (Join-Path $ModelSimBin 'vlib.exe') @('work') 'library.log'}
    $sources=@('../../../rtl/sbm_shift_comb.sv','../../../rtl/sbm_accum_comb.sv',
        '../../../rtl/mul_norm_comb.sv','../../../tb/arithmetic_checker.sv',
        '../../../tb/tb_week9_arithmetic.sv')
    Run-Tool (Join-Path $ModelSimBin 'vlog.exe') (@('-sv','-work','work')+$sources+@('-l','compile.log')) 'compile_console.log'
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-c','work.tb_week9_arithmetic','-l','simulate.log','-do','run.do') 'simulate_console.log'
    $log=Get-Content -Raw simulate.log
    if($log -notmatch 'WEEK9 ARITHMETIC ALL PASS' -or $log -match '\*\*\s+(Error|Fatal):') {throw 'Arithmetic verification failed'}
    $matches=[regex]::Matches($log,'ARITHMETIC PASS F=(\d+) scheme=(\d+) rows=(\d+)')
    $rows=0L
    foreach($entry in $matches) {$rows += [long]$entry.Groups[3].Value}
    $expected=[regex]::Match((Get-Content -Raw generator.log),'rows=(\d+)')
    if($matches.Count -ne 10 -or $rows -ne [long]$expected.Groups[1].Value) {throw 'Incomplete coverage'}
    [pscustomobject]@{status='PASS';date=(Get-Date -Format o);seed=20261009;rows=$rows;
        mismatches=0;simulator=(Get-Content -Raw version.log).Trim();
        scope='W9-03 combinational shifter/accumulator/normalize/packer adapter; not Gate2';
        command='scripts/verify_week9_arithmetic_modelsim.ps1'} |
        ConvertTo-Json | Set-Content summary.json
} finally {Pop-Location}
