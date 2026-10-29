param(
    [ValidateSet('opt17_nf','opt17_f')][string]$Top='opt17_nf',
    [ValidatePattern('^_[A-Za-z0-9_]+$')][string]$BuildTag='_r2',
    [ValidatePattern('^[A-Za-z0-9_]+$')][string]$Label='event'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$studyRoot = Join-Path $projectRoot 'results/opt17_20261029'
$runRoot = Join-Path $studyRoot "modelsim_${Top}_$Label"
$vector = Join-Path $studyRoot "build_${Top}${BuildTag}/${Label}_event.txt"
if (Test-Path -LiteralPath $runRoot) { throw 'Preserve previous ModelSim run' }
if (!(Test-Path -LiteralPath $vector)) { throw 'Generate oracle-checked event vectors first' }
$bin = 'C:/altera/13.0sp1/modelsim_ase/win32aloem'
New-Item -ItemType Directory -Force "$runRoot/source","$runRoot/tmp" | Out-Null
$env:TEMP = "$runRoot/tmp"
$env:TMP = $env:TEMP
$sources = @()
$hashes = @{}
$compatibility = @()
foreach ($relative in Get-Content -LiteralPath "$projectRoot/experiments/opt17_20261029/sources.f") {
    $inputPath = Join-Path $projectRoot $relative
    $leaf = Split-Path $relative -Leaf
    $outputPath = Join-Path "$runRoot/source" $leaf
    $body = Get-Content -LiteralPath $inputPath -Raw
    if ($leaf -match '^lod_lzd_core') {
        $body = $body.Replace("POS_W'(group_index)","pos_cast_t'(group_index)")
        $body = $body.Replace("S'(pos_tree[LEVELS][0])","count_cast_t'(pos_tree[LEVELS][0])")
        $body = $body.Replace('            assign match_bits',"            typedef logic [POS_W-1:0] pos_cast_t;`n            typedef logic [S-1:0] count_cast_t;`n            assign match_bits")
        $compatibility += $relative
    }
    if ($leaf -in @('mac_f_wrapper.sv','opt17_f_ref_wrapper.sv')) {
        $body = $body.Replace("I_W'(N_MAX)","iteration_cast_t'(N_MAX)")
        $body = $body.Replace('    localparam int I_W = 4;', '    localparam int I_W = 4; typedef logic [I_W-1:0] iteration_cast_t;')
        $compatibility += $relative
    }
    [IO.File]::WriteAllText($outputPath,$body)
    $sources += $outputPath
    $hashes[$relative] = (Get-FileHash -LiteralPath $inputPath).Hash.ToLowerInvariant()
}
Copy-Item -LiteralPath "$projectRoot/rtl/posit_mac.vh" -Destination "$runRoot/source"
$testbench = "$projectRoot/tb/opt17/tb_${Top}_event.sv"
Copy-Item -LiteralPath $testbench -Destination "$runRoot/source"
$sources += "$runRoot/source/tb_${Top}_event.sv"
@{
    top=$Top
    source_sha256=$hashes
    testbench_sha256=(Get-FileHash -LiteralPath $testbench).Hash.ToLowerInvariant()
    vector_sha256=(Get-FileHash -LiteralPath $vector).Hash.ToLowerInvariant()
    compatibility_typed_cast_only=$compatibility
    vector_scope='Public cycle trace generated only after independent integer/full-grid d/flags and per-round checks'
} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$runRoot/manifest.json"
Push-Location $runRoot
try {
    & "$bin/vsim.exe" -version > version.log
    & "$bin/vlib.exe" work > library.log
    if ($LASTEXITCODE) { throw 'vlib failed' }
    & "$bin/vlog.exe" -sv -timescale 1ns/1ps "+incdir+$runRoot/source" -work work @sources -l compile.log > compile_console.log
    if ($LASTEXITCODE) { throw 'ModelSim compile failed' }
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') |
        Set-Content -Encoding ascii run.do
    & "$bin/vsim.exe" -c "work.tb_${Top}_event" "+STIMULUS=$vector" -do run.do -l simulation.log -wlf events.wlf > console.log
    if ($LASTEXITCODE) { throw 'ModelSim simulation failed' }
    $body = Get-Content -LiteralPath simulation.log -Raw
    if ($body -notmatch 'OPT17_EVENT_PASS' -or $body -match '\*\*\s+(Error|Fatal):') {
        throw 'Event PASS missing or simulation error'
    }
    $body -split "`n" | Where-Object { $_ -match 'OPT17_EVENT_PASS' }
    'PASS' | Set-Content status.txt
} finally { Pop-Location }
