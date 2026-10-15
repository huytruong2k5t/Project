param(
    [string]$VivadoBin = 'C:\AMDDesignTools\2026.1\Vivado\bin',
    [string]$Python = 'C:\Users\This PC\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root 'results/primitive_xilinx_20261015'
& $Python (Join-Path $PSScriptRoot 'prepare_primitive_xilinx.py')
if ($LASTEXITCODE) { throw 'prepare failed' }
$run = Join-Path $output 'simulation'
New-Item -ItemType Directory -Force -Path $run | Out-Null
# Process-local runtime paths; no installation, home or license changes.
foreach ($dir in @('tmp','appdata','localappdata')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $run $dir) | Out-Null
}
$env:TEMP = Join-Path $run 'tmp'
$env:TMP = $env:TEMP
$env:APPDATA = Join-Path $run 'appdata'
$env:LOCALAPPDATA = Join-Path $run 'localappdata'
$env:XILINX_LOCAL_USER_DATA = 'no'
Push-Location $run
try {
    $files = @(
        '../reference/dyn_left_shifter_reference.sv',
        '../reference/dyn_right_shifter_reference.sv',
        '../reference/lod_lzd_core_reference.sv',
        '../../../rtl/candidates/primitives/dyn_left_shifter.sv',
        '../../../rtl/candidates/primitives/dyn_right_shifter.sv',
        '../../../rtl/candidates/primitives/lod_lzd_core.sv',
        '../../../tb/primitive_shift_check.sv',
        '../../../tb/primitive_lod_check.sv',
        '../tb_primitive_xilinx.sv'
    )
    & (Join-Path $VivadoBin 'xvlog.bat') --sv @files -log compile.log
    if ($LASTEXITCODE) { throw 'xvlog failed' }
    & (Join-Path $VivadoBin 'xelab.bat') tb_primitive_xilinx -s primitive_snapshot -log elaborate.log
    if ($LASTEXITCODE) { throw 'xelab failed' }
    @('-runall','-log','simulate.log') | Set-Content -Encoding ascii xsim.options
    & (Join-Path $VivadoBin 'xsim.bat') primitive_snapshot -f xsim.options
    if ($LASTEXITCODE) { throw 'xsim failed' }
    $log = Get-Content -LiteralPath simulate.log -Raw
    if ($log -notmatch 'PRIMITIVE_ALL_PASS' -or $log -match 'Fatal:|SHIFT_FAIL|LOD_FAIL|Could not obtain') {
        throw 'simulation pass marker missing or failure reported'
    }
    $checks = [long]0
    $pass = [regex]::Matches($log,'(?:SHIFT|LOD)_PASS[^\r\n]*checks=(\d+)')
    foreach ($match in $pass) { $checks += [long]$match.Groups[1].Value }
    if ($pass.Count -ne 117) { throw "expected 117 configurations, got $($pass.Count)" }
    @{
        status='PASS'; simulator='Vivado XSim 2026.1'; seed=20261015;
        configurations=$pass.Count; checks=$checks; mismatch=0;
        oracle='linear scan / per-output-bit indexing, baseline and candidate';
        scope='known binary inputs; exhaustive small widths, all encoded shifts, directed/random larger widths';
        four_state_equivalence='not claimed; invalid/unknown controls are outside this binary contract'
    } | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $output 'verification.json')
} finally { Pop-Location }
