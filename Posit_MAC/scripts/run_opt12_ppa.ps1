param(
    [ValidateSet('reference','adjacent','sentinel','negate')][string]$Variant='sentinel',
    [ValidateSet('Default','Explore','RuntimeOptimized')][string]$Strategy='Default',
    [ValidateSet('nf','f')][string]$Top='nf',
    [ValidateSet('8.000','8.300','10.000')][string]$Period='8.000',
    [ValidatePattern('^[a-zA-Z0-9_]+$')][string]$Attempt='r1'
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$StudyRoot='results/opt120_20261018'
$study=Join-Path $root $StudyRoot
if($Variant -ne 'reference' -and ((Get-Content "$study/unit/$Variant/status.txt" -Raw).Trim() -ne 'COMPLETE')) {throw 'Unit verification must pass before PPA'}
$periodTag=$Period.Replace('.','')
$ppaFolder=if($Top -eq 'f') {'ppa_f'} else {'ppa'}
$run=Join-Path $study "$ppaFolder/$Variant/p$periodTag/${Strategy}_$Attempt"
if(Test-Path $run) {throw 'Preserve existing evidence'}
foreach($name in @('tmp','appdata','localappdata','source/rtl','source/syn/constraints','source/tb')) {
    New-Item -ItemType Directory -Force "$run/$name" | Out-Null
}
$manifest=Get-Content "$root/rtl/production.f"
foreach($path in $manifest) {
    $dst=Join-Path "$run/source" $path
    New-Item -ItemType Directory -Force (Split-Path $dst -Parent) | Out-Null
    Copy-Item -LiteralPath "$study/source/$Variant/$path" -Destination $dst
}
$manifest | Set-Content -Encoding ascii "$run/source/rtl/production.f"
Copy-Item "$study/source/$Variant/rtl/posit_mac.vh" "$run/source/rtl"
Copy-Item "$root/tb/prepack_nf_ppa_top.sv" "$run/source/tb"
Copy-Item "$root/tb/week13_fused_ppa_top.sv" "$run/source/tb"
Copy-Item "$root/syn/constraints/a35t_clock.xdc","$root/syn/constraints/a35t_benchmark_100mhz.xdc" "$run/source/syn/constraints"
$clock=Get-Content "$run/source/syn/constraints/a35t_clock.xdc" -Raw
$clock=$clock.Replace('-period 10.000',"-period $Period")
[IO.File]::WriteAllText("$run/source/syn/constraints/a35t_clock.xdc",$clock)
$flow=Get-Content "$root/syn/run_a35t.tcl" -Raw
$flow=$flow.Replace('benchmark_100mhz',"opt12_p${periodTag}_fixedio")
$flow=$flow.Replace("a35t_opt12_p${periodTag}_fixedio.xdc",'a35t_benchmark_100mhz.xdc')
$flow=$flow.Replace('- 10.0)',"- $Period)")
$flow=$flow.Replace('clock_period_ns=10 ',"clock_period_ns=$Period ")
$flow=$flow.Replace('Fixed 100 MHz benchmark budget','Study-specific clock with unchanged C2 I/O budget')
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
@{contract='A35T-OPT12-HIGHCLOCK-FIXED-IO';variant=$Variant;strategy=$Strategy;top=$Top;part='xc7a35tcpg236-1';
  clock_ns=[double]$Period;input_min_ns=2.5;input_max_ns=2.5;output_min_ns=0;output_max_ns=0.5;
  uncertainty_setup_ns=0.1;uncertainty_hold_ns=0.1;source_sha256=$hashes;
  command="powershell -NoProfile -File scripts/run_opt12_ppa.ps1 -Variant $Variant -Strategy $Strategy -Top $Top -Period $Period -Attempt $Attempt"} |
    ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$run/manifest.json"
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$env:APPDATA="$run/appdata"; $env:LOCALAPPDATA="$run/localappdata"; $env:XILINX_LOCAL_USER_DATA='no'
Push-Location $run
try {
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -notrace -source "$run/source/syn/run_a35t.tcl" -log vivado.log -journal vivado.jou -tclargs $Top "opt12_p${periodTag}_fixedio" implement > console.log
    if($LASTEXITCODE) {throw 'Vivado failed'}
    $toolLog=Get-Content vivado.log -Raw
    if($toolLog -match '(?m)^ERROR:') {throw 'Tool error'}
    foreach($warning in [regex]::Matches($toolLog,'(?m)^CRITICAL WARNING:.*$')) {
        if($warning.Value -notmatch '\[Route 35-39\] The design did not meet timing requirements.') {throw "Unexplained critical warning: $($warning.Value)"}
    }
    # Negative slack remains a measured FAIL, not a script error or timing PASS.
    if((Get-Content status.txt -Raw).Trim() -ne 'COMPLETE') {throw 'No completion marker'}
    Write-Output "OPT12 PPA EXECUTION COMPLETE (inspect slack for PASS/FAIL) $Variant $Strategy"
} finally {Pop-Location}
