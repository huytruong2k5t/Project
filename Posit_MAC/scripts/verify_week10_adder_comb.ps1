param(
    [string]$ModelSimBin = 'C:\altera\13.0sp1\modelsim_ase\win32aloem',
    [ValidatePattern('^[a-z0-9_-]+$')][string]$FixtureRun = 'pilot',
    [ValidatePattern('^[a-z0-9_-]+$')][string]$RunName = 'modelsim_comb'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'rtl_paths.ps1')
$projectRoot = Split-Path $PSScriptRoot -Parent
$resultRoot = Join-Path $projectRoot "results/week10_adder/$RunName"
$fixtureRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot "results/week10_adder/$FixtureRun"))
if ($FixtureRun -eq $RunName) { throw 'Fixtures and reports must be separate' }
New-Item -ItemType Directory -Path $resultRoot -Force | Out-Null
$sourceNames = @('lod_lzd_core','dyn_left_shifter','dyn_right_shifter','posit_parser_comb',
    'posit_add_align','posit_add_arith','posit_add_normalize','posit_add_comb',
    'posit_pack_prepare','posit_pack_finish','posit_pack_comb')
$sources = @($sourceNames | ForEach-Object { Resolve-RtlPath $_ })
$sources += Join-Path $projectRoot 'tb/tb_week10_adder_comb.sv'
Push-Location $resultRoot
try {
    Set-Content -Encoding ascii run_status.txt RUNNING
    & (Join-Path $ModelSimBin 'vsim.exe') -version | Set-Content version.log
    if ($LASTEXITCODE) { throw 'ModelSim version failed' }
    & (Join-Path $ModelSimBin 'vlib.exe') work | Set-Content library.log
    if ($LASTEXITCODE) { throw 'vlib failed' }
    $sourceHashes = @{}
    foreach ($source in $sources) {
        $key = $source.Substring($projectRoot.Length + 1).Replace('\','/')
        $sourceHashes[$key] = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $sourceHashes['rtl/posit_mac.vh'] = (Get-FileHash -LiteralPath (Join-Path $projectRoot 'rtl/posit_mac.vh') -Algorithm SHA256).Hash.ToLowerInvariant()
    $sourceHashes | ConvertTo-Json | Set-Content -Encoding utf8 source_sha256.json
    & (Join-Path $ModelSimBin 'vlog.exe') -sv -timescale 1ns/1ps "+incdir+$projectRoot/rtl" -work work @sources -l compile.log | Set-Content compile_console.log
    if ($LASTEXITCODE) { throw 'vlog failed' }
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    foreach ($format in @(@(8,0),@(16,1),@(32,2),@(32,3))) {
        $nb = $format[0]; $es = $format[1]
        $log = "simulate_${nb}_${es}.log"
        & (Join-Path $ModelSimBin 'vsim.exe') -c work.tb_week10_adder_comb "-gNB=$nb" "-gES=$es" "+VECTOR_DIR=$fixtureRoot" -l $log -wlf "simulate_${nb}_${es}.wlf" -do run.do | Set-Content "console_${nb}_${es}.log"
        if ($LASTEXITCODE) { throw "Simulation failed $nb/$es" }
        $text = Get-Content -LiteralPath $log -Raw
        if ($text -notmatch 'W10 COMB PASS' -or $text -match '\*\*\s+(Error|Fatal):') { throw "Missing PASS $nb/$es" }
        Write-Output ($text -split "`n" | Where-Object { $_ -match 'W10 COMB PASS' })
    }
    Set-Content -Encoding ascii run_status.txt COMPLETE
} finally {
    Pop-Location
}
