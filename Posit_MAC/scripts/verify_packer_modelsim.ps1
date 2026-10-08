param(
    [string]$ModelSimBin = 'C:\altera\13.0sp1\modelsim_ase\win32aloem',
    [switch]$CollectExisting
)

$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$resultPath = Join-Path $projectPath 'results/packer'
$parserPath = Join-Path $projectPath 'results/parser_comb'
$sources = @(
    'rtl/posit_mac.vh',
    'rtl/dyn_right_shifter.sv',
    'rtl/posit_pack_prepare.sv',
    'rtl/posit_pack_finish.sv',
    'rtl/posit_pack_comb.sv',
    'rtl/posit_pack.sv',
    'rtl/lod_lzd_core.sv',
    'rtl/dyn_left_shifter.sv',
    'rtl/posit_parser.sv',
    'tb/packer_checker.sv',
    'tb/tb_posit_pack.sv',
    'tb/parser_packer_checker.sv',
    'tb/tb_parser_packer.sv',
    'l1/test/gen_packer_vectors.cpp',
    'l1/include/posit_packer.hpp',
    'l1/include/posit_parser.hpp',
    'l1/include/posit_types.hpp',
    'l1/gen_packer_vectors.exe',
    'scripts/verify_packer_modelsim.ps1'
)

function Source-Hashes {
    foreach ($name in $sources) {
        $hash = Get-FileHash -LiteralPath (Join-Path $projectPath $name) -Algorithm SHA256
        $hash.Hash.ToLowerInvariant() + '  ' + $name
    }
}

function Run-Tool([string]$Name, [string[]]$Arguments, [string]$LogName) {
    & (Join-Path $ModelSimBin "$Name.exe") @Arguments 2>&1 |
        Tee-Object -FilePath $LogName
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed: exit=$LASTEXITCODE; see $LogName"
    }
}

$parserSummary = Get-Content -Raw (Join-Path $parserPath 'summary.json') | ConvertFrom-Json
if ($parserSummary.status -ne 'PASS' -or $parserSummary.checks -ne 2465812) {
    throw 'Accepted parser fixtures are required.'
}
foreach ($line in Get-Content (Join-Path $parserPath 'vectors.sha256')) {
    $parts = $line -split '  ', 2
    $hash = Get-FileHash -LiteralPath (Join-Path $parserPath $parts[1]) -Algorithm SHA256
    if ($hash.Hash.ToLowerInvariant() -ne $parts[0]) {
        throw "Parser fixture hash changed: $($parts[1])"
    }
}

