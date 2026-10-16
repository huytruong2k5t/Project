param([ValidateSet('xc7a35tcpg236-1','xc7a100tcsg324-1')][string]$Part='xc7a35tcpg236-1',
      [ValidateSet('lod','lod_mixed','shift','chain','chain_extra','packer','confirm','release','adoption')][string]$Phase='lod',
      [string]$VivadoBin='C:/AMDDesignTools/2026.1/Vivado/bin',
      [switch]$FrozenSources,
      [ValidatePattern('^results/[a-zA-Z0-9_/-]+$')][string]$RunRoot='results/primitive_v2_20261016',
      [switch]$PlanOnly)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root 'results/primitive_v2_20261016'
$manifest=Get-Content -LiteralPath "$out/manifest.json" -Raw | ConvertFrom-Json
$dependency=Get-Content -LiteralPath "$out/dependency_sha256.json" -Raw | ConvertFrom-Json
foreach($header in Get-ChildItem -LiteralPath "$out/source" -Recurse -Filter posit_mac.vh) {
    if((Get-FileHash -LiteralPath $header.FullName).Hash.ToLowerInvariant() -ne $dependency.'rtl/posit_mac.vh') {throw 'Frozen header changed'}
}
foreach($entry in $manifest.sources.PSObject.Properties) {
    $path=Join-Path $root $entry.Name
    if($FrozenSources -and $entry.Name.StartsWith('rtl/common/')) {$path=Join-Path $out ('source/baseline/'+(Split-Path $entry.Name -Leaf))}
    if((Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() -ne $entry.Value) {throw 'Frozen source differs; use -FrozenSources only to replay the original snapshot'}
}
$requiredVariants=if($Phase -eq 'lod') {@('group4')} elseif($Phase -eq 'lod_mixed') {@('group4_mixed')} elseif($Phase -eq 'release') {@('selected')} elseif($Phase -eq 'adoption') {@('lod_only')} else {@('group4','reverse','radix4','native')}
if($Phase -in @('release','adoption')) {
    $release=Get-Content "$out/release_manifest.json" -Raw | ConvertFrom-Json
    foreach($entry in $release.sources.PSObject.Properties) {
        foreach($folder in @('rtl/candidates/primitives_v2/selected','results/primitive_v2_20261016/source/selected')) {
            if((Get-FileHash -LiteralPath "$root/$folder/$($entry.Name).sv").Hash.ToLowerInvariant() -ne $entry.Value) {throw 'Selective source changed'}
        }
    }
    if($Phase -eq 'adoption') {
        foreach($name in @('lod_lzd_core','dyn_left_shifter','dyn_right_shifter')) {
            $expected=if($name -eq 'lod_lzd_core') {$release.sources.$name} else {$manifest.sources."rtl/common/$name.sv"}
            if((Get-FileHash -LiteralPath "$out/source/lod_only/$name.sv").Hash.ToLowerInvariant() -ne $expected) {throw 'LOD-only snapshot differs'}
        }
    }
}
if(Test-Path "$out/mixed_manifest.json") {
    $extra=Get-Content "$out/mixed_manifest.json" -Raw | ConvertFrom-Json
    if((Get-FileHash -LiteralPath (Join-Path $root $extra.source)).Hash.ToLowerInvariant() -ne $extra.sha256) {throw 'Additional source changed'}
}
foreach($variant in $requiredVariants) {
    $v=Get-Content -LiteralPath "$out/verification/$variant/verification.json" -Raw | ConvertFrom-Json
    if($v.status -ne 'PASS' -or $v.mismatch -ne 0) {throw 'Unit verification incomplete'}
}
foreach($variant in @('baseline','group4','reverse','radix4','native','group4_mixed')) {
    foreach($name in @('lod_lzd_core','dyn_left_shifter','dyn_right_shifter')) {
        $source="rtl/common/$name.sv"
        if(($variant -eq 'group4' -and $name -eq 'lod_lzd_core') -or ($variant -in @('reverse','radix4','native') -and $name -ne 'lod_lzd_core')) {$source="rtl/candidates/primitives_v2/$variant/$name.sv"}
        $expected=if($variant -eq 'group4_mixed' -and $name -eq 'lod_lzd_core') {$extra.sha256} else {$manifest.sources.$source}
        if((Get-FileHash -LiteralPath "$out/source/$variant/$name.sv").Hash.ToLowerInvariant() -ne $expected) {throw 'Measured snapshot changed'}
    }
}
if(!(Test-Path "$out/lint/summary.txt")) {throw 'Strict lint incomplete'}
$run=[IO.Path]::GetFullPath((Join-Path $root "$RunRoot/$Part/$Phase"))
$resultsPrefix=[IO.Path]::GetFullPath((Join-Path $root 'results'))+[IO.Path]::DirectorySeparatorChar
if(!$run.StartsWith($resultsPrefix,[StringComparison]::OrdinalIgnoreCase)) {throw 'RunRoot outside results'}
if($PlanOnly) {
    @{part=$Part;phase=$Phase;run=$run;cases=@(Get-Content "$out/${Phase}_cases.tsv").Count;frozen_sources=[bool]$FrozenSources} | ConvertTo-Json
    return
}
foreach($name in @('tmp','appdata','localappdata')) {New-Item -ItemType Directory -Force "$run/$name" | Out-Null}
$driver=if($Phase -in @('confirm','release','adoption')) {'scripts/primitive_v2_confirm.tcl'} elseif($Phase -eq 'packer') {'scripts/primitive_v2_followup.tcl'} else {'scripts/primitive_v2_ppa.tcl'}
$inputs=@{}
foreach($name in @('tb/primitive_v2_boundary.sv','tb/primitive_v2_top.sv',$driver)) {
    $inputs[$name]=(Get-FileHash -LiteralPath (Join-Path $root $name)).Hash.ToLowerInvariant()
}
$inputs['cases']=(Get-FileHash -LiteralPath "$out/${Phase}_cases.tsv").Hash.ToLowerInvariant()
$lock=Join-Path $run 'input_sha256.json'
if(Test-Path -LiteralPath $lock) {
    $old=Get-Content -LiteralPath $lock -Raw | ConvertFrom-Json
    foreach($entry in $old.PSObject.Properties) {if($inputs[$entry.Name] -ne $entry.Value) {throw 'Measured inputs changed; do not resume this folder'}}
} else {$inputs | ConvertTo-Json | Set-Content -Encoding utf8 $lock}
$env:TEMP="$run/tmp";$env:TMP=$env:TEMP
$env:APPDATA="$run/appdata";$env:LOCALAPPDATA="$run/localappdata";$env:XILINX_LOCAL_USER_DATA='no'
Push-Location $run
try {
    & "$VivadoBin/vivado.bat" -mode batch -notrace -source (Join-Path $root $driver) -log vivado.log -journal vivado.jou -tclargs $Part $Phase > console.log
    if($LASTEXITCODE) {throw "Vivado failed $Part/$Phase"}
} finally {Pop-Location}
