$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$study=Join-Path $root 'results/opt02b_20261017'
$run=Join-Path $study 'ppa'
foreach($name in @('leaf/status.txt','lint/status.txt','pilot_status.txt')) {
    if(!(Test-Path "$study/$name") -or (Get-Content "$study/$name" -Raw).Trim() -ne 'COMPLETE') {throw "Missing functional prerequisite: $name"}
}
if(Test-Path $run) {throw 'Preserve this one-run output'}
foreach($name in @('source','driver','tmp','appdata','localappdata')) {
    New-Item -ItemType Directory -Force "$run/$name" | Out-Null
}
Copy-Item "$study/source/candidate/*" "$run/source"
Copy-Item "$root/tb/prepack_nf_ppa_top.sv" "$run/driver"
$hashes=@{}
foreach($name in @('scripts/opt02b_a35_ppa.tcl','scripts/run_opt02b_a35_ppa.ps1','tb/prepack_nf_ppa_top.sv')) {
    $hashes[$name]=(Get-FileHash -LiteralPath "$root/$name").Hash.ToLowerInvariant()
}
Copy-Item "$root/scripts/opt02b_a35_ppa.tcl" "$run/driver"
$hashes | ConvertTo-Json | Set-Content -Encoding utf8 "$run/driver_sha256.json"
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$env:APPDATA="$run/appdata"; $env:LOCALAPPDATA="$run/localappdata"; $env:XILINX_LOCAL_USER_DATA='no'
Push-Location $run
try {
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -notrace -source "$run/driver/opt02b_a35_ppa.tcl" -log vivado.log -journal vivado.jou > console.log
    if($LASTEXITCODE) {throw 'Candidate PPA failed; preserve logs'}
} finally {Pop-Location}