New-Item -ItemType Directory -Force $resultPath | Out-Null
Push-Location $resultPath
try {
    if ($CollectExisting) {
        if (@(Compare-Object (Get-Content compiled_sources.sha256) @(Source-Hashes)).Count) {
            throw 'Existing logs do not match the current source snapshot.'
        }
        foreach ($line in Get-Content vectors.sha256) {
            $parts = $line -split '  ', 2
            $hash = Get-FileHash -LiteralPath $parts[1] -Algorithm SHA256
            if ($hash.Hash.ToLowerInvariant() -ne $parts[0]) {
                throw "Packer fixture hash changed: $($parts[1])"
            }
        }
    } else {
        $generator = Join-Path $projectPath 'l1/gen_packer_vectors.exe'
        & $generator '.' 2>&1 | Tee-Object -FilePath generator.log
        if ($LASTEXITCODE -ne 0) { throw 'Fixture generator failed.' }
        Source-Hashes | Set-Content compiled_sources.sha256
        Get-ChildItem -Filter 'packer_*.txt' | ForEach-Object {
            (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() +
            '  ' + $_.Name
        } | Set-Content vectors.sha256
        if (!(Test-Path work)) { Run-Tool 'vlib' @('work') 'library.log' }
        $compileSources = $sources | Where-Object { $_ -like '*.sv' } |
            ForEach-Object { '../../' + $_ }
        Run-Tool 'vlog' (@('-sv', '-timescale', '1ns/1ps', '+incdir+../../rtl') +
            $compileSources + @('-l', 'compile.log')) 'compile_console.log'
        @('onerror {quit -code 1}', 'onbreak {quit -code 1}',
          'run -all', 'quit -code 0') | Set-Content -Encoding ascii run.do
        Run-Tool 'vsim' @('-c', 'work.tb_posit_pack', '-l', 'simulate.log',
                         '-do', 'run.do') 'simulate_console.log'
        Run-Tool 'vsim' @('-c', 'work.tb_parser_packer', '-l', 'chain.log',
                         '-do', 'run.do') 'chain_console.log'
    }
    Run-Tool 'vsim' @('-version') 'version.log'
    $generatorLog = Get-Content -Raw generator.log
    $packLog = Get-Content -Raw simulate.log
    $chainLog = Get-Content -Raw chain.log
    $compileLog = Get-Content -Raw compile.log
    if (Test-Path chain_compile.log) {
        $compileLog += Get-Content -Raw chain_compile.log
    }
    if ($generatorLog -notmatch 'PACKER GENERATOR PASS rows=2973524' -or
        $packLog -notmatch 'PACKER ALL PASS' -or
        $chainLog -notmatch 'PARSER PACKER ALL PASS' -or
        ($packLog + $chainLog + $compileLog) -match '\*\*\s+(Error|Fatal):|timeout') {
        throw 'Packer acceptance incomplete or failed.'
    }
    $packSuites = @()
    foreach ($m in [regex]::Matches($packLog,
        'PACK PASS NB=(\d+) ES=(\d+) MODE=(\w+) rows=(\d+) comb=(\d+) received=(\d+) resets=(\d+) discarded=(\d+) stall=(\d+) full=(\d+) simultaneous=(\d+) latency=(\d+)')) {
        $packSuites += [pscustomobject]@{
            NB=[int]$m.Groups[1].Value; ES=[int]$m.Groups[2].Value
            mode=$m.Groups[3].Value; rows=[long]$m.Groups[4].Value
            comb=[long]$m.Groups[5].Value; received=[long]$m.Groups[6].Value
            resets=[int]$m.Groups[7].Value; discarded=[int]$m.Groups[8].Value
            stall=[long]$m.Groups[9].Value; full=[long]$m.Groups[10].Value
            simultaneous=[long]$m.Groups[11].Value; latency=[long]$m.Groups[12].Value
        }
    }
    $chainSuites = @()
    foreach ($m in [regex]::Matches($chainLog,
        'CHAIN PASS NB=(\d+) ES=(\d+) MODE=(\w+) rows=(\d+) discarded=(\d+) resets=(\d+) stall=(\d+) latency=(\d+)')) {
        $chainSuites += [pscustomobject]@{
            NB=[int]$m.Groups[1].Value; ES=[int]$m.Groups[2].Value
            mode=$m.Groups[3].Value; rows=[long]$m.Groups[4].Value
            discarded=[int]$m.Groups[5].Value; resets=[int]$m.Groups[6].Value
            stall=[long]$m.Groups[7].Value; latency=[long]$m.Groups[8].Value
        }
    }
    if ($packSuites.Count -ne 8 -or ($packSuites | Measure-Object rows -Sum).Sum -ne 5947048 -or
        $chainSuites.Count -ne 8 -or ($chainSuites | Measure-Object rows -Sum).Sum -ne 4931624) {
        throw 'Incomplete suite counts.'
    }
    [pscustomobject]@{
        status='PASS'; date=(Get-Date -Format o); seed=20261006; mismatches=0
        input_rows=2973524; pack_mode_checks=5947048; chain_checks=4931624
        oracle='accepted L1 pack/parse plus independent variable-length bit-list encoder'
        simulator=(Get-Content -Raw version.log).Trim()
        pack_suites=$packSuites; chain_suites=$chainSuites
        ppa_status='MEASURED_QUARTUS_STANDALONE_SEPARATE_SUMMARY'
        command='scripts/verify_packer_modelsim.ps1'
    } | ConvertTo-Json -Depth 6 | Set-Content summary.json
    Write-Output 'PACKER ACCEPTANCE PASS pack=5947048 chain=4931624 mismatches=0'
} finally {
    Pop-Location
}
