$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$study=Join-Path $root 'results/opt02b_20261017'
$run=Join-Path $root 'results/nf_all_stages_20261017'
if(Test-Path $run) {throw 'Preserve existing measurement; do not overwrite'}
if((Get-Content "$study/ppa/status.txt" -Raw).Trim() -ne 'COMPLETE') {throw 'Missing candidate checkpoint'}
foreach($name in @('source','driver','tmp','appdata','localappdata')) {
    New-Item -ItemType Directory -Force "$run/$name" | Out-Null
}
Copy-Item "$study/ppa/source/*" "$run/source"
Copy-Item "$study/ppa/driver/prepack_nf_ppa_top.sv" "$run/driver"
Copy-Item "$PSScriptRoot/nf_all_stages_sta.tcl" "$run/driver"
Copy-Item $PSCommandPath "$run/driver"
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$env:APPDATA="$run/appdata"; $env:LOCALAPPDATA="$run/localappdata"; $env:XILINX_LOCAL_USER_DATA='no'
Push-Location $run
try {
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -notrace -source "$run/driver/nf_all_stages_sta.tcl" -log vivado.log -journal vivado.jou > console.log
    if($LASTEXITCODE) {throw 'STA failed; preserve routed checkpoint and logs'}
} finally {Pop-Location}
