param(
    [string]$QuartusTool = 'C:/altera/13.0sp1/quartus/bin64/quartus_sh.exe',
    [switch]$CollectExisting
)
$ErrorActionPreference = 'Stop'
$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$resultPath = Join-Path $projectPath 'results/packer_ppa'
$rtlNames = @(
    'rtl/posit_mac.vh', 'rtl/dyn_right_shifter.sv',
    'rtl/posit_pack_prepare.sv', 'rtl/posit_pack_finish.sv',
    'rtl/posit_pack.sv', 'rtl/packer_ppa_boundary.sv', 'rtl/packer_ppa_top.sv'
)
New-Item -ItemType Directory -Force $resultPath | Out-Null
# Quartus13 requires an explicit generate around this module-level branch.
# The export only adds generate/endgenerate, preserving the shifter equations.
$compatPath = Join-Path $resultPath 'compat'
New-Item -ItemType Directory -Force $compatPath | Out-Null
$compatShifter = Join-Path $compatPath 'dyn_right_shifter.sv'
if (!$CollectExisting) {
    $raw = Get-Content -Raw (Join-Path $projectPath 'rtl/dyn_right_shifter.sv')
    $export = $raw.Replace('    if (N == 1) begin : g_single_bit',
        "    generate`n    if (N == 1) begin : g_single_bit")
    $export = $export.Replace('endmodule', "    endgenerate`nendmodule")
    Set-Content -NoNewline -Encoding utf8 $compatShifter $export
}
$currentHashes = @($rtlNames | ForEach-Object {
    (Get-FileHash -LiteralPath (Join-Path $projectPath $_) -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + $_
})
$currentHashes += (Get-FileHash -LiteralPath $compatShifter -Algorithm SHA256).Hash.ToLowerInvariant() +
    '  results/packer_ppa/compat/dyn_right_shifter.sv'
if ($CollectExisting) {
    if (@(Compare-Object (Get-Content (Join-Path $resultPath 'sources.sha256')) $currentHashes).Count) {
        throw 'PPA results do not match current sources.'
    }
} else {
    $currentHashes | Set-Content (Join-Path $resultPath 'sources.sha256')
    & $QuartusTool --version | Set-Content (Join-Path $resultPath 'version.log')
}
$rows = @()
foreach ($mode in @('RNE', 'TRUNC')) {
    foreach ($seed in @(1, 2, 3)) {
        $folder = Join-Path $resultPath "${mode}_seed${seed}"
        if (!$CollectExisting) {
            New-Item -ItemType Directory -Force $folder | Out-Null
            'QUARTUS_VERSION = "13.0"', 'PROJECT_REVISION = "packer"' |
                Set-Content (Join-Path $folder 'packer.qpf') -Encoding ascii
            $qsf = @(
                'set_global_assignment -name FAMILY "Cyclone IV E"',
                'set_global_assignment -name DEVICE EP4CE22F17C6',
                'set_global_assignment -name TOP_LEVEL_ENTITY packer_ppa_top',
                'set_global_assignment -name SDC_FILE packer.sdc',
                'set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files',
                "set_global_assignment -name SEED $seed",
                'set_global_assignment -name NUM_PARALLEL_PROCESSORS 2',
                ('set_parameter -name ROUND_MODE "\"' + $mode + '\""'),
                ('set_global_assignment -name SEARCH_PATH "' + (Join-Path $projectPath 'rtl').Replace('\', '/') + '"')
            )
            $qsf += $rtlNames | Where-Object { $_ -like '*.sv' } | ForEach-Object {
                $source = if ($_ -eq 'rtl/dyn_right_shifter.sv') { $compatShifter } else {
                    Join-Path $projectPath $_
                }
                'set_global_assignment -name SYSTEMVERILOG_FILE "' +
                $source.Replace('\', '/') + '"'
            }
            $qsf | Set-Content (Join-Path $folder 'packer.qsf') -Encoding ascii
            @('create_clock -name clk -period 10.000 [get_ports clk]',
              'derive_clock_uncertainty') |
                Set-Content (Join-Path $folder 'packer.sdc') -Encoding ascii
            Push-Location $folder
            try {
                & $QuartusTool --flow compile packer *> compile.log
                if ($LASTEXITCODE -ne 0) { throw "Quartus failed: $mode seed$seed" }
            } finally { Pop-Location }
        }
        $fit = Get-Content -Raw (Join-Path $folder 'output_files/packer.fit.summary')
        $sta = Get-Content -Raw (Join-Path $folder 'output_files/packer.sta.rpt')
        $lut = [regex]::Match($fit, 'Total combinational functions\s*:\s*([\d,]+)')
        $ff = [regex]::Match($fit, 'Total registers\s*:\s*([\d,]+)')
        $fmax = [regex]::Match($sta, '(?s)Slow 1200mV 85C Model Fmax Summary\s*;.*?;\s*([0-9.]+) MHz')
        $setup = [regex]::Match($sta, '(?s)Slow 1200mV 85C Model Setup Summary\s*;.*?;\s*clk\s*;\s*(-?[0-9.]+)\s*;')
        if (!$lut.Success -or !$ff.Success -or !$fmax.Success -or !$setup.Success) { throw 'Incomplete PPA reports.' }
        $rows += [pscustomobject]@{
            mode=$mode; seed=$seed; device='EP4CE22F17C6'; NB=32; ES=2; F_IN=55
            combinational_functions_LUT4=[int]$lut.Groups[1].Value.Replace(',', '')
            registers=[int]$ff.Groups[1].Value.Replace(',', '')
            fmax_slow85C_MHz=[double]::Parse($fmax.Groups[1].Value, [cultureinfo]::InvariantCulture)
            setup_wns_ns=[double]::Parse($setup.Groups[1].Value, [cultureinfo]::InvariantCulture)
            clock_ns=10; boundary='same registered input/output, continuous stream'
        }
        Write-Output "PPA $mode seed$seed collected"
    }
}
$rows | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $resultPath 'summary.csv')
[pscustomobject]@{
    status='COMPLETED'; date=(Get-Date -Format o); scope='standalone packer benchmark, not full MAC'
    all_seeds_meet_10ns=(@($rows | Where-Object { $_.setup_wns_ns -lt 0 }).Count -eq 0)
    device='EP4CE22F17C6'; tool=(Get-Content -Raw (Join-Path $resultPath 'version.log')).Trim()
    limits='LUT4; auto-assigned IO without board/input/output timing; fmax is register-register STA; no power measurement'
    variants=$rows
} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $resultPath 'summary.json')
$rows | Format-Table -AutoSize
