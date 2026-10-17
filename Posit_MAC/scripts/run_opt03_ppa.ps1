param(
    [ValidateSet('xc7a35tcpg236-1','xc7a100tcsg324-1')]
    [string]$Part='xc7a35tcpg236-1',
    [ValidatePattern('^results/[a-zA-Z0-9_/-]+$')]
    [string]$RunRoot='results/opt03_20261017',
    [switch]$Resume
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root 'results/opt03_20261017'
if (!(Test-Path "$out/pilot_status.txt") -or (Get-Content "$out/pilot_status.txt" -Raw).Trim() -ne 'COMPLETE') {throw 'NF pilots incomplete'}
foreach($variant in @('baseline','candidate')) {
    $manifest=Get-Content "$out/${variant}_sha256.json" -Raw | ConvertFrom-Json
    foreach($entry in $manifest.PSObject.Properties) {
        if((Get-FileHash -LiteralPath "$out/source/$variant/$($entry.Name)").Hash.ToLowerInvariant() -ne $entry.Value) {throw 'Snapshot changed'}
    }
}
if($RunRoot.Contains('..')) {throw 'Invalid RunRoot'}
$run=Join-Path $root "$RunRoot/ppa/$Part"
if(Test-Path "$run/metrics.csv") {
    if(!$Resume) {throw 'Do not overwrite existing evidence'}
    $rows=@(Import-Csv "$run/metrics.csv")
    if($rows.Count -ne 1 -or $rows[0].variant -ne 'candidate' -or $rows[0].strategy -ne 'default' -or !(Test-Path "$run/candidate_synth.dcp")) {throw 'Only resume a completed Default followed by checkpoint-open failure'}
    if(Test-Path "$run/driver_sha256_default.json") {throw 'Preserve previous resume'}
    Copy-Item "$run/driver_sha256.json" "$run/driver_sha256_default.json"
    Copy-Item "$run/console.log" "$run/console_default.log"
    Copy-Item "$run/vivado.log" "$run/vivado_default.log"
    (Get-FileHash "$run/candidate_synth.dcp").Hash.ToLowerInvariant() | Set-Content "$run/checkpoint.sha256"
} elseif($Resume) {throw 'No Default result to resume'}
foreach($name in @('tmp','appdata','localappdata')) {New-Item -ItemType Directory -Force "$run/$name" | Out-Null}
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$env:APPDATA="$run/appdata"; $env:LOCALAPPDATA="$run/localappdata"; $env:XILINX_LOCAL_USER_DATA='no'
$lock=@{}
foreach($name in @('scripts/opt03_ppa.tcl','tb/prepack_nf_ppa_top.sv')) {
    $lock[$name]=(Get-FileHash -LiteralPath (Join-Path $root $name)).Hash.ToLowerInvariant()
}
$lock | ConvertTo-Json | Set-Content -Encoding utf8 "$run/driver_sha256.json"
Push-Location $run
try {
    $arguments=@('-mode','batch','-notrace','-source',"$root/scripts/opt03_ppa.tcl",
                 '-log','vivado.log','-journal','vivado.jou','-tclargs',$Part)
    if($Resume) {$arguments+='resume'}
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' @arguments > console.log
    if($LASTEXITCODE) {throw "Vivado failed: $Part"}
} finally {Pop-Location}
