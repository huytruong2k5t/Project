param(
    [ValidateSet('Verify','SynthNF','SynthF')][string]$Stage='Verify',
    [string]$RunRoot='results/refactored_mac_20261101',
    [ValidatePattern('^[A-Za-z0-9_]*$')][string]$SynthSuffix='',
    [ValidateRange(1000,1000000)][int]$VectorCount=5000
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$run=Join-Path $root $RunRoot
$bin='C:/altera/13.0sp1/modelsim_ase/win32aloem'
if($Stage -eq 'Verify') {
    if(Test-Path -LiteralPath $run){throw 'Choose a fresh RunRoot; preserve existing results'}
    New-Item -ItemType Directory -Force "$run/source","$run/tmp","$run/verify" | Out-Null
    $paths=@(Get-Content "$root/rtl/mac_active.f")+@(
        'rtl/mac_active.f','rtl/posit_mac.vh',
        'rtl/adder/posit_add_comb.sv','rtl/adder/posit_add_align.sv','rtl/adder/posit_add_arith.sv','rtl/adder/posit_add_normalize.sv',
        'rtl/common/dyn_right_shifter.sv','rtl/common/lod_lzd_core.sv','rtl/common/dyn_left_shifter_fixed2.sv',
        'tb/tb_posit_add_5stage_equiv.sv','tb/tb_refactored_mac.sv','tb/tb_posit_pack_equiv.sv',
        'tb/prepack_nf_ppa_top.sv','tb/week13_fused_ppa_top.sv',
        'scripts/gen_refactored_mac_vectors.py','scripts/run_refactored_mac.ps1',
        'syn/refactored_mac_synth.tcl','syn/constraints/a35t_clock.xdc','syn/constraints/a35t_benchmark_100mhz.xdc')
    $hashes=@{}
    foreach($p in ($paths|Sort-Object -Unique)) {
        if(!$p.Trim()){continue}
        $dst=Join-Path "$run/source" $p
        New-Item -ItemType Directory -Force (Split-Path $dst -Parent)|Out-Null
        Copy-Item -LiteralPath "$root/$p" -Destination $dst
        $hashes[$p]=(Get-FileHash -LiteralPath $dst).Hash
    }
    @{part='xc7a35tcpg236-1';period_ns=10;vector_count=$VectorCount;scope='Current RTL FLOOR; NF N_MAX8/exact-capable bank54; F N_MAX12 bank16; cfg_mode=1 in replay. Not FULL_TERM acceptance.';sha256=$hashes}|ConvertTo-Json -Depth 4|Set-Content -Encoding utf8 "$run/manifest.json"
}
if(!(Test-Path "$run/manifest.json")){throw 'Run Verify to snapshot sources first'}
$manifest=Get-Content "$run/manifest.json" -Raw|ConvertFrom-Json
foreach($entry in $manifest.sha256.PSObject.Properties) {
    if((Get-FileHash -LiteralPath "$run/source/$($entry.Name)").Hash -ne $entry.Value){throw "Snapshot hash mismatch: $($entry.Name)"}
}
$env:TEMP="$run/tmp";$env:TMP=$env:TEMP
if($Stage -eq 'Verify') {
    $py='C:/Users/This PC/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
    & $py "$run/source/scripts/gen_refactored_mac_vectors.py" "$run/vectors" --count $VectorCount
    if($LASTEXITCODE){throw 'Vector generation failed'}
    Push-Location "$run/verify"
    try {
        & "$bin/vlib.exe" work > library.log
        if($LASTEXITCODE){throw 'vlib failed'}
        $sources=@(Get-Content "$run/source/rtl/mac_active.f"|ForEach-Object {"$run/source/$_"})
        foreach($p in @('posit_add_comb','posit_add_align','posit_add_arith','posit_add_normalize')){$sources+="$run/source/rtl/adder/$p.sv"}
        foreach($p in @('dyn_right_shifter','lod_lzd_core','dyn_left_shifter_fixed2')){$sources+="$run/source/rtl/common/$p.sv"}
        $sources+="$run/source/tb/tb_posit_add_5stage_equiv.sv"
        $sources+="$run/source/tb/tb_refactored_mac.sv"
        $sources+="$run/source/tb/tb_posit_pack_equiv.sv"
        & "$bin/vlog.exe" -sv -timescale 1ns/1ps "+incdir+$run/source/rtl" -work work @sources -l compile.log > compile_console.log
        if($LASTEXITCODE){throw 'Compile failed; inspect compile.log'}
        @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0')|Set-Content -Encoding ascii run.do
        foreach($label in @('adder','packer','nf','f')) {
            $simArgs=@('-c')
            if($label -eq 'adder'){$simArgs+='work.tb_posit_add_5stage_equiv';$marker='ADDER_REFACTOR_PASS'}
            elseif($label -eq 'packer') {$simArgs+='work.tb_posit_pack_equiv';$marker='PACKER_REFACTOR_PASS'}
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
        & 'C:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -notrace -source "$target/run_synth.tcl" -log vivado.log -journal vivado.jou -tclargs $variant > console.log
        if($LASTEXITCODE){throw 'Vivado synthesis failed'}
        if((Get-Content status.txt -Raw).Trim() -ne 'SYNTHESIS_COMPLETE'){throw 'Missing synthesis completion'}
        "SYNTHESIS_COMPLETE $variant"
    } finally {Pop-Location}
}
