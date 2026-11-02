param([Parameter(Mandatory=$true)][string]$RunRoot,
      [string]$Baseline='results/readme_refactor_recheck_20261101')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$run=Join-Path $root $RunRoot
$output=Join-Path $run 'verify_parser_f'
if(Test-Path -LiteralPath $output){throw 'Preserve previous parser verification'}
New-Item -ItemType Directory -Force "$output/source","$output/tmp"|Out-Null
$baselineRoot=Join-Path $root $Baseline
foreach($item in @('parser/posit_parser.sv','common/lod_lzd_core_fixed2.sv')) {
    $body=Get-Content -LiteralPath "$baselineRoot/source/rtl/$item" -Raw
    $body=$body.Replace('lod_lzd_core_fixed2','lod_lzd_core_previous')
    if($item -like 'parser/*'){$body=$body.Replace('module posit_parser (','module posit_parser_previous (')}
    Set-Content -LiteralPath "$output/source/$(Split-Path $item -Leaf)" -Value $body -Encoding ascii
}
Copy-Item $PSCommandPath "$output/source/run_f_parser_equiv.ps1"
$sources=@("$run/source/rtl/parser/posit_parser_f.sv","$run/source/rtl/parser/posit_parser_f_regime_lod.sv",
    "$run/source/rtl/common/dyn_left_shifter.sv","$output/source/posit_parser.sv",
    "$output/source/lod_lzd_core_fixed2.sv","$run/source/tb/tb_parser_f_timing_equiv.sv")
@{baseline=$baselineRoot;files=@($sources|ForEach-Object{@{path=$_;sha256=(Get-FileHash -LiteralPath $_).Hash}})}|
    ConvertTo-Json -Depth 5|Set-Content "$output/manifest.json"
$env:TEMP="$output/tmp";$env:TMP=$env:TEMP
$bin='C:/altera/13.0sp1/modelsim_ase/win32aloem'
Push-Location $output
try {
    & "$bin/vlib.exe" work > library.log
    if($LASTEXITCODE){throw 'vlib failed'}
    & "$bin/vlog.exe" -sv -timescale 1ns/1ps "+incdir+$run/source/rtl" @sources -l compile.log > compile_console.log
    if($LASTEXITCODE){throw 'Parser compile failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0')|Set-Content -Encoding ascii run.do
    & "$bin/vsim.exe" -c work.tb_parser_f_timing_equiv -do run.do -l parser.log -wlf parser.wlf > console.log
    if($LASTEXITCODE){throw 'Parser simulation failed'}
    $body=Get-Content parser.log -Raw
    foreach($marker in @('PARSER_MAG_DUT_PASS','LOD_SERIAL_PASS','PARSER_PREVIOUS_EQUIV_PASS')) {
        if($body -notmatch $marker){throw "Missing $marker"}
    }
    if($body -match '\*\*\s+(Error|Fatal):'){throw 'Parser simulation reported errors'}
    'PASS'|Set-Content status.txt
    $body -split "`n"|Where-Object{$_ -match '_PASS'}
} finally {Pop-Location}
