# Source this helper after a runner's param block.
$script:RtlProject = Split-Path $PSScriptRoot -Parent
$script:RtlPaths = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'rtl_paths.json') -Raw | ConvertFrom-Json
function Resolve-RtlPath([string]$Name) {
    $key = 'rtl/' + [IO.Path]::GetFileNameWithoutExtension($Name) + '.sv'
    $entry = $script:RtlPaths.PSObject.Properties[$key]
    if ($null -eq $entry) { throw "Unknown RTL: $Name" }
    Join-Path $script:RtlProject $entry.Value
}
function Resolve-SourcePath([string]$Relative) {
    $key = $Relative.Replace('\','/')
    $entry = $script:RtlPaths.PSObject.Properties[$key]
    if ($null -ne $entry) { $key = $entry.Value }
    Join-Path $script:RtlProject $key
}
