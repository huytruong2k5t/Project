param(
    [ValidatePattern('^results/[a-zA-Z0-9_/-]+$')][string]$RunRoot='results/opt120_20261018/event_sentinel',
    [ValidateSet('adjacent','sentinel','negate')][string]$Variant='sentinel',
    [switch]$AllFormats
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$study="$root/results/opt120_20261018"
if(Test-Path "$root/rtl/production_freeze.json") {
    $frozen=Get-Content "$root/rtl/production_freeze.json" -Raw | ConvertFrom-Json
    if($frozen.status -ne 'LOCKED_FOR_W14') {throw 'Release is not locked'}
    foreach($group in @('rtl_sha256','model_sha256','build_contract_sha256')) {
        foreach($entry in $frozen.$group.PSObject.Properties) {
            if((Get-FileHash (Join-Path $root $entry.Name)).Hash.ToLowerInvariant() -ne $entry.Value) {
                throw "Frozen input changed: $($entry.Name)"
            }
        }
    }
}
if($RunRoot.Contains('..')) {throw 'Invalid output path'}
$run=Join-Path $root $RunRoot
if(Test-Path $run) {throw 'Preserve existing evidence'}
foreach($name in @('source/rtl','source/tb','compat','tmp')) {New-Item -ItemType Directory -Force "$run/$name" | Out-Null}
$env:TEMP="$run/tmp"; $env:TMP=$env:TEMP
$bin='C:/altera/13.0sp1/modelsim_ase/win32aloem'
$hashes=@{}; $sources=@()
foreach($path in (Get-Content "$root/rtl/production.f")) {
    $dst=Join-Path "$run/source" $path
    New-Item -ItemType Directory -Force (Split-Path $dst -Parent) | Out-Null
    Copy-Item -LiteralPath "$study/source/$Variant/$path" -Destination $dst
    $hashes[$path]=(Get-FileHash $dst).Hash.ToLowerInvariant()
    if((Split-Path $path -Leaf) -eq 'lod_lzd_core.sv') {
        $text=Get-Content $dst -Raw
        $text=$text.Replace("POS_W'(group_index)","pos_cast_t'(group_index)").Replace("S'(pos_tree[LEVELS][0])","count_cast_t'(pos_tree[LEVELS][0])")
        $text=$text.Replace('            assign match_bits',"            typedef logic [POS_W-1:0] pos_cast_t;`n            typedef logic [S-1:0] count_cast_t;`n            assign match_bits")
        $dst="$run/compat/lod_lzd_core.sv"
        [IO.File]::WriteAllText($dst,$text)
    } elseif((Split-Path $path -Leaf) -eq 'mac_f_wrapper.sv') {
        $text=Get-Content $dst -Raw
        $text=$text.Replace('    localparam int I_W = $clog2(FRAC_W+1);','    localparam int I_W = $clog2(FRAC_W+1); typedef logic [I_W-1:0] iteration_cast_t;')
        $text=$text.Replace("I_W'(N_MAX)","iteration_cast_t'(N_MAX)")
        $dst="$run/compat/mac_f_wrapper.sv"
        [IO.File]::WriteAllText($dst,$text)
    }
    $sources+=$dst
}
Copy-Item "$study/source/$Variant/rtl/posit_mac.vh" "$run/source/rtl"
$hashes['rtl/posit_mac.vh']=(Get-FileHash "$run/source/rtl/posit_mac.vh").Hash.ToLowerInvariant()
$hashes | ConvertTo-Json | Set-Content -Encoding utf8 "$run/source_sha256.json"
foreach($name in @('tb_week11_mac.sv','tb_week13_fused_event.sv')) {
    Copy-Item "$root/tb/$name" "$run/source/tb"
    $tbText=Get-Content "$run/source/tb/$name" -Raw
    $tbText=$tbText.Replace('always #5 clk = ~clk;','always #4 clk = ~clk;')
    [IO.File]::WriteAllText("$run/source/tb/$name",$tbText)
    $sources+="$run/source/tb/$name"
}
$fixtures="$root/results/opt02b_20261017/fixtures"
$protocol="$root/results/opt02b_20261017/protocol_fixtures"
$vectors="$study/fused/$Variant/pilot.vectors"
if(!(Test-Path $vectors)) {throw 'Regenerate bound F smoke vectors before event replay'}
$fixtureHashes=@{}
$boundFixtures=@($vectors)
foreach($format in @(@(8,0),@(16,1),@(32,2),@(32,3))) {
    $boundFixtures+="$fixtures/mac_$($format[0])_$($format[1]).txt"
    $boundFixtures+="$protocol/mac_$($format[0])_$($format[1]).txt"
}
foreach($p in $boundFixtures) {
    $fixtureHashes[$p.Substring($root.Length+1)]=(Get-FileHash $p).Hash.ToLowerInvariant()
}
$fixtureHashes | ConvertTo-Json | Set-Content -Encoding utf8 "$run/fixture_sha256.json"
'event_clock_ns=8.000 CK2Q_ns=1.000; RTL simulation only, not SDF timing proof' | Set-Content "$run/event_scope.txt"
Push-Location $run
try {
    & "$bin/vsim.exe" -version > version.log
    & "$bin/vlib.exe" work > library.log
    if($LASTEXITCODE) {throw 'vlib failed'}
    & "$bin/vlog.exe" -sv -timescale 1ns/1ps "+incdir+$run/source/rtl" -work work @sources -l compile.log > compile_console.log
    if($LASTEXITCODE) {throw 'vlog failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    $formats=,@(32,3)
    if($AllFormats) {$formats=@(@(8,0),@(16,1),@(32,2),@(32,3))}
    foreach($format in $formats) {
        $nb=$format[0]; $es=$format[1]
        foreach($kind in @('corner','protocol')) {
            $fixtureDir=if($kind -eq 'corner') {$fixtures} else {$protocol}
            $log="${kind}_${nb}_${es}.log"
            & "$bin/vsim.exe" -c work.tb_week11_mac "-gNB=$nb" "-gES=$es" "+VECTOR_DIR=$fixtureDir" -do run.do -l $log -wlf "${kind}_${nb}_${es}.wlf" > "${kind}_${nb}_${es}_console.log"
            if($LASTEXITCODE) {throw 'NF event failed'}
            $text=Get-Content $log -Raw
            if($text -notmatch 'W11 MODELSIM PASS' -or $text -match '\*\*\s+(Error|Fatal):') {throw 'NF acceptance missing'}
            Write-Output ($text -split "`n" | Where-Object {$_ -match 'W11 MODELSIM PASS'})
        }
    }
    & "$bin/vsim.exe" -c work.tb_week13_fused_event "+VECTORS=$vectors" -do run.do -l fused.log -wlf fused.wlf > fused_console.log
    if($LASTEXITCODE) {throw 'F event failed'}
    $text=Get-Content fused.log -Raw
    if($text -notmatch 'W13_EVENT_PASS' -or $text -match '\*\*\s+(Error|Fatal):') {throw 'F acceptance missing'}
    Write-Output ($text -split "`n" | Where-Object {$_ -match 'W13_EVENT_PASS'})
    'COMPLETE' | Set-Content status.txt
} finally {Pop-Location}
