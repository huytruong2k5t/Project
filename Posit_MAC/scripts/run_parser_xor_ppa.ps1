param(
    [ValidateSet('xc7a35tcpg236-1','xc7a100tcsg324-1')]
    [string]$Part = 'xc7a35tcpg236-1',
    [ValidatePattern('^results/[a-zA-Z0-9_/-]+$')]
    [string]$RunRoot = 'results/parser_xor_20261016'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if ($RunRoot.Contains('..')) { throw 'Invalid RunRoot' }
$run = Join-Path $root "$RunRoot/ppa/$Part"
if (Test-Path "$run/metrics.csv") { throw 'Evidence exists; select a fresh RunRoot' }
$lock = Get-Content "$root/results/parser_xor_20261016/study_inputs.json" -Raw | ConvertFrom-Json
foreach ($entry in $lock.PSObject.Properties) {
    if ((Get-FileHash -LiteralPath (Join-Path $root $entry.Name)).Hash.ToLowerInvariant() -ne $entry.Value) {
        throw "Frozen study input changed: $($entry.Name)"
    }
}
foreach ($name in @('tmp','appdata','localappdata')) {
    New-Item -ItemType Directory -Force "$run/$name" | Out-Null
}
$env:TEMP = "$run/tmp"
$env:TMP = $env:TEMP
$env:APPDATA = "$run/appdata"
$env:LOCALAPPDATA = "$run/localappdata"
$env:XILINX_LOCAL_USER_DATA = 'no'
Push-Location $run
try {
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -notrace `
        -source "$root/scripts/parser_xor_ppa.tcl" -log vivado.log `
        -journal vivado.jou -tclargs $Part > console.log
    if ($LASTEXITCODE) { throw "Parser PPA failed: $Part" }
} finally { Pop-Location }
