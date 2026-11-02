param(
    [ValidateSet('Verify','SynthNF','SynthF')][string]$Stage='Verify',
    [string]$RunRoot='results/refactored_mac_20261101',
    [ValidatePattern('^[A-Za-z0-9_]*$')][string]$SynthSuffix='',
    [ValidateRange(1000,1000000)][int]$VectorCount=5000,
    [string]$SourceRoot='',
    [ValidateSet('All','F')][string]$VerifyScope='All',
    [string]$ModelSimBin=$env:MODELSIM_BIN,
    [string]$PythonExecutable='python',
    [string]$VivadoExecutable='vivado'
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$inputRoot=if($SourceRoot){(Resolve-Path -LiteralPath $SourceRoot).Path}else{$root}
$run=Join-Path $root $RunRoot
if(!$ModelSimBin) {
    $simCommand=Get-Command vsim -ErrorAction SilentlyContinue
    if(!$simCommand){throw 'Set MODELSIM_BIN or pass -ModelSimBin; installation is not modified'}
    $ModelSimBin=Split-Path -Parent $simCommand.Source
}
$bin=(Resolve-Path -LiteralPath $ModelSimBin).Path
function Get-VerificationReferences([string]$tree) {
    foreach($relative in @('adder/posit_add_comb.sv','adder/posit_add_align.sv','adder/posit_add_arith.sv','adder/posit_add_normalize.sv',
            'common/dyn_right_shifter.sv','common/lod_lzd_core.sv','common/dyn_left_shifter_fixed2.sv','packer/ref_posit_pack_comb.sv')) {
        $current="tb/reference/rtl/$relative"
        $legacy="rtl/$relative"
        if(Test-Path -LiteralPath "$tree/$current"){$current}
        elseif(Test-Path -LiteralPath "$tree/$legacy"){$legacy}
        else {throw "Missing verification reference: $relative"}
    }
}
if($Stage -eq 'Verify') {
    if(Test-Path -LiteralPath $run){throw 'Choose a fresh RunRoot; preserve existing results'}
    New-Item -ItemType Directory -Force "$run/source","$run/tmp","$run/verify" | Out-Null
    $paths=@(Get-Content "$inputRoot/rtl/mac_active.f")+@(
        'rtl/mac_active.f','rtl/posit_mac.vh',
        'tb/tb_posit_add_5stage_equiv.sv','tb/tb_refactored_mac.sv','tb/tb_posit_pack_equiv.sv','tb/tb_mul_iter_core.sv',
        'tb/prepack_nf_ppa_top.sv','tb/week13_fused_ppa_top.sv',
        'scripts/gen_refactored_mac_vectors.py','scripts/run_refactored_mac.ps1',
        'syn/refactored_mac_synth.tcl','syn/constraints/a35t_clock.xdc','syn/constraints/a35t_benchmark_100mhz.xdc')
    $paths+=@(Get-VerificationReferences $inputRoot)
    if(Test-Path "$inputRoot/tb/tb_parser_f_timing_equiv.sv"){$paths+='tb/tb_parser_f_timing_equiv.sv'}
    $hashes=@{}
    foreach($p in ($paths|Sort-Object -Unique)) {
        if(!$p.Trim()){continue}
        $dst=Join-Path "$run/source" $p
        New-Item -ItemType Directory -Force (Split-Path $dst -Parent)|Out-Null
        Copy-Item -LiteralPath "$inputRoot/$p" -Destination $dst
        $hashes[$p]=(Get-FileHash -LiteralPath $dst).Hash
    }
    @{part='xc7a35tcpg236-1';period_ns=10;vector_count=$VectorCount;verify_scope=$VerifyScope;input_root=$inputRoot;scope='Shared approximate12 FULL_TERM26/Q24 core; OPS0/1,n0..12; no cfg_mode. Functional replay, not final52-point acceptance.';sha256=$hashes}|ConvertTo-Json -Depth 4|Set-Content -Encoding utf8 "$run/manifest.json"
}
if(!(Test-Path "$run/manifest.json")){throw 'Run Verify to snapshot sources first'}
$manifest=Get-Content "$run/manifest.json" -Raw|ConvertFrom-Json
foreach($entry in $manifest.sha256.PSObject.Properties) {
    if((Get-FileHash -LiteralPath "$run/source/$($entry.Name)").Hash -ne $entry.Value){throw "Snapshot hash mismatch: $($entry.Name)"}
}
$env:TEMP="$run/tmp";$env:TMP=$env:TEMP
if($Stage -eq 'Verify') {
    $py=(Get-Command $PythonExecutable -ErrorAction Stop).Source
    & $py "$run/source/scripts/gen_refactored_mac_vectors.py" "$run/vectors" --count $VectorCount
    if($LASTEXITCODE){throw 'Vector generation failed'}
    Push-Location "$run/verify"
    try {
        & "$bin/vlib.exe" work > library.log
        if($LASTEXITCODE){throw 'vlib failed'}
        $sources=@(Get-Content "$run/source/rtl/mac_active.f"|ForEach-Object {"$run/source/$_"})
        $sources+=@(Get-VerificationReferences "$run/source" | ForEach-Object {"$run/source/$_"})
        $sources+="$run/source/tb/tb_posit_add_5stage_equiv.sv"
        $sources+="$run/source/tb/tb_refactored_mac.sv"
        $sources+="$run/source/tb/tb_posit_pack_equiv.sv"
        $sources+="$run/source/tb/tb_mul_iter_core.sv"
        & "$bin/vlog.exe" -sv -timescale 1ns/1ps "+incdir+$run/source/rtl" -work work @sources -l compile.log > compile_console.log
        if($LASTEXITCODE){throw 'Compile failed; inspect compile.log'}
        @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0')|Set-Content -Encoding ascii run.do
        $labels=if($VerifyScope -eq 'F'){@('adder','packer','core','f')}else{@('adder','packer','core','nf','f')}
        foreach($label in $labels) {
            $simArgs=@('-c')
            if($label -eq 'adder'){$simArgs+='work.tb_posit_add_5stage_equiv';$marker='ADDER_REFACTOR_PASS'}
            elseif($label -eq 'packer') {$simArgs+='work.tb_posit_pack_equiv';$marker='PACKER_REFACTOR_PASS'}
            elseif($label -eq 'core') {$simArgs+='work.tb_mul_iter_core';$marker='SHARED_CORE_PASS'}
            else {$simArgs+='work.tb_refactored_mac';$simArgs+="-gFUSED=$(if($label -eq 'f'){1}else{0})";$simArgs+="+VECTORS=$run/vectors/$label.txt";$marker='MAC_REFACTOR_PASS'}
            $simArgs+=@('-do','run.do','-l',"$label.log",'-wlf',"$label.wlf")
            & "$bin/vsim.exe" @simArgs > "${label}_console.log"
            if($LASTEXITCODE){throw "$label simulation failed"}
            $body=Get-Content "$label.log" -Raw
            if($body -notmatch $marker -or $body -match '\*\*\s+(Error|Fatal):'){throw "$label acceptance failed"}
            $body -split "`n"|Where-Object {$_ -match $marker}
        }
        'PASS'|Set-Content status.txt
    } finally {Pop-Location}
} else {
    if((Get-Content "$run/verify/status.txt" -Raw).Trim() -ne 'PASS'){throw 'Verification must pass before synthesis'}
    $variant=if($Stage -eq 'SynthNF'){'nf'}else{'f'}
    if($variant -eq 'nf' -and $manifest.verify_scope -eq 'F'){throw 'NF was not verified in this run'}
    $target="$run/synth_${variant}$SynthSuffix"
    if(Test-Path $target){throw 'Preserve existing synthesis'}
    New-Item -ItemType Directory -Force $target|Out-Null
    foreach($name in @('appdata','localappdata','tmp')) {New-Item -ItemType Directory -Force "$target/$name"|Out-Null}
    $env:APPDATA="$target/appdata";$env:LOCALAPPDATA="$target/localappdata"
    $env:TEMP="$target/tmp";$env:TMP=$env:TEMP;$env:XILINX_LOCAL_USER_DATA='no'
    $env:REFACTORED_SOURCE_ROOT="$run/source"
    Copy-Item -LiteralPath "$root/syn/refactored_mac_synth.tcl" -Destination "$target/run_synth.tcl"
    @{runner_sha256=(Get-FileHash $PSCommandPath).Hash;tcl_sha256=(Get-FileHash "$target/run_synth.tcl").Hash;verified_manifest_sha256=(Get-FileHash "$run/manifest.json").Hash;variant=$variant;stage='synthesis only'}|ConvertTo-Json|Set-Content "$target/execution.json"
    Push-Location $target
    try {
        & $VivadoExecutable -mode batch -notrace -source "$target/run_synth.tcl" -log vivado.log -journal vivado.jou -tclargs $variant > console.log
        if($LASTEXITCODE){throw 'Vivado synthesis failed'}
        if((Get-Content status.txt -Raw).Trim() -ne 'SYNTHESIS_COMPLETE'){throw 'Missing synthesis completion'}
        "SYNTHESIS_COMPLETE $variant"
    } finally {Pop-Location}
}
