param([string[]]$Variants=@('group4','reverse','radix4','native'),
      [string]$VivadoBin='C:/AMDDesignTools/2026.1/Vivado/bin',
      [string]$Python='C:/Users/This PC/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe',
      [switch]$FrozenSources,
      [ValidatePattern('^results/[a-zA-Z0-9_/-]+$')][string]$RunRoot='results/primitive_v2_20261016')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root 'results/primitive_v2_20261016'
& $Python (Join-Path $PSScriptRoot 'prepare_primitive_v2_checks.py')
if($LASTEXITCODE) {throw 'Check preparation failed'}
$manifest=Get-Content -LiteralPath (Join-Path $out 'manifest.json') -Raw | ConvertFrom-Json
foreach($entry in $manifest.sources.PSObject.Properties) {
    $path=Join-Path $root $entry.Name
    if($FrozenSources -and $entry.Name.StartsWith('rtl/common/')) {$path=Join-Path $out ('source/baseline/'+(Split-Path $entry.Name -Leaf))}
    if((Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() -ne $entry.Value) {throw 'Source changed; -FrozenSources replays the original snapshot'}
}
foreach($variant in $Variants) {
    if($variant -notin @('group4','reverse','radix4','native','group4_mixed','selected','lod_only')) {throw 'Unknown variant'}
    $run=[IO.Path]::GetFullPath((Join-Path $root "$RunRoot/verification/$variant"))
    $resultsPrefix=[IO.Path]::GetFullPath((Join-Path $root 'results'))+[IO.Path]::DirectorySeparatorChar
    if(!$run.StartsWith($resultsPrefix,[StringComparison]::OrdinalIgnoreCase)) {throw 'RunRoot outside results'}
    foreach($name in @('tmp','appdata','localappdata')) {New-Item -ItemType Directory -Force (Join-Path $run $name) | Out-Null}
    $env:TEMP=Join-Path $run 'tmp';$env:TMP=$env:TEMP
    $env:APPDATA=Join-Path $run 'appdata';$env:LOCALAPPDATA=Join-Path $run 'localappdata'
    $env:XILINX_LOCAL_USER_DATA='no'
    Push-Location $run
    try {
        $files=@('../../reference/lod_lzd_core_reference.sv','../../reference/dyn_left_shifter_reference.sv','../../reference/dyn_right_shifter_reference.sv',
            "../../source/$variant/lod_lzd_core.sv","../../source/$variant/dyn_left_shifter.sv","../../source/$variant/dyn_right_shifter.sv",
            '../../checks/primitive_shift_check.sv','../../checks/primitive_lod_check.sv','../../checks/tb_primitive_v2.sv')
        if($RunRoot -ne 'results/primitive_v2_20261016') {
            $files=@($files | ForEach-Object { [IO.Path]::GetFullPath((Join-Path "$out/verification/$variant" $_)) })
        }
        & "$VivadoBin/xvlog.bat" --sv @files -log compile.log > compile_console.log
        if($LASTEXITCODE) {throw "Compile failed $variant"}
        & "$VivadoBin/xelab.bat" tb_primitive_v2 -s checked -log elaborate.log > elaborate_console.log
        if($LASTEXITCODE) {throw "Elaboration failed $variant"}
        @('-runall','-log','simulate.log') | Set-Content -Encoding ascii xsim.options
        & "$VivadoBin/xsim.bat" checked -f xsim.options > simulate_console.log
        if($LASTEXITCODE) {throw "Simulation failed $variant"}
        $log=Get-Content -LiteralPath simulate.log -Raw
        if($log -notmatch 'PRIMITIVE_V2_ALL_PASS' -or $log -match 'Fatal:|_FAIL|ERROR:|Could not obtain') {throw "Verification failed $variant"}
        $matches=[regex]::Matches($log,'(?:SHIFT|LOD)_PASS[^\r\n]*checks=(\d+)')
        $count=0L;foreach($m in $matches){$count += [long]$m.Groups[1].Value}
        if($matches.Count -ne 138 -or $count -lt 3082416) {throw 'Incomplete independent-oracle matrix'}
        @{status='PASS';variant=$variant;seed=20261016;configurations=$matches.Count;checks=$count;mismatch=0;
            tool='Vivado XSim 2026.1';scope='Binary exhaustive small widths, all shift encodings, directed/random large widths; no X/Z equivalence claim'} |
            ConvertTo-Json | Set-Content -Encoding utf8 verification.json
        Write-Output "V2_VERIFY_PASS variant=$variant configs=$($matches.Count) checks=$count mismatch=0"
    } finally {Pop-Location}
}
