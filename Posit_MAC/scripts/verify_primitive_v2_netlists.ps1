param([string]$VivadoBin='C:/AMDDesignTools/2026.1/Vivado/bin')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$cases=Get-Content -LiteralPath "$root/results/primitive_v2_20261016/netlist_cases.json" -Raw | ConvertFrom-Json
$glbl=Join-Path (Split-Path $VivadoBin -Parent) 'data/verilog/src/glbl.v'
foreach($relative in $cases) {
    $run=Join-Path $root $relative
    if((Test-Path "$run/simulate.log") -and (Get-Content "$run/simulate.log" -Raw) -match 'NETLIST_PASS checks=10000 mismatch=0') {continue}
    foreach($d in @('tmp','appdata','localappdata')) {New-Item -ItemType Directory -Force "$run/$d" | Out-Null}
    $env:TEMP="$run/tmp";$env:TMP=$env:TEMP
    $env:APPDATA="$run/appdata";$env:LOCALAPPDATA="$run/localappdata";$env:XILINX_LOCAL_USER_DATA='no'
    Push-Location $run
    try {
        & "$VivadoBin/xvlog.bat" --sv ../functional_netlist.v tb_primitive_v2_netlist.sv $glbl -log compile.log > compile_console.log
        if($LASTEXITCODE) {throw 'Netlist compile failed'}
        & "$VivadoBin/xelab.bat" tb_primitive_v2_netlist glbl -L unisims_ver -s checked -log elaborate.log > elaborate_console.log
        if($LASTEXITCODE) {throw 'Netlist elaborate failed'}
        @('-runall','-log','simulate.log') | Set-Content -Encoding ascii xsim.options
        & "$VivadoBin/xsim.bat" checked -f xsim.options > simulate_console.log
        if($LASTEXITCODE -or (Get-Content simulate.log -Raw) -notmatch 'NETLIST_PASS checks=10000 mismatch=0') {throw 'Netlist verification failed'}
        Write-Output "NETLIST_VERIFIED $relative"
    } finally {Pop-Location}
}
