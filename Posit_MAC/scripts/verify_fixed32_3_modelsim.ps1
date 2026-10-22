param(
    [ValidatePattern('^[A-Za-z0-9_]+$')][string]$RunLabel = 'event_replay',
    [ValidatePattern('^_[A-Za-z0-9_]+$')][string]$BuildTag = '_literal_ports',
    [ValidatePattern('^[A-Za-z0-9_]+$')][string]$VectorLabel = 'pilot'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$studyRoot = Join-Path $projectRoot 'results/fixed32_3_20261022'
$eventRoot = Join-Path $studyRoot $RunLabel
if (Test-Path -LiteralPath $eventRoot) { throw 'Preserve existing event evidence' }
$modelSimBin = 'C:/altera/13.0sp1/modelsim_ase/win32aloem'
New-Item -ItemType Directory -Force "$eventRoot/source/rtl","$eventRoot/source/tb","$eventRoot/tmp" | Out-Null
$env:TEMP = "$eventRoot/tmp"
$env:TMP = $env:TEMP
$sources = @()
$compatibility = @()
foreach ($relative in Get-Content -LiteralPath "$projectRoot/rtl/production.f") {
    $inputPath = Join-Path $projectRoot $relative
    $leaf = Split-Path $relative -Leaf
    $outputPath = Join-Path "$eventRoot/source/rtl" $leaf
    $body = Get-Content -LiteralPath $inputPath -Raw
    if ($leaf -match '^lod_lzd_core') {
        $body = $body.Replace("POS_W'(group_index)","pos_cast_t'(group_index)")
        $body = $body.Replace("S'(pos_tree[LEVELS][0])","count_cast_t'(pos_tree[LEVELS][0])")
        $body = $body.Replace('            assign match_bits', "            typedef logic [POS_W-1:0] pos_cast_t;`n            typedef logic [S-1:0] count_cast_t;`n            assign match_bits")
        $compatibility += $relative
    }
    if ($leaf -eq 'mac_f_wrapper.sv') {
        $body = $body.Replace("I_W'(N_MAX)","iteration_cast_t'(N_MAX)")
        $body = $body.Replace('    localparam int I_W = 4;', '    localparam int I_W = 4; typedef logic [I_W-1:0] iteration_cast_t;')
        $compatibility += $relative
    }
    [IO.File]::WriteAllText($outputPath,$body)
    $sources += $outputPath
}
Copy-Item -LiteralPath "$projectRoot/rtl/posit_mac.vh" -Destination "$eventRoot/source/rtl"
Copy-Item -LiteralPath "$projectRoot/tb/tb_fixed32_3_nf.sv" -Destination "$eventRoot/source/tb"
Copy-Item -LiteralPath "$projectRoot/tb/tb_week13_fused_event.sv" -Destination "$eventRoot/source/tb"
$sources += "$eventRoot/source/tb/tb_fixed32_3_nf.sv"
$sources += "$eventRoot/source/tb/tb_week13_fused_event.sv"
@{scope='Fixed32/3, no format overrides'; compatibility_typed_cast_only=$compatibility} |
    ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 "$eventRoot/compatibility.json"
Push-Location $eventRoot
try {
    & "$modelSimBin/vsim.exe" -version > version.log
    & "$modelSimBin/vlib.exe" work > library.log
    if ($LASTEXITCODE) { throw 'vlib failed' }
    & "$modelSimBin/vlog.exe" -sv -timescale 1ns/1ps "+incdir+$eventRoot/source/rtl" -work work @sources -l compile.log > compile_console.log
    if ($LASTEXITCODE) { throw 'vlog failed' }
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') |
        Set-Content -Encoding ascii run.do
    foreach ($kind in @('corner','protocol')) {
        $fixtures = if ($kind -eq 'corner') { 'fixtures' } else { 'protocol_fixtures' }
        $fixturePath = "$projectRoot/results/opt02b_20261017/$fixtures"
        & "$modelSimBin/vsim.exe" -c work.tb_fixed32_3_nf "+VECTOR_DIR=$fixturePath" -do run.do -l "$kind.log" -wlf "$kind.wlf" > "${kind}_console.log"
        if ($LASTEXITCODE) { throw "NF $kind failed" }
        $logBody = Get-Content -LiteralPath "$kind.log" -Raw
        if ($logBody -notmatch 'W11 MODELSIM PASS' -or $logBody -match '\*\*\s+(Error|Fatal):') { throw "NF $kind missing PASS" }
        $logBody -split "`n" | Where-Object { $_ -match 'W11 MODELSIM PASS' }
    }
    $vectorPath = "$studyRoot/build_f$BuildTag/$VectorLabel.vectors"
    & "$modelSimBin/vsim.exe" -c work.tb_week13_fused_event "+VECTORS=$vectorPath" -do run.do -l fused.log -wlf fused.wlf > fused_console.log
    if ($LASTEXITCODE) { throw 'F event failed' }
    $logBody = Get-Content -LiteralPath fused.log -Raw
    if ($logBody -notmatch 'W13_EVENT_PASS' -or $logBody -match '\*\*\s+(Error|Fatal):') { throw 'F missing PASS' }
    $logBody -split "`n" | Where-Object { $_ -match 'W13_EVENT_PASS' }
    'PASS' | Set-Content status.txt
} finally { Pop-Location }
