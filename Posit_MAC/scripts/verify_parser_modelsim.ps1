param(
    [string]$ModelSimBin = 'C:\altera\13.0sp1\modelsim_ase\win32aloem',
    [switch]$CollectExisting
)

$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$resultPath = Join-Path $projectPath 'results/parser_pipeline'
$fixturePath = Join-Path $projectPath 'results/parser_comb'
$sourceNames = @(
    'rtl/posit_mac.vh',
    'rtl/lod_lzd_core.sv',
    'rtl/dyn_left_shifter.sv',
    'rtl/posit_parser.sv',
    'tb/parser_pipeline_checker.sv',
    'tb/tb_posit_parser.sv'
)

function Source-Hashes {
    foreach ($name in $sourceNames) {
        $hash = Get-FileHash -LiteralPath (Join-Path $projectPath $name) -Algorithm SHA256
        $hash.Hash.ToLowerInvariant() + '  ' + $name
    }
}

function Run-Tool([string]$Name, [string[]]$ToolArguments, [string]$LogName) {
    & (Join-Path $ModelSimBin "$Name.exe") @ToolArguments 2>&1 |
        Tee-Object -FilePath $LogName

    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed: exit=$LASTEXITCODE; see $LogName"
    }
}

# Require accepted fixtures, not arbitrary text files with a plausible row count.
$fixtureSummary = Get-Content -Raw (Join-Path $fixturePath 'summary.json') | ConvertFrom-Json
if ($fixtureSummary.status -ne 'PASS' -or $fixtureSummary.checks -ne 2465812) {
    throw 'Run verify_parser_comb_modelsim.ps1 to produce accepted fixtures first.'
}

foreach ($line in Get-Content (Join-Path $fixturePath 'vectors.sha256')) {
    $parts = $line -split '  ', 2
    $hash = Get-FileHash -LiteralPath (Join-Path $fixturePath $parts[1]) -Algorithm SHA256

    if ($hash.Hash.ToLowerInvariant() -ne $parts[0]) {
        throw "Fixture hash changed: $($parts[1])"
    }
}

New-Item -ItemType Directory -Force $resultPath | Out-Null
Push-Location $resultPath

try {
    if ($CollectExisting) {
        $saved = Get-Content -LiteralPath 'compiled_sources.sha256'
        $current = @(Source-Hashes)

        if (@(Compare-Object $saved $current).Count) {
            throw 'Existing simulation does not match current source hashes.'
        }
    } else {
        Source-Hashes | Set-Content 'compiled_sources.sha256'

        if (!(Test-Path 'work')) {
            Run-Tool 'vlib' @('work') 'library.log'
        }

        $arguments = @(
            '-sv', '-timescale', '1ns/1ps', '+incdir+../../rtl', '-work', 'work',
            '../../rtl/lod_lzd_core.sv',
            '../../rtl/dyn_left_shifter.sv',
            '../../rtl/posit_parser.sv',
            '../../tb/parser_pipeline_checker.sv',
            '../../tb/tb_posit_parser.sv',
            '-l', 'compile.log'
        )
        Run-Tool 'vlog' $arguments 'compile_console.log'

        @(
            'onerror {quit -code 1}',
            'onbreak {quit -code 1}',
            'run -all',
            'quit -code 0'
        ) | Set-Content -Encoding ascii 'run.do'

        Run-Tool 'vsim' @(
            '-c', 'work.tb_posit_parser', '-l', 'simulate.log', '-do', 'run.do'
        ) 'simulate_console.log'
    }

    Run-Tool 'vsim' @('-version') 'version.log'
    $log = Get-Content -Raw -LiteralPath 'simulate.log'
    $compileLog = Get-Content -Raw -LiteralPath 'compile.log'

    if ($log -notmatch 'PARSER_PIPELINE ALL PASS' -or
        $log -match '\*\*\s+(Error|Fatal):|PIPE .*FAIL|timeout' -or
        $compileLog -match '\*\*\s+(Error|Fatal):') {
        throw 'Parser pipeline acceptance did not pass.'
    }

    $pattern = 'PIPE PASS NB=(\d+) ES=(\d+) checks=(\d+) reset=(\d+) discarded=(\d+) stalls=(\d+) full=(\d+) simultaneous=(\d+) bubbles=(\d+) latency=(\d+)'
    $suites = @()

    foreach ($match in [regex]::Matches($log, $pattern)) {
        $suites += [pscustomobject]@{
            NB = [int]$match.Groups[1].Value
            ES = [int]$match.Groups[2].Value
            checks = [long]$match.Groups[3].Value
            resets = [int]$match.Groups[4].Value
            discardedByReset = [int]$match.Groups[5].Value
            stalledOutputChecks = [long]$match.Groups[6].Value
            fullPipelineChecks = [long]$match.Groups[7].Value
            simultaneousHandshakes = [long]$match.Groups[8].Value
            inputBubbles = [long]$match.Groups[9].Value
            noStallLatencyChecks = [long]$match.Groups[10].Value
        }
    }

    $total = ($suites | Measure-Object checks -Sum).Sum
    if ($suites.Count -ne 4 -or $total -ne 2465812) {
        throw 'Incomplete four-format parser acceptance.'
    }

    [pscustomobject]@{
        date = Get-Date -Format o
        status = 'PASS'
        checks = $total
        mismatches = 0
        fixtureSeed = 20261005
        handshakeSeed = '20261005 + NB*17 + ES; xorshift32'
        stages = 2
        capacity = 2
        unstalledII = 1
        timing = 'accept E0; output valid after E1; earliest output handshake E2'
        reset = 'reset_n: async assert, two-FF synchronous release; startup excluded from datapath latency'
        oracle = 'accepted parser_comb L1/independent field fixtures'
        simulator = (Get-Content -Raw version.log).Trim()
        suites = $suites
        compileCommand = 'vlog -sv -timescale 1ns/1ps +incdir+../../rtl -work work ../../rtl/lod_lzd_core.sv ../../rtl/dyn_left_shifter.sv ../../rtl/posit_parser.sv ../../tb/parser_pipeline_checker.sv ../../tb/tb_posit_parser.sv -l compile.log'
        simulationCommand = 'vsim -c work.tb_posit_parser -l simulate.log -do run.do'
    } | ConvertTo-Json -Depth 5 | Set-Content 'summary.json'

    Copy-Item -LiteralPath (Join-Path $fixturePath 'vectors.sha256') -Destination 'vectors.sha256'
    Source-Hashes | Set-Content 'sources.sha256'
    (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant() |
        Set-Content 'runner.sha256'

    Write-Output "PARSER PIPELINE MODELSIM PASS checks=$total mismatches=0"
} finally {
    Pop-Location
}
