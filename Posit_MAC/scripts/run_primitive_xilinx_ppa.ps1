param(
    [ValidateSet('xc7a35tcpg236-1','xc7a100tcsg324-1')]
    [string]$Part = 'xc7a35tcpg236-1',
    [switch]$Smoke,
    [string]$VivadoBin = 'C:\AMDDesignTools\2026.1\Vivado\bin'
)
$ErrorActionPreference='Stop'
$root = Split-Path $PSScriptRoot -Parent
$outRoot = Join-Path $root 'results/primitive_xilinx_20261015'
if (-not (Test-Path -LiteralPath (Join-Path $outRoot 'verification.json'))) {
    throw 'Run verify_primitive_xilinx.ps1 first'
}
$verification = Get-Content -LiteralPath (Join-Path $outRoot 'verification.json') -Raw | ConvertFrom-Json
if ($verification.status -ne 'PASS') { throw 'Unit verification has not passed' }
$manifest = Get-Content -LiteralPath (Join-Path $outRoot 'manifest.json') -Raw | ConvertFrom-Json
foreach ($property in $manifest.sources.PSObject.Properties) {
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root $property.Name)).Hash.ToLowerInvariant()
    if ($actual -ne $property.Value) { throw "Source changed after snapshot: $($property.Name)" }
}
$name = if ($Smoke) { "$Part-smoke" } else { $Part }
$run = Join-Path $outRoot $name
New-Item -ItemType Directory -Force -Path $run | Out-Null
foreach ($dir in @('tmp','appdata','localappdata')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $run $dir) | Out-Null
}
$env:TEMP = Join-Path $run 'tmp'
$env:TMP = $env:TEMP
$env:APPDATA = Join-Path $run 'appdata'
$env:LOCALAPPDATA = Join-Path $run 'localappdata'
$env:XILINX_LOCAL_USER_DATA = 'no'
$arguments = @('-mode','batch','-notrace','-source',(Join-Path $PSScriptRoot 'primitive_xilinx_ppa.tcl'),
    '-log','vivado.log','-journal','vivado.jou','-tclargs',$Part)
if ($Smoke) { $arguments += 'smoke' }
Push-Location $run
try {
    & (Join-Path $VivadoBin 'vivado.bat') @arguments
    if ($LASTEXITCODE) { throw "Vivado failed, exit=$LASTEXITCODE; inspect $run/vivado.log" }
} finally { Pop-Location }
