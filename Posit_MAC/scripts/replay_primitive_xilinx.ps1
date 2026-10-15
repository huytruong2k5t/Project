# Public entry for this frozen study. Do not reuse its checkpoints for new RTL.
param(
    [ValidateSet('check','verify','resume')]
    [string]$Mode = 'check',
    [ValidateSet('xc7a35tcpg236-1','xc7a100tcsg324-1')]
    [string]$Part = 'xc7a35tcpg236-1',
    [string]$Python = 'C:\Users\This PC\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'rtl_paths.ps1')
$root = Split-Path $PSScriptRoot -Parent
$study = Join-Path $root 'results/primitive_xilinx_20261015'
$manifest = Get-Content -LiteralPath (Join-Path $study 'manifest.json') -Raw | ConvertFrom-Json
foreach ($entry in $manifest.sources.PSObject.Properties) {
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-SourcePath $entry.Name)).Hash.ToLowerInvariant()
    if ($actual -ne $entry.Value) {
        throw "Frozen source changed: $($entry.Name). Use a new study directory for new RTL/constraints; do not overwrite this checkpoint."
    }
}
# The implementation consumes these private snapshots, not the current RTL path.
foreach ($variant in @('baseline','candidate')) {
    $sourceDir = if ($variant -eq 'baseline') { 'rtl/common' } else { 'rtl/candidates/primitives' }
    foreach ($name in @('dyn_left_shifter.sv','dyn_right_shifter.sv','lod_lzd_core.sv',
                        'primitive_ppa_top.sv','primitive_ppa_boundary.sv','posit_mac.vh')) {
        $directory = if ($name -like 'primitive_ppa*' -or $name -eq 'posit_mac.vh') { 'rtl' } else { $sourceDir }
        $expected = (Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-SourcePath "$directory/$name")).Hash
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $study "source/$variant/$name")).Hash
        if ($actual -ne $expected) { throw "Implementation snapshot changed: $variant/$name" }
    }
}
# Verify retained reports before any regeneration changes their recorded hashes.
$summaryPath = Join-Path $study 'summary.json'
if (Test-Path -LiteralPath $summaryPath) {
    $summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
    foreach ($entry in $summary.report_sha256.PSObject.Properties) {
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Resolve-SourcePath $entry.Name)).Hash.ToLowerInvariant()
        if ($actual -ne $entry.Value) { throw "Retained report changed: $($entry.Name)" }
    }
}
Push-Location $root
try {
    if ($Mode -eq 'verify') {
        & (Join-Path $PSScriptRoot 'verify_primitive_xilinx.ps1') -Python $Python
        if ($LASTEXITCODE) { throw 'Functional replay failed' }
    } elseif ($Mode -eq 'resume') {
        & (Join-Path $PSScriptRoot 'run_primitive_xilinx_ppa.ps1') -Part $Part
        if ($LASTEXITCODE) { throw 'PPA resume failed' }
    }
    & $Python (Join-Path $PSScriptRoot 'collect_primitive_xilinx.py')
    if ($LASTEXITCODE) { throw 'Evidence audit failed or PPA matrix incomplete' }
} finally { Pop-Location }
