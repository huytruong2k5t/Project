param([string]$ModelSimBin='C:/altera/13.0sp1/modelsim_ase/win32aloem',
      [ValidatePattern('^results/[a-zA-Z0-9_/-]+$')][string]$RunRoot='results/prepack_refactor_20261016')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root $RunRoot
if($RunRoot.Contains('..')) {throw 'Invalid RunRoot'}
$run=Join-Path $out 'modelsim'
if(Test-Path "$run/status.txt") {throw 'Preserve existing evidence; choose fresh RunRoot and prepare frozen sources first'}
New-Item -ItemType Directory -Force "$run/tmp" | Out-Null
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$nfNames=@('lod_lzd_core','dyn_left_shifter','dyn_right_shifter','posit_parser','posit_parser_comb',
    'ops_sel_comb','sac_step_comb','sbm_shift_comb','sbm_accum_comb','iter_ctrl','sbm_accum',
    'mul_iter_core','posit_pack_prepare','posit_pack_finish','posit_pack_comb','round_unpacked_comb',
    'posit_add_align','posit_add_arith','posit_add_normalize','posit_add','posit_pack','mac_nf_wrapper','posit_mac_nf')
# ModelSim10.1d predates parameter-sized casts. Only the private LOD copy uses
# equivalent unsigned typedef casts; production common RTL remains byte-identical.
New-Item -ItemType Directory -Force "$run/compat" | Out-Null
$core=Get-Content "$out/source/baseline/lod_lzd_core.sv" -Raw
$core=$core.Replace("POS_W'(group_index)","pos_cast_t'(group_index)").Replace("S'(pos_tree[LEVELS][0])","count_cast_t'(pos_tree[LEVELS][0])")
$core=$core.Replace('            assign match_bits',"            typedef logic [POS_W-1:0] pos_cast_t;`n            typedef logic [S-1:0] count_cast_t;`n            assign match_bits")
[IO.File]::WriteAllText("$run/compat/lod_lzd_core.sv",$core)
$sources=@($nfNames | ForEach-Object {if($_ -eq 'lod_lzd_core') {"$run/compat/lod_lzd_core.sv"} else {"$out/source/baseline/$_.sv"}})
$sources+=Join-Path $out 'source/candidate/mul_prepack_norm_comb.sv'
$sources+=Join-Path $root 'tb/tb_week11_mac.sv'
$fixtures=Join-Path $out 'fixtures'
if(!(Test-Path $fixtures)) {
    New-Item -ItemType Directory -Force $fixtures | Out-Null
    Copy-Item "$root/results/prepack_refactor_20261016/fixtures/mac_*.txt" $fixtures
}
$fixtureHashes=@{}
Get-ChildItem -LiteralPath $fixtures -Filter 'mac_*.txt' -File | ForEach-Object {
    $fixtureHashes[$_.Name]=(Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant()
}
$fixtureHashes | ConvertTo-Json | Set-Content -Encoding utf8 "$run/fixture_sha256.json"
Push-Location $run
try {
    & "$ModelSimBin/vsim.exe" -version > version.log
    & "$ModelSimBin/vlib.exe" work > library.log
    if($LASTEXITCODE) {throw 'vlib failed'}
    & "$ModelSimBin/vlog.exe" -sv -timescale 1ns/1ps "+incdir+$out/source/baseline" -work work @sources -l compile.log > compile_console.log
    if($LASTEXITCODE) {throw 'vlog failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    & "$ModelSimBin/vlog.exe" -sv -timescale 1ns/1ps -work work "$root/tb/tb_lod_lzd_core.sv" -l lod_compile.log > lod_compile_console.log
    if($LASTEXITCODE) {throw 'LOD compat test compile failed'}
    & "$ModelSimBin/vsim.exe" -c work.tb_lod_lzd_core -l lod_simulate.log -do run.do > lod_console.log
    if($LASTEXITCODE) {throw 'LOD compat test failed'}
    foreach($profile in @(@(8,0),@(16,1),@(32,2),@(32,3))) {
        $nb=$profile[0]; $es=$profile[1]
        & "$ModelSimBin/vsim.exe" -c work.tb_week11_mac "-gNB=$nb" "-gES=$es" "+VECTOR_DIR=$fixtures" -l "simulate_${nb}_${es}.log" -wlf "simulate_${nb}_${es}.wlf" -do run.do > "console_${nb}_${es}.log"
        if($LASTEXITCODE) {throw "ModelSim failed $nb/$es"}
        $log=Get-Content "simulate_${nb}_${es}.log" -Raw
        if($log -notmatch 'W11 MODELSIM PASS' -or $log -match '\*\*\s+(Fatal|Error):') {throw 'Missing acceptance'}
        Write-Output ($log -split "`n" | Where-Object {$_ -match 'W11 MODELSIM PASS'})
    }
    'COMPLETE' | Set-Content status.txt
} finally {Pop-Location}
