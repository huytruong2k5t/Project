param([string]$ModelSimBin = 'C:\altera\13.0sp1\modelsim_ase\win32aloem')
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$resultPath = Join-Path $projectPath 'results/paper_contract_audit/windows'
New-Item -ItemType Directory -Force $resultPath | Out-Null
function Run-Tool([string]$Path, [string[]]$ToolArguments, [string]$Log) {
    & $Path @ToolArguments 2>&1 | Tee-Object -FilePath $Log
    if ($LASTEXITCODE -ne 0) { throw "$Path failed: $LASTEXITCODE" }
}
Push-Location $resultPath
$oldTemp = $env:TEMP
$oldTmp = $env:TMP
try {
    $env:TEMP = Join-Path $projectPath 'results/paper_contract_audit/tmp'
    $env:TMP = $env:TEMP
    Run-Tool (Join-Path $projectPath 'l1/test_paper_contract_audit.exe') @('.') 'generator.log'
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-version') 'version.log'
    if (!(Test-Path work)) { Run-Tool (Join-Path $ModelSimBin 'vlib.exe') @('work') 'library.log' }
    $sources = @('rtl/dyn_right_shifter.sv', 'rtl/posit_pack_prepare.sv',
        'rtl/posit_pack_finish.sv', 'rtl/posit_pack_comb.sv', 'tb/tb_paper_fig5_pack.sv')
    $hashes = @{}
    foreach ($source in $sources) {
        $hashes[$source] = (Get-FileHash (Join-Path $projectPath $source) -Algorithm SHA256).Hash
    }
    $paths = $sources | ForEach-Object { Join-Path $projectPath $_ }
    Run-Tool (Join-Path $ModelSimBin 'vlog.exe') (@('-sv', '-work', 'work') + $paths + @('-l', 'compile.log')) 'compile_console.log'
    @('onerror {quit -code 1}', 'onbreak {quit -code 1}', 'run -all', 'quit -code 0') | Set-Content -Encoding ascii run.do
    $process = Start-Process -FilePath (Join-Path $ModelSimBin 'vsim.exe') -ArgumentList @('-c', 'work.tb_paper_fig5_pack', '-l', 'simulate.log', '-do', 'run.do') -WorkingDirectory $resultPath -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput 'simulate_console.log' -RedirectStandardError 'simulate_stderr.log'
    if ($process.ExitCode -ne 0) { throw 'ModelSim failed' }
    $log = Get-Content -Raw simulate.log
    $actual = [regex]::Match($log, 'PAPER FIG5 PACK PASS records=(\d+) raw_boundary_differences=(\d+) mismatch=0')
    $expected = [regex]::Match((Get-Content -Raw generator.log), 'normal_checks=(\d+) clamp_checks=(\d+) sac_pairs=(\d+) fixture_rows=(\d+) raw_boundary_differences=(\d+)')
    if (!$actual.Success -or !$expected.Success -or $log -match '\*\*\s+(Error|Fatal):') { throw 'Fig5 simulation failed' }
    if ($actual.Groups[1].Value -ne $expected.Groups[4].Value -or $actual.Groups[2].Value -ne $expected.Groups[5].Value) { throw 'Incomplete Fig5 checks' }
    foreach ($source in $sources) {
        if ((Get-FileHash (Join-Path $projectPath $source) -Algorithm SHA256).Hash -ne $hashes[$source]) { throw 'Source changed during run' }
    }
    [pscustomobject]@{
        status = 'PASS'; date = (Get-Date -Format o); seed = 'deterministic exhaustive/directed; no PRNG'
        RTLComparisons = [int]$actual.Groups[1].Value; mismatches = 0
        rawFigureBoundaryDifferences = [int]$actual.Groups[2].Value
        softwarePackComparisons = [int]$expected.Groups[1].Value
        SACPairsCompared = [int]$expected.Groups[3].Value
        simulator = (Get-Content -Raw version.log).Trim()
        command = 'scripts/verify_paper_contract_modelsim.ps1'
        fixtureSHA256 = (Get-FileHash packer.txt -Algorithm SHA256).Hash
        sourceSHA256 = $hashes
        scope = 'literal Fig5 normal encoding, explicit project clamps at range edges; not source special flags, original SAC, TableI or Gate2 acceptance'
    } | ConvertTo-Json -Depth 4 | Set-Content summary.json
    Write-Output $actual.Value
} finally {
    $env:TEMP = $oldTemp
    $env:TMP = $oldTmp
    Pop-Location
}
