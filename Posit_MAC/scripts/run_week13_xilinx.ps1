param([ValidateSet('simulate','ppa')][string]$Mode='simulate')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$bin='C:/AMDDesignTools/2026.1/Vivado/bin'
$run=Join-Path $root "results/week13/$Mode"
New-Item -ItemType Directory -Force $run | Out-Null
foreach($name in @('tmp','appdata','localappdata')) {New-Item -ItemType Directory -Force (Join-Path $run $name) | Out-Null}
$env:TEMP=Join-Path $run 'tmp'
$env:TMP=$env:TEMP
$env:APPDATA=Join-Path $run 'appdata'
$env:LOCALAPPDATA=Join-Path $run 'localappdata'
$env:XILINX_LOCAL_USER_DATA='no'
$hashes=@{}
foreach($relative in @(Get-Content "$root/scripts/week13_sources.txt")+@('rtl/posit_mac.vh','tb/week13_fused_ppa_top.sv','tb/tb_week13_fused_event.sv','scripts/week13_fused_ppa.tcl')) {
 $hashes[$relative]=(Get-FileHash -LiteralPath (Join-Path $root $relative) -Algorithm SHA256).Hash.ToLowerInvariant()
}
$hashes | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $run 'source_sha256.json')
Push-Location $run
try {
 if($Mode -eq 'ppa') {
  & "$bin/vivado.bat" -mode batch -source "$root/scripts/week13_fused_ppa.tcl" -log vivado.log -journal vivado.jou
  if($LASTEXITCODE) {throw 'PPA failed'}
 } else {
  $files=@(Get-Content "$root/scripts/week13_sources.txt" | ForEach-Object {Join-Path $root $_})
  $files+=Join-Path $root 'tb/tb_week13_fused_event.sv'
  & "$bin/xvlog.bat" --sv --include "$root/rtl" @files -log compile.log
  if($LASTEXITCODE) {throw 'xvlog failed'}
  & "$bin/xelab.bat" tb_week13_fused_event -s fused_snapshot -timescale 1ns/1ps -log elaborate.log
  if($LASTEXITCODE) {throw 'xelab failed'}
  @('-runall','-testplusarg','VECTORS=../verilator/pilot.vectors','-log','simulate.log') | Set-Content -Encoding ascii xsim.options
  & "$bin/xsim.bat" fused_snapshot -f xsim.options
  if($LASTEXITCODE) {throw 'xsim failed'}
  $log=Get-Content simulate.log -Raw
  if($log -notmatch 'W13_EVENT_PASS' -or $log -match 'Fatal:|ERROR:|Error:|Could not obtain') {throw 'event simulation failed'}
 }
} finally {Pop-Location}
