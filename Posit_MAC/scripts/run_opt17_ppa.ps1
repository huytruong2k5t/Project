param(
    [ValidateSet('opt17_nf_ref','opt17_f_ref','opt17_nf','opt17_f','opt17_nf_3p','opt17_f_3p')]
    [string]$Top='opt17_nf'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$runRoot = Join-Path $projectRoot "results/opt17_20261029/ppa/$Top"
if (!(Test-Path -LiteralPath "$runRoot/manifest.json")) { throw 'Run prepare-ppa first' }
if (Test-Path -LiteralPath "$runRoot/vivado.log") { throw 'Preserve existing PPA attempt' }
$manifest = Get-Content -LiteralPath "$runRoot/manifest.json" -Raw | ConvertFrom-Json
foreach ($entry in $manifest.source_sha256.PSObject.Properties) {
    if ((Get-FileHash -LiteralPath (Join-Path $runRoot $entry.Name)).Hash.ToLowerInvariant() -ne $entry.Value) {
        throw "PPA source changed: $($entry.Name)"
    }
}
foreach ($name in @('tmp','appdata','localappdata')) {
    New-Item -ItemType Directory -Force "$runRoot/$name" | Out-Null
}
$env:TEMP = "$runRoot/tmp"
$env:TMP = $env:TEMP
$env:APPDATA = "$runRoot/appdata"
$env:LOCALAPPDATA = "$runRoot/localappdata"
$env:XILINX_LOCAL_USER_DATA = 'no'
Push-Location $runRoot
try {
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -notrace -source source/flow.tcl -log vivado.log -journal vivado.jou > console.log
    if ($LASTEXITCODE) { throw 'Vivado PPA failed; preserve logs/reports' }
    if (!(Test-Path -LiteralPath status.txt) -or (Get-Content -LiteralPath status.txt -Raw).Trim() -ne 'COMPLETE') {
        throw 'PPA completion marker missing'
    }
    Write-Output "OPT17 PPA COMPLETE $Top (inspect timing; completion is not signoff)"
} finally { Pop-Location }
