param(
    [ValidateSet('nf','f')][string]$Variant='nf',
    [ValidateSet('benchmark_100mhz')][string]$Profile='benchmark_100mhz',
    [ValidateSet('validate','synth','implement')][string]$Action='validate',
    [ValidatePattern('^results/[a-zA-Z0-9_/-]+$')][string]$RunRoot='results/a35t_c2_validate_nf'
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$run=Join-Path $root $RunRoot
if(Test-Path -LiteralPath $run) {throw 'Preserve existing results: choose a fresh RunRoot'}
foreach($name in @('tmp','appdata','localappdata','source')) {
    New-Item -ItemType Directory -Force "$run/$name" | Out-Null
}
$paths=@(Get-Content "$root/rtl/production.f")+@('rtl/production.f','rtl/posit_mac.vh',
    'tb/prepack_nf_ppa_top.sv','tb/week13_fused_ppa_top.sv','syn/run_a35t.tcl',
    'syn/constraints/a35t_clock.xdc','syn/constraints/a35t_benchmark_100mhz.xdc','scripts/run_a35t_sta.ps1')
$hashes=@{}
foreach($name in ($paths | Sort-Object -Unique)) {
    $dst=Join-Path "$run/source" $name
    New-Item -ItemType Directory -Force (Split-Path $dst -Parent) | Out-Null
    Copy-Item -LiteralPath (Join-Path $root $name) -Destination $dst
    $hashes[$name]=(Get-FileHash -LiteralPath $dst).Hash.ToLowerInvariant()
}
@{contract='A35T-C2';part='xc7a35tcpg236-1';variant=$Variant;profile=$Profile;action=$Action;
  run_root=$RunRoot;input_min_ns=2.5;input_max_ns=2.5;output_min_ns=0;output_max_ns=0.5;implementation='Default';random_seed_override=$null;
  command="./scripts/run_a35t_sta.ps1 -Variant $Variant -Profile $Profile -Action $Action -RunRoot $RunRoot";
  source_sha256=$hashes} | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 "$run/manifest.json"
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$env:APPDATA="$run/appdata"; $env:LOCALAPPDATA="$run/localappdata"; $env:XILINX_LOCAL_USER_DATA='no'
Push-Location $run
try {
    $argsList=@('-mode','batch','-notrace','-source',"$run/source/syn/run_a35t.tcl",'-log','vivado.log','-journal','vivado.jou','-tclargs',$Variant,$Profile,$Action)
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' @argsList > console.log
    if($LASTEXITCODE) {throw 'A35T flow failed; preserve logs'}
    if((Get-Content vivado.log -Raw) -match '(?m)^(ERROR|CRITICAL WARNING):') {
        'FAILED' | Set-Content status.txt
        throw 'Constraint/tool errors or critical warnings; do not accept completion marker'
    }
    $expected=if($Action -eq 'validate') {'VALIDATED'} else {'COMPLETE'}
    if((Get-Content status.txt -Raw).Trim() -ne $expected) {throw 'Missing completion marker'}
} finally {Pop-Location}
