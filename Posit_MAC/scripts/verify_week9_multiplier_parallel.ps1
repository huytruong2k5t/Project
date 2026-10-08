param([string]$ModelSimBin='C:\altera\13.0sp1\modelsim_ase\win32aloem',
      [string]$FixtureRun='final_pilot',[string]$RunName='parallel_pilot',
      [ValidateRange(1,12)][int]$Jobs=8)
$ErrorActionPreference='Stop'
if($FixtureRun -notmatch '^[a-z0-9_-]+$' -or $RunName -notmatch '^[a-z0-9_-]+$') {throw 'Invalid run names'}
$projectPath=Split-Path $PSScriptRoot -Parent
$fixturePath=Join-Path $projectPath "results/week9_multiplier/$FixtureRun"
$resultPath=Join-Path $projectPath "results/week9_multiplier/$RunName"
if($fixturePath -eq $resultPath) {throw 'Output must be separate from frozen fixtures'}
New-Item -ItemType Directory -Force $resultPath | Out-Null
$profiles=Get-ChildItem -LiteralPath $fixturePath -Filter 'mul_*.txt' | Sort-Object Name
if($profiles.Count -ne 16) {throw 'Expected sixteen frozen fixtures'}
Push-Location $resultPath
$active=@()
try {
    & (Join-Path $ModelSimBin 'vsim.exe') -version | Set-Content version.log
    if($LASTEXITCODE) {throw 'Version query failed'}
    if(!(Test-Path work)) {& (Join-Path $ModelSimBin 'vlib.exe') work | Set-Content library.log}
    $sources=@('lod_lzd_core','dyn_left_shifter','dyn_right_shifter','posit_parser',
        'ops_sel_comb','sac_step_comb','sbm_shift_comb','sbm_accum_comb','iter_ctrl','sbm_accum',
        'mul_iter_core','mul_norm_comb','posit_pack_prepare','posit_pack_finish','posit_pack',
        'mul_iter_wrapper','posit_mul_iter') | ForEach-Object {"../../../rtl/$_.sv"}
    $sources+=@('../../../tb/multiplier_checker.sv','../../../tb/tb_week9_multiplier_single.sv')
    $sourceHashes=@{}
    foreach($source in $sources) {$sourceHashes[$source]=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLower()}
    $sourceHashes['../../../rtl/posit_mac.vh']=(Get-FileHash -LiteralPath '../../../rtl/posit_mac.vh' -Algorithm SHA256).Hash.ToLower()
    @{source_sha256=$sourceHashes;scope='source captured immediately before vlog'} | ConvertTo-Json -Depth 4 | Set-Content frozen_source_sha256.json
    & (Join-Path $ModelSimBin 'vlog.exe') -sv -timescale 1ns/1ps '+incdir+../../../rtl' -work work @sources -l compile.log | Set-Content compile_console.log
    if($LASTEXITCODE) {throw 'Compile failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    $queue=[System.Collections.Generic.Queue[object]]::new()
    foreach($fixture in $profiles) {$queue.Enqueue($fixture)}
    while($queue.Count -or $active.Count) {
        while($queue.Count -and $active.Count -lt $Jobs) {
            $fixture=$queue.Dequeue()
            $parts=$fixture.BaseName.Split('_')
            $profile=$fixture.BaseName
            New-Item -ItemType Directory -Force $profile | Out-Null
            # One process has one DUT; all use the same read-only fixture directory.
            $relativeFixture="../$FixtureRun"
            $arguments=@('-c','work.tb_week9_multiplier_single',"-gNB=$($parts[1])", "-gES=$($parts[2])",
                "-gSCHEME=$($parts[3])","-gROUNDING=$($parts[4])", "+VECTOR_DIR=$relativeFixture",
                '-l',"$profile/simulate.log",'-wlf',"$profile/simulate.wlf",'-do','run.do')
            $process=Start-Process -FilePath (Join-Path $ModelSimBin 'vsim.exe') -ArgumentList $arguments -WorkingDirectory $resultPath -WindowStyle Hidden -PassThru -RedirectStandardOutput "$resultPath/$profile/console.log" -RedirectStandardError "$resultPath/$profile/error.log"
            $active+=@{process=$process;profile=$profile}
            Write-Output "START $profile PID=$($process.Id)"
        }
        $remaining=@()
        foreach($entry in $active) {
            $entry.process.Refresh()
            if(!$entry.process.HasExited) {$remaining+=$entry;continue}
            $entry.process.WaitForExit()
            $log=Get-Content -Raw "$($entry.profile)/simulate.log"
            if($entry.process.ExitCode -ne 0 -or $log -notmatch 'WEEK9 SINGLE PROFILE PASS' -or $log -match '\*\*\s+(Error|Fatal):') {throw "Failed profile $($entry.profile)"}
            Write-Output "PASS $($entry.profile)"
        }
        $active=$remaining
        if($queue.Count -or $active.Count) {Start-Sleep -Seconds 2}
    }
    $rows=0L;$completed=0L;$aborts=0L
    $profileResults=@()
    foreach($fixture in $profiles) {
        $log=Get-Content -Raw "$($fixture.BaseName)/simulate.log"
        $match=[regex]::Match($log,'MULTIPLIER PASS NB=(\d+) ES=(\d+) scheme=(\d+) rounding=(\d+) rows=(\d+) completed=(\d+) reset_aborts=(\d+)')
        if(!$match.Success) {throw 'Missing profile counts'}
        $r=[long]$match.Groups[5].Value;$c=[long]$match.Groups[6].Value;$a=[long]$match.Groups[7].Value
        if($r -ne $c+$a) {throw 'Count inconsistency'}
        $rows+=$r;$completed+=$c;$aborts+=$a
        $profileResults+=@{profile=$fixture.BaseName;rows=$r;completed=$c;resetAborts=$a;
            fixtureSHA256=(Get-FileHash -LiteralPath $fixture.FullName -Algorithm SHA256).Hash.ToLower()}
    }
    [pscustomobject]@{status='PASS';date=(Get-Date -Format o);seed=20261009;fixtureRows=$rows;
        comparedTransactions=$completed;resetAborts=$aborts;mismatches=0;profiles=$profileResults;
        simulator=(Get-Content -Raw version.log).Trim();fixtureRun=$FixtureRun;
        scope='same multiplier checker, isolated profile processes; no waveform recording';
        Gate2='numerical results only; lint and structural coverage still required';
        command="scripts/verify_week9_multiplier_parallel.ps1 -FixtureRun $FixtureRun -RunName $RunName -Jobs $Jobs"} |
        ConvertTo-Json -Depth 5 | Set-Content summary.json
    Write-Output "WEEK9 PARALLEL ALL PASS compared=$completed reset_aborts=$aborts"
} finally {
    foreach($entry in $active) {
        $entry.process.Refresh()
        if(!$entry.process.HasExited) {$entry.process.Kill();$entry.process.WaitForExit()}
    }
    Pop-Location
}
