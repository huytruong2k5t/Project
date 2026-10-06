param(
    [string]$QuartusTool = 'C:/altera/13.0sp1/quartus/bin64/quartus_sh.exe',
    [string]$ModelSimDir = 'C:/altera/13.0sp1/modelsim_ase/win32aloem',
    [switch]$SkipSimulation,
    [switch]$SkipSynthesis
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputRoot = Join-Path $projectRoot 'results/ops_ppa'
$source = (Join-Path $projectRoot 'rtl/ops_compare_top.sv').Replace('\','/')
$tb = (Join-Path $projectRoot 'tb/tb_ops_compare.sv').Replace('\','/')
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
if (-not $SkipSimulation) {
    $simDir = Join-Path $outputRoot 'sim'
    New-Item -ItemType Directory -Force -Path $simDir | Out-Null
    Push-Location -LiteralPath $simDir
    try {
        if (-not (Test-Path -LiteralPath 'work')) {
            & (Join-Path $ModelSimDir 'vlib.exe') work
            if ($LASTEXITCODE -ne 0) { throw 'vlib failed' }
        }
        & (Join-Path $ModelSimDir 'vlog.exe') -sv -work work $source $tb *> build.log
        if ($LASTEXITCODE -ne 0) { throw 'OPS RTL compilation failed' }
        & (Join-Path $ModelSimDir 'vsim.exe') -c -onfinish exit work.tb_ops_compare -do 'run -all; quit -code 0' *> verified.log
        if ($LASTEXITCODE -ne 0 -or -not (Select-String -LiteralPath verified.log -Pattern 'OPS_COMPARE PASS' -Quiet)) {
            throw 'OPS simulation failed or missing PASS marker'
        }
    } finally { Pop-Location }
}
$rows = @()
for ($policy = 0; $policy -lt 2; $policy++) {
    $policyName = if ($policy -eq 0) { 'predict' } else { 'minpop' }
    foreach ($seed in @(1,2,3)) {
        $folder = Join-Path $outputRoot "${policyName}_seed${seed}"
        if (-not $SkipSynthesis) {
            New-Item -ItemType Directory -Force -Path $folder | Out-Null
            'QUARTUS_VERSION = "13.0"', 'PROJECT_REVISION = "ops_compare"' |
                Set-Content -LiteralPath (Join-Path $folder 'ops_compare.qpf') -Encoding ASCII
            @"
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE22F17C6
set_global_assignment -name TOP_LEVEL_ENTITY ops_compare_top
set_global_assignment -name SYSTEMVERILOG_FILE "$source"
set_global_assignment -name SDC_FILE ops_compare.sdc
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name SEED $seed
set_global_assignment -name NUM_PARALLEL_PROCESSORS 2
set_parameter -name POLICY $policy
"@ | Set-Content -LiteralPath (Join-Path $folder 'ops_compare.qsf') -Encoding ASCII
            'create_clock -name clk -period 10.000 [get_ports clk]', 'derive_clock_uncertainty' |
                Set-Content -LiteralPath (Join-Path $folder 'ops_compare.sdc') -Encoding ASCII
            Push-Location -LiteralPath $folder
            try {
                & $QuartusTool --flow compile ops_compare *> compile.log
                if ($LASTEXITCODE -ne 0) { throw "Quartus failed: $policyName seed $seed" }
            } finally { Pop-Location }
        }
        $summary = Get-Content -Raw -LiteralPath (Join-Path $folder 'output_files/ops_compare.fit.summary')
        $sta = Get-Content -Raw -LiteralPath (Join-Path $folder 'output_files/ops_compare.sta.rpt')
        $logic = [regex]::Match($summary,'Total combinational functions\s*:\s*(\d+)')
        $registers = [regex]::Match($summary,'Total registers\s*:\s*(\d+)')
        $fmax = [regex]::Match($sta,'(?s)Slow 1200mV 85C Model Fmax Summary\s*;.*?;\s*([0-9.]+) MHz')
        if (-not $logic.Success -or -not $registers.Success -or -not $fmax.Success) { throw 'Incomplete PPA report' }
        $rows += [pscustomobject]@{
            policy=$policyName; seed=$seed; combinational_functions_LUT4=[int]$logic.Groups[1].Value
            registers=[int]$registers.Groups[1].Value
            fmax_slow85C_MHz=[double]::Parse($fmax.Groups[1].Value,[cultureinfo]::InvariantCulture)
        }
    }
}
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'results/ops_ppa_summary.csv')
$rows | Format-Table -AutoSize
