param([switch]$Apply)
$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$separator = [IO.Path]::DirectorySeparatorChar
$results = [IO.Path]::GetFullPath((Join-Path $project 'results'))
$resultsPrefix = $results + $separator
$receipt = Join-Path $results 'cleanup_cache_20261023'
$cacheNames = @('obj','obj_dir','obj_fast','work','db','incremental_db','xsim.dir','.Xil','tmp','__pycache__','.pytest_cache')
$waveExtensions = @('.wlf','.vcd','.fst','.vpd')
$all = @(Get-ChildItem -LiteralPath $results -Recurse -Force)
if (@($all | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) {
    throw 'Reparse point found; no deletion is allowed without a separate review'
}
$extraCache = Join-Path $project 'scripts/__pycache__'
if (Test-Path -LiteralPath $extraCache) {
    $extraItem = Get-Item -LiteralPath $extraCache -Force
    if ($extraItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked Python cache' }
    $extraChildren = @(Get-ChildItem -LiteralPath $extraCache -Recurse -Force)
    if (@($extraChildren | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) { throw 'Linked Python cache child' }
    $all += $extraItem
    $all += $extraChildren
}

function Assert-CachePath([string]$Path) {
    $absolute = [IO.Path]::GetFullPath($Path)
    $insideResults = $absolute.StartsWith($resultsPrefix,[StringComparison]::OrdinalIgnoreCase)
    $insidePython = $absolute.Equals($extraCache,[StringComparison]::OrdinalIgnoreCase) -or
        $absolute.StartsWith($extraCache+$separator,[StringComparison]::OrdinalIgnoreCase)
    if ((!$insideResults -and !$insidePython) -or $absolute.Equals($results,[StringComparison]::OrdinalIgnoreCase)) {
        throw "Target outside approved cache locations: $absolute"
    }
    return $absolute
}

$directories = [System.Collections.Generic.List[string]]::new()
foreach ($item in ($all | Where-Object { $_.PSIsContainer -and ($_.Name -in $cacheNames -or $_.Name -match '^obj_[A-Za-z0-9_]+$') } | Sort-Object { $_.FullName.Length })) {
    $absolute = Assert-CachePath $item.FullName
    $nested = $false
    foreach ($parent in $directories) {
        if ($absolute.StartsWith($parent+$separator,[StringComparison]::OrdinalIgnoreCase)) { $nested=$true; break }
    }
    if (!$nested) { $directories.Add($absolute) }
}
$deleted = [System.Collections.Generic.List[object]]::new()
$retained = [System.Collections.Generic.List[object]]::new()
$waves = [System.Collections.Generic.List[string]]::new()
foreach ($item in ($all | Where-Object { !$_.PSIsContainer })) {
    $inside = $false
    foreach ($parent in $directories) {
        if ($item.FullName.StartsWith($parent+$separator,[StringComparison]::OrdinalIgnoreCase)) { $inside=$true; break }
    }
    if ($inside) { $deleted.Add($item) }
    elseif ($item.Extension -in $waveExtensions) {
        [void](Assert-CachePath $item.FullName)
        $deleted.Add($item)
        $waves.Add($item.FullName)
    } else { $retained.Add($item) }
}
$report = [ordered]@{
    status=$(if($Apply){'APPLIED'}else{'DRY_RUN'})
    date='2026-10-23'; scope='results and scripts/__pycache__ only; scratch/Git/dependencies untouched'
    before_bytes=[long](($all | Where-Object { !$_.PSIsContainer } | Measure-Object Length -Sum).Sum)
    reclaimed_bytes=[long](($deleted | Measure-Object Length -Sum).Sum)
    retained_bytes=[long](($retained | Measure-Object Length -Sum).Sum)
    removed_files=$deleted.Count; retained_files=$retained.Count
    directory_count=$directories.Count; standalone_wave_count=$waves.Count
    policy='Delete build/library/cache directories and waves; preserve reports, logs, fixtures, raw coverage, source snapshots, archives and hashes'
}
if (!$Apply) { [pscustomobject]$report; return }
if (Test-Path -LiteralPath $receipt) { throw 'Preserve existing cleanup receipt' }
if (@(Get-Process -Name vsim,vlog,vivado,xsim,cc1plus,verilator,gcc,'g++',make -ErrorAction SilentlyContinue).Count) {
    throw 'Compiler/simulator active: preserve caches and retry after it finishes'
}
New-Item -ItemType Directory -Path $receipt | Out-Null
Write-Output ('Hashing '+$retained.Count+' retained evidence files before deletion...')
$protected = @($retained | Sort-Object FullName | ForEach-Object {
    @{path=$_.FullName.Substring($project.Length+1).Replace('\','/');
      sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
})
$bytes = [Text.Encoding]::UTF8.GetBytes(($protected | ConvertTo-Json -Depth 4 -Compress))
$stream = [IO.File]::Create((Join-Path $receipt 'retained_sha256.json.gz'))
$gzip = [IO.Compression.GZipStream]::new($stream,[IO.Compression.CompressionLevel]::Optimal)
try { $gzip.Write($bytes,0,$bytes.Length) } finally { $gzip.Dispose(); $stream.Dispose() }
foreach ($path in $directories) {
    $resolved = (Resolve-Path -LiteralPath $path).Path
    [void](Assert-CachePath $resolved)
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
foreach ($path in $waves) {
    $resolved = (Resolve-Path -LiteralPath $path).Path
    [void](Assert-CachePath $resolved)
    Remove-Item -LiteralPath $resolved -Force
}
Write-Output 'Verifying retained files byte-for-byte by SHA256...'
foreach ($entry in $protected) {
    $hash = (Get-FileHash -LiteralPath (Join-Path $project $entry.path) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $entry.sha256) { throw ('Retained evidence changed: '+$entry.path) }
}
$report['retained_hash_check']='PASS'
$report['removed_directories']=@($directories | ForEach-Object { $_.Substring($project.Length+1).Replace('\','/') })
$report['removed_waves']=@($waves | ForEach-Object { $_.Substring($project.Length+1).Replace('\','/') })
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $receipt 'cleanup.json') -Encoding utf8NoBOM
[pscustomobject]$report | Select-Object status,before_bytes,reclaimed_bytes,retained_bytes,removed_files,retained_files,directory_count,standalone_wave_count,retained_hash_check
