param(
    [ValidateSet('production','candidate')][string]$Variant='production',
    [ValidateSet('results/opt02c_20261018')][string]$StudyRoot='results/opt02c_20261018',
    [ValidateSet('Default','Explore','RuntimeOptimized')][string]$Strategy='Default',
    [ValidateSet('nf','f')][string]$Top='nf'
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$study=Join-Path $root $StudyRoot
$ppaFolder=if($Top -eq 'f') {'ppa_f'} else {'ppa'}
$run=Join-Path $study "$ppaFolder/$Variant/$Strategy"
if(Test-Path $run) {throw 'Preserve existing evidence'}
foreach($name in @('tmp','appdata','localappdata','source/rtl','source/syn/constraints','source/tb')) {
    New-Item -ItemType Directory -Force "$run/$name" | Out-Null
}
$manifest=Get-Content "$study/reference_production.f"
foreach($extra in @('posit_product_pack.sv','posit_magnitude_parse.sv')) {
    if(Test-Path "$study/source/$Variant/$extra") {$manifest+="rtl/mac_nf/$extra"}
}
foreach($path in $manifest) {
    $dst=Join-Path "$run/source" $path
    New-Item -ItemType Directory -Force (Split-Path $dst -Parent) | Out-Null
    Copy-Item -LiteralPath "$study/source/$Variant/$(Split-Path $path -Leaf)" -Destination $dst
}
$manifest | Set-Content -Encoding ascii "$run/source/rtl/production.f"
Copy-Item "$study/source/$Variant/posit_mac.vh" "$run/source/rtl"
Copy-Item "$root/tb/prepack_nf_ppa_top.sv" "$run/source/tb"
Copy-Item "$root/tb/week13_fused_ppa_top.sv" "$run/source/tb"
Copy-Item "$root/syn/constraints/a35t_clock.xdc","$root/syn/constraints/a35t_benchmark_100mhz.xdc" "$run/source/syn/constraints"
$flow=Get-Content "$root/syn/run_a35t.tcl" -Raw
$flow=$flow.Replace('place_design -directive Default',"place_design -directive $Strategy")
$flow=$flow.Replace('route_design -directive Default',"route_design -directive $(if($Strategy -eq 'RuntimeOptimized') {'Default'} else {$Strategy})")
# Reuse the established physical bank classifier, not old constraints/implementation.
$banks=Get-Content "$root/scripts/nf_all_stages_sta.tcl" -Raw
$banks=$banks.Substring($banks.IndexOf('proc classify'))
$banks=$banks.Substring(0,$banks.IndexOf('set f [open status.txt'))
$banks="set outputs [get_ports -filter {DIRECTION == OUT}]`n"+$banks
if($Top -eq 'nf') {
    $flow=$flow.Replace('# COMPLETE means execution complete, not timing PASS. Inspect timing/coverage.',
        $banks+"`n# COMPLETE means execution complete, not timing PASS. Inspect timing/coverage.")
}
$flow=$flow.Replace('# COMPLETE means execution complete, not timing PASS. Inspect timing/coverage.',
    "report_cdc -details -file cdc.rpt`n# COMPLETE means execution complete, not timing PASS. Inspect timing/coverage.")
[IO.File]::WriteAllText("$run/source/syn/run_a35t.tcl",$flow)
$hashes=@{}
Get-ChildItem "$run/source" -Recurse -File | ForEach-Object {
    $hashes[$_.FullName.Substring(("$run/source/").Length)]=(Get-FileHash $_.FullName).Hash.ToLowerInvariant()
}
@{contract='A35T-C2';variant=$Variant;strategy=$Strategy;top=$Top;part='xc7a35tcpg236-1';
  clock_ns=10;input_min_ns=2.5;input_max_ns=2.5;output_min_ns=0;output_max_ns=0.5;
  uncertainty_setup_ns=0.1;uncertainty_hold_ns=0.1;source_sha256=$hashes;
  command="powershell -NoProfile -File scripts/run_opt02c_ppa.ps1 -StudyRoot $StudyRoot -Variant $Variant -Strategy $Strategy -Top $Top"} |
    ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$run/manifest.json"
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$env:APPDATA="$run/appdata"; $env:LOCALAPPDATA="$run/localappdata"; $env:XILINX_LOCAL_USER_DATA='no'
Push-Location $run
try {
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -notrace -source "$run/source/syn/run_a35t.tcl" -log vivado.log -journal vivado.jou -tclargs $Top benchmark_100mhz implement > console.log
    if($LASTEXITCODE) {throw 'Vivado failed'}
    if((Get-Content vivado.log -Raw) -match '(?m)^(ERROR|CRITICAL WARNING):') {throw 'Tool error/critical warning'}
    if((Get-Content status.txt -Raw).Trim() -ne 'COMPLETE') {throw 'No completion marker'}
    Write-Output "OPT02C PPA COMPLETE $Variant $Strategy"
} finally {Pop-Location}
