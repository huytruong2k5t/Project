param([switch]$Apply, [ValidatePattern('^\d{8}$')][string]$Checkpoint = '20261011')
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$resultsRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'results'))
$resultsPrefix = $resultsRoot + [IO.Path]::DirectorySeparatorChar
function Assert-ResultPath([string]$Target) {
    $resolvedTarget = [IO.Path]::GetFullPath($Target)
    if (-not $resolvedTarget.StartsWith($resultsPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Cleanup target outside results: $resolvedTarget"
    }
    if ((Get-Item -LiteralPath $resolvedTarget -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Cleanup target is a link: $resolvedTarget"
    }
}
$allItems = @(Get-ChildItem -LiteralPath $resultsRoot -Recurse -Force)
if (@($allItems | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) {
    throw 'A link exists in results; review it before recursive cleanup.'
}
$allFiles = @($allItems | Where-Object { -not $_.PSIsContainer })
$cacheNames = @('obj_dir','work','tmp','db','incremental_db','xsim.dir','__pycache__')
$cacheDirs = @()
foreach ($candidate in @($allItems | Where-Object { $_.PSIsContainer -and $_.Name -in $cacheNames } | Sort-Object { $_.FullName.Length })) {
    $underChosen = $false
    foreach ($chosen in $cacheDirs) {
        if ($candidate.FullName.StartsWith($chosen.FullName + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            $underChosen = $true
        }
    }
    if (-not $underChosen) { $cacheDirs += $candidate }
}
$removeFiles = @()
$preserved = @()
$fixtureRoot = [IO.Path]::GetFullPath((Join-Path $resultsRoot 'week9_multiplier/stratified_corpus'))
foreach ($file in $allFiles) {
    $reason = $null
    foreach ($dir in $cacheDirs) {
        if ($file.FullName.StartsWith($dir.FullName + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            $reason = 'Rebuildable compiler/simulator cache'
            break
        }
    }
    if ($file.DirectoryName -eq $fixtureRoot -and $file.Name -match '^mul_\d+_\d+_[01]_[01]\.txt$') {
        $reason = 'Regenerate: gen_week9_multiplier results/week9_multiplier/stratified_corpus 1056000 stratified'
    }
    $w10Prefix = [IO.Path]::GetFullPath((Join-Path $resultsRoot 'week10_adder')) + [IO.Path]::DirectorySeparatorChar
    $projectionPrefix = [IO.Path]::GetFullPath((Join-Path $resultsRoot 'week10_contract')) + [IO.Path]::DirectorySeparatorChar
    if (($file.FullName.StartsWith($w10Prefix, [StringComparison]::OrdinalIgnoreCase) -and
         $file.Name -in @('gen_vectors','gen_vectors_ubsan','gen_paired')) -or
        ($file.FullName.StartsWith($projectionPrefix, [StringComparison]::OrdinalIgnoreCase) -and
         $file.Name -in @('test_projection','test_projection_ubsan'))) {
        $reason = 'Rebuild W10 ELF test/generator executable from source'
    }
    if ($file.FullName.StartsWith($w10Prefix, [StringComparison]::OrdinalIgnoreCase) -and
        (($file.DirectoryName.EndsWith('ubsan_vectors') -and $file.Name -like 'add_*.txt') -or
         ($file.DirectoryName.EndsWith('paired') -and $file.Name -eq 'replay.txt'))) {
        $reason = 'Rebuild W10 UBSan fixture or identical paired replay; keep primary pilot inputs and logs'
    }
    if ($file.Extension -in @('.wlf','.vcd','.fst','.vpd')) { $reason = 'Regenerate simulation waveform' }
    $relative = [IO.Path]::GetRelativePath($resultsRoot, $file.FullName).Replace('\','/')
    if ($reason) {
        Assert-ResultPath $file.FullName
        $removeFiles += [PSCustomObject]@{ path=$relative; bytes=$file.Length; reason=$reason; sha256=$null }
    } else {
        $preserved += $file
    }
}
$beforeBytes = ($allFiles | Measure-Object Length -Sum).Sum
$removedBytes = ($removeFiles | Measure-Object bytes -Sum).Sum
Write-Output ("PLAN: {0} files / {1:N2} MiB removed; {2} files retained; before {3:N2} MiB" -f $removeFiles.Count,($removedBytes/1MB),$preserved.Count,($beforeBytes/1MB))
if (-not $Apply) { Write-Output 'Preview only. Run with -Apply after reviewing the plan.'; return }
$runningSimulators = @(Get-Process -Name vsim,vlog,verilator,make -ErrorAction SilentlyContinue)
if ($runningSimulators.Count) { throw 'A simulator/build process is active; wait for completion before cleanup.' }
$retainedHashes = @()
foreach ($file in $preserved) {
    $retainedHashes += [PSCustomObject]@{
        path=[IO.Path]::GetRelativePath($resultsRoot,$file.FullName).Replace('\','/')
        bytes=$file.Length
        sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}
foreach ($record in $removeFiles | Where-Object { $_.path -like 'week9_multiplier/stratified_corpus/mul_*.txt' }) {
    $record.sha256=(Get-FileHash -LiteralPath (Join-Path $resultsRoot $record.path) -Algorithm SHA256).Hash.ToLowerInvariant()
}
$manifestPath = Join-Path $resultsRoot ('cleanup_' + $Checkpoint + '_manifest.json')
if (Test-Path -LiteralPath $manifestPath) { throw 'This cleanup checkpoint already exists; preserve it and use a new checkpoint for another session.' }
$manifest = [ordered]@{
    date=[DateTime]::ParseExact($Checkpoint,'yyyyMMdd',[Globalization.CultureInfo]::InvariantCulture).ToString('yyyy-MM-dd'); timezone='Asia/Saigon'; status='PLANNED'; scope='Only Posit_MAC/results'
    before_bytes=$beforeBytes; removed_bytes=$removedBytes; removed_file_count=$removeFiles.Count
    cache_directory_count=$cacheDirs.Count
    policy='Keep all historical summaries/logs/CSV/coverage/source snapshots/PPA evidence and small pilot/corner/replay fixtures; remove caches, large stratified mul fixtures and waves. W10 ELF generators/UBSan duplicate inputs are also rebuilt; primary pilot input retained. Cache hashes omitted; stratified fixture and retained evidence hashes recorded.'
    rebuild_guide='../../doc/HUONG_DAN_CHAY_WSL_MODELSIM.md sections6.1/6.4/6.5; results/README.md'
    removed=$removeFiles; retained=$retainedHashes
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8
foreach ($dir in $cacheDirs) {
    Assert-ResultPath $dir.FullName
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force
}
foreach ($record in $removeFiles) {
    $target = Join-Path $resultsRoot $record.path
    if (Test-Path -LiteralPath $target) {
        Assert-ResultPath $target
        Remove-Item -LiteralPath $target -Force
    }
}
# Remove empty child directories only; retain results itself and every evidence directory.
foreach ($dir in @(Get-ChildItem -LiteralPath $resultsRoot -Recurse -Directory -Force | Sort-Object { $_.FullName.Length } -Descending)) {
    if (-not @(Get-ChildItem -LiteralPath $dir.FullName -Force).Count) {
        Assert-ResultPath $dir.FullName
        Remove-Item -LiteralPath $dir.FullName -Force
    }
}
foreach ($record in $retainedHashes) {
    $target=Join-Path $resultsRoot $record.path
    if (-not (Test-Path -LiteralPath $target)) { throw "Retained evidence missing: $($record.path)" }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $record.sha256) {
        throw "Retained evidence changed: $($record.path)"
    }
}
$manifest.status='COMPLETE'
$manifest.retained_hash_check='PASS: every retained file unchanged before documentation updates'
$manifest.after_bytes=(Get-ChildItem -LiteralPath $resultsRoot -Recurse -File -Force | Measure-Object Length -Sum).Sum
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Write-Output ("COMPLETE: saved {0:N2} MiB; remaining about {1:N2} MiB; retained hashes verified." -f ($removedBytes/1MB),($manifest.after_bytes/1MB))
