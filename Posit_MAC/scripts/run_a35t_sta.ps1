param(
    [ValidateSet('nf','f')][string]$Variant='nf',
    [ValidateSet('ip_ooc','integration')][string]$Profile='ip_ooc',
    [ValidateSet('validate','synth','implement')][string]$Action='validate',
    [ValidatePattern('^results/[a-zA-Z0-9_/-]+$')][string]$RunRoot='results/a35t_c1_validate_nf',
    [string]$IoXdc=''
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$run=Join-Path $root $RunRoot
if(Test-Path -LiteralPath $run) {throw 'Preserve existing results: choose a fresh RunRoot'}
if($Profile -eq 'integration' -and !$IoXdc) {throw 'Integration requires configured IoXdc; no default min/max'}
if($Profile -eq 'ip_ooc' -and $IoXdc) {throw 'ip_ooc has no I/O delay assumptions'}
if($IoXdc) {
    $resolved=(Resolve-Path -LiteralPath (Join-Path $root $IoXdc)).Path
    if(!$resolved.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetExtension($resolved) -ne '.xdc') {
        throw 'IoXdc must be an XDC inside Posit_MAC'
    }
    $IoXdc=$resolved.Substring($root.Length+1).Replace('\','/')
}
foreach($name in @('tmp','appdata','localappdata','source')) {
    New-Item -ItemType Directory -Force "$run/$name" | Out-Null
}
$paths=@(Get-Content "$root/rtl/production.f")+@('rtl/production.f','rtl/posit_mac.vh',
    'tb/prepack_nf_ppa_top.sv','tb/week13_fused_ppa_top.sv','syn/run_a35t.tcl',
    'syn/constraints/a35t_clock.xdc','syn/constraints/a35t_io_template.xdc','scripts/run_a35t_sta.ps1')
if($IoXdc) {$paths+=$IoXdc}
$hashes=@{}
foreach($name in ($paths | Sort-Object -Unique)) {
    $dst=Join-Path "$run/source" $name
    New-Item -ItemType Directory -Force (Split-Path $dst -Parent) | Out-Null
    Copy-Item -LiteralPath (Join-Path $root $name) -Destination $dst
    $hashes[$name]=(Get-FileHash -LiteralPath $dst).Hash.ToLowerInvariant()
}
@{contract='A35T-C1';part='xc7a35tcpg236-1';variant=$Variant;profile=$Profile;action=$Action;
  run_root=$RunRoot;io_xdc=$IoXdc;implementation='Default';random_seed_override=$null;
  command="./scripts/run_a35t_sta.ps1 -Variant $Variant -Profile $Profile -Action $Action -RunRoot $RunRoot -IoXdc $IoXdc";
  source_sha256=$hashes} | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 "$run/manifest.json"
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$env:APPDATA="$run/appdata"; $env:LOCALAPPDATA="$run/localappdata"; $env:XILINX_LOCAL_USER_DATA='no'
Push-Location $run
try {
    $argsList=@('-mode','batch','-notrace','-source',"$run/source/syn/run_a35t.tcl",'-log','vivado.log','-journal','vivado.jou','-tclargs',$Variant,$Profile,$Action)
    if($IoXdc) {$argsList+=$IoXdc}
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' @argsList > console.log
    if($LASTEXITCODE) {throw 'A35T flow failed; preserve logs'}
    if((Get-Content vivado.log -Raw) -match '(?m)^(ERROR|CRITICAL WARNING):') {
        'FAILED' | Set-Content status.txt
        throw 'Constraint/tool errors or critical warnings; do not accept completion marker'
    }
    $expected=if($Action -eq 'validate') {'VALIDATED'} else {'COMPLETE'}
    if((Get-Content status.txt -Raw).Trim() -ne $expected) {throw 'Missing completion marker'}
} finally {Pop-Location}
