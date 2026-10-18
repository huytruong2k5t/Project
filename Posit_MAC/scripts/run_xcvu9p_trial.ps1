param(
    [ValidateSet('nf','f')][string]$Top='nf',
    [ValidatePattern('^[A-Za-z0-9_]+$')][string]$Attempt='initial',
    [switch]$PrepareOnly
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$suffix=if($Attempt -eq 'initial') {''} else {"_$Attempt"}
$run=Join-Path $root "results/xcvu9p_trial_20261018/${Top}_p8300_Explore$suffix"
if(!(Test-Path "$run/manifest.json")) {
    if($suffix) {& python "$PSScriptRoot/prepare_xcvu9p_trial.py" $Top $Attempt}
    else {& python "$PSScriptRoot/prepare_xcvu9p_trial.py" $Top}
    if($LASTEXITCODE) {throw 'Preparation/release audit failed'}
}
if($PrepareOnly) {Write-Output "PREPARED ONLY: $run"; return}
if(Test-Path "$run/vivado.log") {throw 'Preserve existing run/logs; use a reviewed new attempt'}
$manifest=Get-Content "$run/manifest.json" -Raw | ConvertFrom-Json
if($manifest.status -ne 'PREPARED_NOT_SYNTHESIZED') {throw 'Unexpected manifest state'}
if((Get-FileHash "$root/rtl/production_freeze.json").Hash.ToLowerInvariant() -ne $manifest.release_sha256) {
    throw 'Active release changed: do not run stale preparation'
}
foreach($entry in $manifest.source_sha256.PSObject.Properties) {
    if((Get-FileHash (Join-Path "$run/source" $entry.Name)).Hash.ToLowerInvariant() -ne $entry.Value) {
        throw "Snapshot hash changed: $($entry.Name)"
    }
}
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$env:APPDATA="$run/appdata"; $env:LOCALAPPDATA="$run/localappdata"
$env:XILINX_LOCAL_USER_DATA='no'
Push-Location $run
try {
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -notrace -source "$run/source/syn/run_xcvu9p.tcl" -log vivado.log -journal vivado.jou -tclargs $Top xcvu9p_trial implement > console.log
    $code=$LASTEXITCODE
    $text=Get-Content vivado.log -Raw
    if($code -or $text -match '(?m)^ERROR:|Device files unavailable:') {throw 'Vivado failed: inspect retained log'}
    if(!(Test-Path status.txt) -or (Get-Content status.txt -Raw).Trim() -ne 'COMPLETE') {throw 'Implementation incomplete'}
    Write-Output 'Execution complete; inspect timing.rpt and r2r_* before claiming timing PASS'
} finally {Pop-Location}
