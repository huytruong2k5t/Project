$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$run=Join-Path $root 'results/single_a35_packer_20261017'
if(Test-Path $run) {throw 'One run only: preserve existing output; do not rerun automatically'}
foreach($dir in @('source','driver','tmp','appdata','localappdata')) {
    New-Item -ItemType Directory -Force "$run/$dir" | Out-Null
}
$hashes=@{}
foreach($name in Get-Content "$root/rtl/production.f") {
    if(!$name.Trim()) {continue}
    Copy-Item -LiteralPath "$root/$name" -Destination "$run/source"
    $hashes[$name]=(Get-FileHash -LiteralPath "$root/$name").Hash.ToLowerInvariant()
}
Copy-Item "$root/rtl/posit_mac.vh" "$run/source"
$hashes['rtl/posit_mac.vh']=(Get-FileHash "$root/rtl/posit_mac.vh").Hash.ToLowerInvariant()
foreach($name in @('tb/prepack_nf_ppa_top.sv','scripts/single_a35_packer_sta.tcl','scripts/run_single_a35_packer_sta.ps1')) {
    Copy-Item -LiteralPath "$root/$name" -Destination "$run/driver"
    $hashes[$name]=(Get-FileHash -LiteralPath "$root/$name").Hash.ToLowerInvariant()
}
$hashes | ConvertTo-Json | Set-Content -Encoding utf8 "$run/source_sha256.json"
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$env:APPDATA="$run/appdata"; $env:LOCALAPPDATA="$run/localappdata"
$env:XILINX_LOCAL_USER_DATA='no'
Push-Location $run
try {
    @('Vivado2026.1','xc7a35tcpg236-1','NF32/3 FRAC_W12 EXACT_EN1 OPS_EN1',
      'clock10ns uncertainty0.1ns input2.5ns output0.5ns',
      'one synth_design, one place_design Default, one route_design Default',
      'no RTL modification; no simulation; no seed/directive sweep') | Set-Content -Encoding utf8 conditions.txt
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -notrace -source "$run/driver/single_a35_packer_sta.tcl" -log vivado.log -journal vivado.jou > console.log
    if($LASTEXITCODE) {throw 'Single STA run failed; preserve logs, do not start another run'}
} finally {Pop-Location}
