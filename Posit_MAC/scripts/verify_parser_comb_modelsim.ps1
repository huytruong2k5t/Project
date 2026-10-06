param([string]$ModelSimBin='C:\altera\13.0sp1\modelsim_ase\win32aloem')
$ErrorActionPreference='Stop'
$projectPath=Split-Path $PSScriptRoot -Parent
$resultPath=Join-Path $projectPath 'results/parser_comb'
$generator=Join-Path $projectPath 'l1/gen_parser_vectors.exe'
if(!(Test-Path -LiteralPath $generator)) {throw 'Build l1/gen_parser_vectors.exe with make gen_parser_vectors.exe first.'}
New-Item -ItemType Directory -Force $resultPath | Out-Null
function Run-Tool([string]$Path,[string[]]$ToolArguments,[string]$LogName) {
    & $Path @ToolArguments 2>&1 | Tee-Object -FilePath $LogName
    if($LASTEXITCODE -ne 0) {throw "$Path failed: exit=$LASTEXITCODE; see $LogName"}
}
Push-Location $resultPath
try {
    Run-Tool $generator @('.') 'generator.log'
    if((Get-Content -Raw generator.log) -notmatch 'GENERATOR PASS total=2465812') {throw 'Generator acceptance marker missing'}
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-version') 'version.log'
    if(!(Test-Path 'work')) {Run-Tool (Join-Path $ModelSimBin 'vlib.exe') @('work') 'library.log'}
    $sources=@('../../rtl/lod_lzd_core.sv','../../rtl/dyn_left_shifter.sv',
        '../../rtl/posit_parser_comb.sv','../../tb/tb_posit_parser_comb.sv')
    Run-Tool (Join-Path $ModelSimBin 'vlog.exe') (@('-sv','-work','work')+$sources+@('-l','compile.log')) 'compile_console.log'
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-c','work.tb_posit_parser_comb','-l','simulate.log','-do','run.do') 'simulate_console.log'
    $log=Get-Content -Raw simulate.log
    if($log -notmatch 'PARSER_COMB ALL PASS' -or $log -match '\*\*\s+(Error|Fatal):|PARSER FAIL|timeout') {throw 'Parser simulation failed'}
    $suites=@()
    foreach($match in [regex]::Matches($log,'PARSER PASS NB=(\d+) ES=(\d+) checks=(\d+)')) {
        $suites += [pscustomobject]@{NB=[int]$match.Groups[1].Value;ES=[int]$match.Groups[2].Value;checks=[long]$match.Groups[3].Value}
    }
    $total=($suites | Measure-Object checks -Sum).Sum
    if($suites.Count -ne 4 -or $total -ne 2465812) {throw 'Incomplete parser acceptance'}
    [pscustomobject]@{date=(Get-Date -Format o);status='PASS';seed=20261005;checks=$total;
        mismatches=0;oracle='accepted L1 plus independent sequential field decoder';
        softposit='not linked: pure parser field comparison';suites=$suites;
        simulator=(Get-Content -Raw version.log).Trim();
        generatorCommand='l1/gen_parser_vectors.exe results/parser_comb';
        compileCommand='vlog -sv -work work ../../rtl/lod_lzd_core.sv ../../rtl/dyn_left_shifter.sv ../../rtl/posit_parser_comb.sv ../../tb/tb_posit_parser_comb.sv -l compile.log';
        simulationCommand='vsim -c work.tb_posit_parser_comb -l simulate.log -do run.do'} |
        ConvertTo-Json -Depth 5 | Set-Content summary.json
    $names=@('rtl/lod_lzd_core.sv','rtl/dyn_left_shifter.sv','rtl/posit_parser_comb.sv',
        'tb/tb_posit_parser_comb.sv','l1/include/posit_parser.hpp','l1/include/posit_types.hpp',
        'l1/test/gen_parser_vectors.cpp','l1/gen_parser_vectors.exe','scripts/verify_parser_comb_modelsim.ps1')
    $names | ForEach-Object {(Get-FileHash -LiteralPath (Join-Path $projectPath $_) -Algorithm SHA256).Hash.ToLowerInvariant()+'  '+$_} | Set-Content sources.sha256
    Get-ChildItem -Filter 'parser_*.txt' | ForEach-Object {(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()+'  '+$_.Name} | Set-Content vectors.sha256
    Write-Output "PARSER MODELSIM PASS checks=$total mismatches=0"
} finally {Pop-Location}
