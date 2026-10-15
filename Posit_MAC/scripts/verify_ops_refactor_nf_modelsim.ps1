param([string]$ModelSimBin='C:\altera\13.0sp1\modelsim_ase\win32aloem')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'rtl_paths.ps1')
$projectRoot=Split-Path $PSScriptRoot -Parent
$resultRoot=Join-Path $projectRoot 'results/ops_refactor_20261014/nf/modelsim'
$fixtureRoot=Join-Path $projectRoot 'results/ops_refactor_20261014/nf/fixtures'
New-Item -ItemType Directory -Path $resultRoot -Force | Out-Null
$names=@('lod_lzd_core','dyn_left_shifter','dyn_right_shifter','posit_parser','posit_parser_comb',
    'ops_sel_comb','sac_step_comb','sbm_shift_comb','sbm_accum_comb','iter_ctrl','sbm_accum',
    'mul_iter_core','mul_prepack_norm_comb','posit_pack_prepare','posit_pack_finish',
    'posit_pack_comb','round_unpacked_comb','posit_add_align','posit_add_arith',
    'posit_add_normalize','posit_add','posit_pack','mac_nf_wrapper','posit_mac_nf')
$sources=@($names | ForEach-Object {Resolve-RtlPath $_})
$sources+=Join-Path $projectRoot 'tb/tb_week11_mac.sv'
Push-Location $resultRoot
try {
    Set-Content -Encoding ascii run_status.txt RUNNING
    & (Join-Path $ModelSimBin 'vsim.exe') -version | Set-Content version.log
    & (Join-Path $ModelSimBin 'vlib.exe') work | Set-Content library.log
    if($LASTEXITCODE) {throw 'vlib failed'}
    $hashes=@{}
    foreach($source in $sources) {
        $key=$source.Substring($projectRoot.Length+1).Replace('\','/')
        $hashes[$key]=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $hashes['rtl/posit_mac.vh']=(Get-FileHash -LiteralPath (Join-Path $projectRoot 'rtl/posit_mac.vh') -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashes | ConvertTo-Json | Set-Content -Encoding utf8 source_sha256.json
    & (Join-Path $ModelSimBin 'vlog.exe') -sv -timescale 1ns/1ps "+incdir+$projectRoot/rtl" -work work @sources -l compile.log | Set-Content compile_console.log
    if($LASTEXITCODE) {throw 'vlog failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    foreach($format in @(@(8,0),@(16,1),@(32,2),@(32,3))) {
        $nb=$format[0]; $es=$format[1]
        $log="simulate_${nb}_${es}.log"
        & (Join-Path $ModelSimBin 'vsim.exe') -c work.tb_week11_mac "-gNB=$nb" "-gES=$es" "+VECTOR_DIR=$fixtureRoot" -l $log -wlf "simulate_${nb}_${es}.wlf" -do run.do | Set-Content "console_${nb}_${es}.log"
        if($LASTEXITCODE) {throw "simulation failed $nb/$es"}
        $text=Get-Content -LiteralPath $log -Raw
        if($text -notmatch 'W11 MODELSIM PASS' -or $text -match '\*\*\s+(Error|Fatal):') {throw "missing PASS $nb/$es"}
        Write-Output ($text -split "`n" | Where-Object {$_ -match 'W11 MODELSIM PASS'})
    }
    Set-Content -Encoding ascii run_status.txt COMPLETE
} finally {Pop-Location}
