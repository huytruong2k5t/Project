param([string]$RunRoot='results/parser_lod_refactor_recheck_20261101',
      [string]$Baseline='results/readme_refactor_recheck_20261101')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$run=Join-Path $root $RunRoot
$baselineRoot=Join-Path $root $Baseline
$output=Join-Path $run 'verify_parser_lod'
if(Test-Path -LiteralPath $output){throw 'Preserve previous supplemental verification'}
New-Item -ItemType Directory -Force "$output/source","$output/tmp"|Out-Null
foreach($item in @('parser/posit_parser.sv','common/lod_lzd_core_fixed2.sv')) {
    $body=Get-Content -LiteralPath "$baselineRoot/source/rtl/$item" -Raw
    $body=$body.Replace('lod_lzd_core_fixed2','lod_lzd_core_previous')
    if($item -like 'parser/*'){$body=$body.Replace('module posit_parser (','module posit_parser_previous (')}
    Set-Content -LiteralPath "$output/source/$(Split-Path $item -Leaf)" -Value $body -Encoding ascii
}
Copy-Item "$root/tb/tb_parser_lod_refactor_recheck.sv" "$output/source/"
Copy-Item $PSCommandPath "$output/source/run_parser_lod_recheck.ps1"
Copy-Item "$root/README.md" "$output/source/README.md"
$files=@("$run/source/rtl/parser/posit_parser.sv","$run/source/rtl/common/lod_lzd_core_fixed2.sv",
    "$run/source/rtl/common/dyn_left_shifter.sv","$run/source/rtl/posit_mac.vh")+@(Get-ChildItem "$output/source" -File|ForEach-Object{$_.FullName})
@{baseline=$baselineRoot;files=@($files|ForEach-Object{@{path=$_;sha256=(Get-FileHash -LiteralPath $_).Hash}})}|
    ConvertTo-Json -Depth 5|Set-Content "$output/manifest.json"
$env:TEMP="$output/tmp"; $env:TMP=$env:TEMP
$bin='C:/altera/13.0sp1/modelsim_ase/win32aloem'
Push-Location $output
try {
    & "$bin/vlib.exe" work > library.log
    if($LASTEXITCODE){throw 'vlib failed'}
    $sources=@("$run/source/rtl/parser/posit_parser.sv","$run/source/rtl/common/lod_lzd_core_fixed2.sv",
        "$run/source/rtl/common/dyn_left_shifter.sv","$output/source/posit_parser.sv",
        "$output/source/lod_lzd_core_fixed2.sv","$output/source/tb_parser_lod_refactor_recheck.sv")
    & "$bin/vlog.exe" -sv -timescale 1ns/1ps "+incdir+$run/source/rtl" @sources -l compile.log > compile_console.log
    if($LASTEXITCODE){throw 'Supplement compile failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0')|Set-Content -Encoding ascii run.do
    & "$bin/vsim.exe" -c work.tb_parser_lod_refactor_recheck -do run.do -l parser_lod.log -wlf parser_lod.wlf > console.log
    if($LASTEXITCODE){throw 'Supplement simulation failed'}
    $body=Get-Content parser_lod.log -Raw
    foreach($marker in @('PARSER_MAG_DUT_PASS','LOD_SERIAL_PASS','PARSER_PREVIOUS_EQUIV_PASS')) {
        if($body -notmatch $marker){throw "Missing $marker"}
    }
    if($body -match '\*\*\s+(Error|Fatal):'){throw 'Simulation reported errors'}
    'PASS'|Set-Content status.txt
    $body -split "`n"|Where-Object{$_ -match '_PASS'}
} finally {Pop-Location}
