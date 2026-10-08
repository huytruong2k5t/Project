param(
    [string]$ModelSimBin = 'C:/altera/13.0sp1/modelsim_ase/win32aloem'
)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$resultPath = Join-Path $projectPath 'results/packer_p2_optimization'
$sources = @('rtl/posit_pack_finish.sv',
    'results/packer_p2_optimization/posit_pack_finish_reference.sv',
    'tb/packer_finish_equivalence_checker.sv',
    'tb/tb_packer_finish_equivalence.sv')
Push-Location $resultPath
try {
    if (!(Test-Path work)) { & "$ModelSimBin/vlib.exe" work }
    & "$ModelSimBin/vlog.exe" -sv -timescale 1ns/1ps ($sources | ForEach-Object { Join-Path $projectPath $_ }) *> equivalence_compile.log
    if ($LASTEXITCODE -ne 0) { throw 'P2 equivalence compile failed' }
    @('onerror {quit -code 1}', 'onbreak {quit -code 1}',
      'run -all', 'quit -code 0') | Set-Content -Encoding ascii equivalence.do
    & "$ModelSimBin/vsim.exe" -c work.tb_packer_finish_equivalence -do equivalence.do *> equivalence.log
    if ($LASTEXITCODE -ne 0) { throw 'P2 equivalence simulation failed' }
    $log = Get-Content -Raw equivalence.log
    if ($log -notmatch 'P2 EQUIVALENCE ALL PASS' -or $log -match '\*\*\s+(Error|Fatal):') {
        throw 'P2 equivalence incomplete'
    }
    $sources | ForEach-Object {
        (Get-FileHash (Join-Path $projectPath $_)).Hash.ToLowerInvariant() + '  ' + $_
    } | Set-Content equivalence_sources.sha256
    & "$ModelSimBin/vsim.exe" -version *> equivalence_version.log
    [pscustomobject]@{status='PASS'; date='2026-10-07'; seed=20261007;
        checks=1448576; scope='NB8 exhaustive binary inputs; NB16/32 100000 random rows each; both modes';
        reference='archived pre-optimization P2, not an independent arithmetic oracle'} |
        ConvertTo-Json | Set-Content equivalence_summary.json
    Write-Output 'P2 EQUIVALENCE PASS checks=1448576'
} finally { Pop-Location }
