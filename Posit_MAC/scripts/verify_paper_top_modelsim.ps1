param([string]$ModelSimBin = 'C:\altera\13.0sp1\modelsim_ase\win32aloem')
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$resultPath = Join-Path $projectPath 'results/paper_top/windows'
New-Item -ItemType Directory -Force $resultPath | Out-Null
function Run-Tool([string]$Path, [string[]]$ToolArguments, [string]$LogName) {
    & $Path @ToolArguments 2>&1 | Tee-Object -FilePath $LogName
    if ($LASTEXITCODE -ne 0) { throw "$Path failed: $LASTEXITCODE; see $LogName" }
}
Push-Location $resultPath
$oldTemp = $env:TEMP
$oldTmp = $env:TMP
try {
    $env:TEMP = Join-Path $projectPath 'results/paper_top/tmp'
    $env:TMP = $env:TEMP
    New-Item -ItemType Directory -Force $env:TEMP | Out-Null
    Run-Tool (Join-Path $projectPath 'l1/gen_paper_top.exe') @('../../paper_discriminators/linux/vectors.csv', '.') 'generator.log'
    Run-Tool (Join-Path $ModelSimBin 'vsim.exe') @('-version') 'version.log'
    if (!(Test-Path work)) { Run-Tool (Join-Path $ModelSimBin 'vlib.exe') @('work') 'library.log' }
    $sources = @('rtl/lod_lzd_core.sv', 'rtl/dyn_left_shifter.sv', 'rtl/dyn_right_shifter.sv',
        'rtl/posit_parser_comb.sv', 'rtl/posit_pack_prepare.sv', 'rtl/posit_pack_finish.sv',
        'rtl/posit_pack_comb.sv', 'rtl/paper_ops_comb.sv', 'rtl/paper_step_comb.sv',
        'rtl/paper_norm_comb.sv', 'rtl/paper_mul_wrapper.sv', 'rtl/paper_mul_iter.sv',
        'tb/tb_paper_mul_iter.sv')
    $sourceHashes = @{}
    foreach ($source in $sources) {
        $sourceHashes[$source] = (Get-FileHash (Join-Path $projectPath $source) -Algorithm SHA256).Hash
    }
    $sourcePaths = $sources | ForEach-Object { Join-Path $projectPath $_ }
    Run-Tool (Join-Path $ModelSimBin 'vlog.exe') (@('-sv', '-timescale', '1ns/1ps', '-work', 'work', "+incdir+$projectPath/rtl") + $sourcePaths + @('-l', 'compile.log')) 'compile_console.log'
    @('onerror {quit -code 1}', 'onbreak {quit -code 1}', 'run -all', 'quit -code 0') | Set-Content -Encoding ascii run.do
    $process = Start-Process -FilePath (Join-Path $ModelSimBin 'vsim.exe') -ArgumentList @('-c', 'work.tb_paper_mul_iter', '-l', 'simulate.log', '-do', 'run.do') -WorkingDirectory $resultPath -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput 'simulate_console.log' -RedirectStandardError 'simulate_stderr.log'
    if ($process.ExitCode -ne 0) { throw "ModelSim failed: $($process.ExitCode)" }
    $log = Get-Content -Raw simulate.log
    $actual = [regex]::Match($log, 'PAPER TOP PASS records=(\d+) commits=(\d+) specials=(\d+) Fig4=(\d+) negative=(\d+) zero_terms=(\d+) tail=(\d+) early=(\d+) long_stalls=(\d+) resets=(\d+) mismatch=0')
    $expected = [regex]::Match((Get-Content -Raw generator.log), 'records=(\d+) commits=(\d+) specials=(\d+) frozen=(\d+)')
    if (!$actual.Success -or !$expected.Success -or $log -match '\*\*\s+(Error|Fatal):') { throw 'Paper top verification failed' }
    foreach ($i in 1..3) {
        if ($actual.Groups[$i].Value -ne $expected.Groups[$i].Value) { throw 'Incomplete comparison' }
    }
    foreach ($source in $sources) {
        if ((Get-FileHash (Join-Path $projectPath $source) -Algorithm SHA256).Hash -ne $sourceHashes[$source]) { throw 'Source changed during simulation' }
    }
    [pscustomobject]@{
        status = 'PASS'; date = (Get-Date -Format o); seed = 20261009
        transactions = [int]$actual.Groups[1].Value; commits = [int]$actual.Groups[2].Value
        specials = [int]$actual.Groups[3].Value; frozenCorpusRecords = [int]$expected.Groups[4].Value
        Fig4 = '0x1ae34000'; Fig4Matches = [int]$actual.Groups[4].Value
        negativeTerms = [int]$actual.Groups[5].Value; zeroTerms = [int]$actual.Groups[6].Value
        tailTerms = [int]$actual.Groups[7].Value; earlyStops = [int]$actual.Groups[8].Value
        longStalls96Cycles = [int]$actual.Groups[9].Value; resetAborts = [int]$actual.Groups[10].Value
        mismatches = 0; simulator = (Get-Content -Raw version.log).Trim()
        command = 'scripts/verify_paper_top_modelsim.ps1'
        sourceSHA256 = $sourceHashes
        transactionsSHA256 = (Get-FileHash transactions.txt -Algorithm SHA256).Hash
        tracesSHA256 = (Get-FileHash traces.txt -Algorithm SHA256).Hash
        contract = 'posit32 ES3, Q12, PT2 prefix7 zero padding, tie-A, complement, first anchor, per-term FLOOR, output cut12/TRUNC'
        latency = 'out_valid E(t+1), E0=input handshake, t=actual committed terms; special t=0; no overlap'
        scope = 'autonomous reconstructed paper profile only; no recovered author RTL, Table I, Gate2, lint or STA claim'
    } | ConvertTo-Json -Depth 5 | Set-Content summary.json
    Write-Output $actual.Value
} finally {
    $env:TEMP = $oldTemp
    $env:TMP = $oldTmp
    Pop-Location
}
