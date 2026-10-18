$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$study=Join-Path $root 'results/opt02c_20261018'
$run=Join-Path $study 'release_checks_v2'
if(Test-Path $run) {throw 'Preserve existing checks'}
foreach($name in @('tmp','appdata','localappdata')) {New-Item -ItemType Directory -Force "$run/$name" | Out-Null}
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$env:APPDATA="$run/appdata"; $env:LOCALAPPDATA="$run/localappdata"; $env:XILINX_LOCAL_USER_DATA='no'
Copy-Item "$root/scripts/check_opt02c_release.tcl" "$run/driver.tcl"
$nf="$study/ppa/candidate/Default/routed.dcp"
$f="$study/ppa_f/candidate/Default/routed.dcp"
@{nf=(Get-FileHash $nf).Hash;f=(Get-FileHash $f).Hash;driver=(Get-FileHash "$run/driver.tcl").Hash} |
    ConvertTo-Json | Set-Content -Encoding utf8 "$run/input_sha256.json"
Push-Location $run
try {
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -notrace -source driver.tcl -log vivado.log -journal vivado.jou -tclargs $nf $f > console.log
    if($LASTEXITCODE) {throw 'Release check failed'}
    if((Get-Content vivado.log -Raw) -match '(?m)^(ERROR|CRITICAL WARNING):') {throw 'Release check tool issue'}
    if((Get-Content status.txt -Raw).Trim() -ne 'COMPLETE') {throw 'No completion marker'}
    'NF/F structural release checks complete'
} finally {Pop-Location}
