param([switch]$Apply,
      [ValidatePattern('^results/[a-zA-Z0-9_/-]+$')]
      [string]$ReportRoot = ('results/cleanup_' + (Get-Date -Format yyyyMMdd_HHmmss)),
      [ValidatePattern('^results(/[a-zA-Z0-9_/-]+)?$')]
      [string]$ScopeRoot = 'results')
$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$results = [IO.Path]::GetFullPath((Join-Path $project 'results'))
$prefix = $results + [IO.Path]::DirectorySeparatorChar
# Only disposable tool databases. Keep source snapshots, fixtures, raw coverage,
# CSV/JSON, plots, logs, timing reports, seeds and hash manifests.
$disposable = @('obj_dir','obj_fast','work','db','incremental_db','xsim.dir','.Xil','tmp','__pycache__')
$scan = [IO.Path]::GetFullPath((Join-Path $project $ScopeRoot))
if ($scan -ne $results -and !$scan.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) {throw 'Cleanup scope outside results'}
$all = @(Get-ChildItem -LiteralPath $scan -Recurse -Force)
if (@($all | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) {
    throw 'Reparse point inside results: review manually before cleanup.'
}
$targets = @()
foreach ($dir in @($all | Where-Object { $_.PSIsContainer -and $_.Name -in $disposable } | Sort-Object { $_.FullName.Length })) {
    $path = [IO.Path]::GetFullPath($dir.FullName)
    if (!$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'Target outside results' }
    if (@($targets | Where-Object { $path.StartsWith($_ + '\',[StringComparison]::OrdinalIgnoreCase) }).Count -eq 0) {
        $targets += $path
    }
}
$removed = @(); $kept = @()
foreach ($file in @($all | Where-Object { !$_.PSIsContainer })) {
    $inside = @($targets | Where-Object { $file.FullName.StartsWith($_ + '\',[StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
    if ($inside) { $removed += $file } else { $kept += $file }
}
$report = [ordered]@{
    mode = $(if ($Apply) {'APPLIED'} else {'DRY_RUN'})
    scope = $ScopeRoot
    date = (Get-Date -Format o)
    before_bytes = [long](($removed + $kept | Measure-Object Length -Sum).Sum)
    reclaim_bytes = [long](($removed | Measure-Object Length -Sum).Sum)
    retained_bytes = [long](($kept | Measure-Object Length -Sum).Sum)
    removed_files = $removed.Count
    retained_files = $kept.Count
    targets = @($targets | ForEach-Object { $_.Substring($project.Length+1).Replace('\','/') })
    policy = 'Only disposable build/cache directories; source/evidence/fixtures remain byte-identical.'
}
if (!$Apply) { $report | ConvertTo-Json -Depth 5; return }
$out = [IO.Path]::GetFullPath((Join-Path $project $ReportRoot))
if (!$out.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) {throw 'Report directory outside results'}
New-Item -ItemType Directory -Force $out | Out-Null
$protected = @($kept | Where-Object {
    # These two generated receipts are replaced after verification below.
    $_.FullName -ne (Join-Path $out 'cleanup.json') -and
    $_.FullName -ne (Join-Path $out 'retained_sha256.json')
} | ForEach-Object {
    [pscustomobject]@{ path=$_.FullName.Substring($project.Length+1).Replace('\','/');
        sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
})
foreach ($path in $targets) {
    $resolved = (Resolve-Path -LiteralPath $path).Path
    if (!$resolved.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'Resolved target outside results' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
foreach ($entry in $protected) {
    $digest = (Get-FileHash -LiteralPath (Join-Path $project $entry.path) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($digest -ne $entry.sha256) { throw "Retained evidence changed: $($entry.path)" }
}
$report['retained_hash_check'] = 'PASS'
$protected | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $out 'retained_sha256.json')
$report | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $out 'cleanup.json')
$report | ConvertTo-Json -Depth 5
