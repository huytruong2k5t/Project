param([string]$RunRoot='results/parser_lod_refactor_recheck_20261101',
      [string]$Baseline='results/readme_refactor_recheck_20261101',
      [ValidatePattern('^[A-Za-z0-9_]+$')][string]$OutputName='critical_path_diagnosis')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$run=Join-Path $root $RunRoot
$output=Join-Path $run $OutputName
if(Test-Path -LiteralPath $output){throw 'Preserve existing diagnosis; choose a fresh RunRoot'}
foreach($dir in @('tmp','appdata','localappdata')){New-Item -ItemType Directory -Force "$output/$dir"|Out-Null}
$env:TEMP="$output/tmp";$env:TMP=$env:TEMP;$env:APPDATA="$output/appdata";$env:LOCALAPPDATA="$output/localappdata";$env:XILINX_LOCAL_USER_DATA='no'
Copy-Item "$PSScriptRoot/query_mac_critical_paths.tcl" "$output/query.tcl"
Copy-Item $PSCommandPath "$output/runner.ps1"
$arguments=@()
$checkpoints=@{}
foreach($variant in @('f','nf')) {
    foreach($version in @('old','new')) {
        $sourceRoot=if($version -eq 'old'){Join-Path $root $Baseline}else{$run}
        $checkpoint=Join-Path $sourceRoot "synth_${variant}_final/synthesis.dcp"
        $label="${variant}_$version"
        $arguments+=@($label,$checkpoint)
        $checkpoints[$label]=@{path=$checkpoint;sha256=(Get-FileHash -LiteralPath $checkpoint).Hash}
    }
}
@{scope='Read-only queries of existing synthesized checkpoints; no resynthesis/place/route';checkpoints=$checkpoints;script_sha256=(Get-FileHash "$output/query.tcl").Hash}|
    ConvertTo-Json -Depth 5|Set-Content "$output/manifest.json"
Push-Location $output
try {
    & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -notrace -source "$output/query.tcl" -tclargs @arguments > console.log
    if($LASTEXITCODE){throw 'Critical path queries failed; inspect console.log'}
    foreach($label in $checkpoints.Keys) {
        if((Get-Content "$label/status.txt" -Raw).Trim() -ne 'QUERY_COMPLETE'){throw "Missing status $label"}
    }
    'QUERY_COMPLETE'|Set-Content status.txt
    'ALL_QUERIES_COMPLETE'
} finally {Pop-Location}
