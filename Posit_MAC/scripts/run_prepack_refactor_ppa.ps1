param(
    [ValidateSet('xc7a35tcpg236-1','xc7a100tcsg324-1')]
    [string]$Part='xc7a35tcpg236-1',
    [ValidatePattern('^results/[a-zA-Z0-9_/-]+$')]
    [string]$RunRoot='results/prepack_refactor_20261016'
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root 'results/prepack_refactor_20261016'
if (!(Test-Path "$out/pilot_status.txt") -or (Get-Content "$out/pilot_status.txt" -Raw).Trim() -ne 'COMPLETE') {throw 'NF pilots incomplete'}
$manifest=Get-Content "$out/source_sha256.json" -Raw | ConvertFrom-Json
foreach($entry in $manifest.PSObject.Properties) {
    if((Get-FileHash -LiteralPath (Join-Path $root $entry.Name)).Hash.ToLowerInvariant() -ne $entry.Value) {throw "Snapshot changed: $($entry.Name)"}
}
if($RunRoot.Contains('..')) {throw 'Invalid RunRoot'}
$run=Join-Path $root "$RunRoot/ppa/$Part"
if(Test-Path "$run/metrics.csv") {throw 'Do not overwrite existing evidence'}
foreach($name in @('tmp','appdata','localappdata')) {New-Item -ItemType Directory -Force "$run/$name" | Out-Null}
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$env:APPDATA="$run/appdata"; $env:LOCALAPPDATA="$run/localappdata"; $env:XILINX_LOCAL_USER_DATA='no'
$lock=@{}
foreach($name in @('scripts/prepack_refactor_ppa.tcl','tb/prepack_nf_ppa_top.sv')) {
    $lock[$name]=(Get-FileHash -LiteralPath (Join-Path $root $name)).Hash.ToLowerInvariant()
}
$lock | ConvertTo-Json | Set-Content -Encoding utf8 "$run/driver_sha256.json"
Push-Location $run
try {
    $arguments=@('-mode','batch','-notrace','-source',"$root/scripts/prepack_refactor_ppa.tcl",
                 '-log','vivado.log','-journal','vivado.jou','-tclargs',$Part)
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' @arguments > console.log
    if($LASTEXITCODE) {throw "Vivado failed: $Part"}
} finally {Pop-Location}
