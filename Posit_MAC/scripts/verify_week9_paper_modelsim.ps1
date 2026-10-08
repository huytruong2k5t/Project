param([string]$ModelSimBin='C:\altera\13.0sp1\modelsim_ase\win32aloem')
$ErrorActionPreference='Stop'
$projectPath=Split-Path $PSScriptRoot -Parent
$resultPath=Join-Path $projectPath 'results/week9_paper/windows'
New-Item -ItemType Directory -Force $resultPath | Out-Null
function Run-Tool([string]$Path,[string[]]$ToolArguments,[string]$LogName) {
    & $Path @ToolArguments 2>&1 | Tee-Object -FilePath $LogName
    if($LASTEXITCODE -ne 0) {throw "$Path failed: exit=$LASTEXITCODE; see $LogName"}
}
Push-Location $resultPath
try {
    Run-Tool (Join-Path $projectPath 'l1/gen_week9_paper.exe') @('../../paper_discriminators/linux/vectors.csv','.') 'generator.log'
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-version') 'version.log'
    if(!(Test-Path work)) {Run-Tool (Join-Path $ModelSimBin 'vlib.exe') @('work') 'library.log'}
    $sources=@('../../../rtl/lod_lzd_core.sv','../../../rtl/dyn_left_shifter.sv',
        '../../../rtl/dyn_right_shifter.sv','../../../rtl/posit_parser_comb.sv',
        '../../../rtl/posit_pack_prepare.sv','../../../rtl/posit_pack_finish.sv',
        '../../../rtl/posit_pack_comb.sv','../../../rtl/paper_ops_comb.sv',
        '../../../rtl/paper_step_comb.sv','../../../tb/tb_week9_paper.sv')
    Run-Tool (Join-Path $ModelSimBin 'vlog.exe') (@('-sv','-work','work')+$sources+@('-l','compile.log')) 'compile_console.log'
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-c','work.tb_week9_paper','-l','simulate.log','-do','run.do') 'simulate_console.log'
    $log=Get-Content -Raw simulate.log
    if($log -notmatch 'WEEK9 PAPER PASS' -or $log -notmatch 'PAPER PT2 LUT PASS entries=128' -or $log -match '\*\*\s+(Error|Fatal):') {throw 'Paper verification failed'}
    $actual=[regex]::Match($log,'commits=(\d+) outputs=(\d+) Fig4=(\d+)')
    $expected=[regex]::Match((Get-Content -Raw generator.log),'records=(\d+) unique=(\d+) commits=(\d+)')
    if($actual.Groups[1].Value -ne $expected.Groups[3].Value -or $actual.Groups[2].Value -ne $expected.Groups[1].Value) {throw 'Incomplete coverage'}
    [pscustomobject]@{status='PASS';date=(Get-Date -Format o);seed='frozen discriminator corpus';commits=[int]$actual.Groups[1].Value;
        records=[int]$actual.Groups[2].Value;uniqueCases=[int]$expected.Groups[2].Value;Fig4='0x1ae34000';pt2Entries=128;
        mismatches=0;simulator=(Get-Content -Raw version.log).Trim();
        scope='W9-R1/R2 functional reconstruction only, not original author RTL or Table I acceptance';
        command='scripts/verify_week9_paper_modelsim.ps1'} |
        ConvertTo-Json | Set-Content summary.json
} finally {Pop-Location}
