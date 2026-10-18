$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$run=Join-Path $root results/week14/event_protocol
if(Test-Path $run) {throw 'Preserve existing event evidence'}
foreach($name in @('source/rtl','source/tb','compat','tmp')) {New-Item -ItemType Directory -Force "$run/$name" | Out-Null}
$env:TEMP="$run/tmp";$env:TMP=$env:TEMP
$bin='C:/altera/13.0sp1/modelsim_ase/win32aloem'
$lock=Get-Content "$root/rtl/production_freeze.json" -Raw | ConvertFrom-Json
$sources=@();$hashes=@{}
foreach($path in $lock.production_files) {
    $dest=Join-Path "$run/source" $path
    New-Item -ItemType Directory -Force (Split-Path $dest -Parent) | Out-Null
    Copy-Item -LiteralPath "$root/$path" -Destination $dest
    $digest=(Get-FileHash $dest).Hash.ToLowerInvariant()
    if($digest -ne $lock.rtl_sha256.$path) {throw "Locked source changed: $path"}
    $hashes[$path]=$digest
    if((Split-Path $path -Leaf) -eq 'lod_lzd_core.sv') {
        $text=Get-Content $dest -Raw
        $text=$text.Replace("POS_W'(group_index)","pos_cast_t'(group_index)").Replace("S'(pos_tree[LEVELS][0])","count_cast_t'(pos_tree[LEVELS][0])")
        $text=$text.Replace('            assign match_bits',"            typedef logic [POS_W-1:0] pos_cast_t;`n            typedef logic [S-1:0] count_cast_t;`n            assign match_bits")
        $dest="$run/compat/lod_lzd_core.sv";[IO.File]::WriteAllText($dest,$text)
    } elseif((Split-Path $path -Leaf) -eq 'mac_f_wrapper.sv') {
        $text=Get-Content $dest -Raw
        $text=$text.Replace('    localparam int I_W = $clog2(FRAC_W+1);','    localparam int I_W = $clog2(FRAC_W+1); typedef logic [I_W-1:0] iteration_cast_t;')
        $text=$text.Replace("I_W'(N_MAX)","iteration_cast_t'(N_MAX)")
        $dest="$run/compat/mac_f_wrapper.sv";[IO.File]::WriteAllText($dest,$text)
    }
    $sources+=$dest
}
Copy-Item "$root/rtl/posit_mac.vh" "$run/source/rtl"
Copy-Item "$root/tb/tb_week14_protocol.sv" "$run/source/tb"
$sources+="$run/source/tb/tb_week14_protocol.sv"
Copy-Item "$root/results/week14/golden_check/protocol_expected.hex" "$run/source/tb"
$hashes['rtl/posit_mac.vh']=(Get-FileHash "$run/source/rtl/posit_mac.vh").Hash.ToLowerInvariant()
@{release_id=$lock.release_id;source_sha256=$hashes;scope='New post-freeze companion, no main inputs changed; local typed-cast compatibility only';tb_sha256=(Get-FileHash "$run/source/tb/tb_week14_protocol.sv").Hash.ToLowerInvariant();vectors_sha256=(Get-FileHash "$run/source/tb/protocol_expected.hex").Hash.ToLowerInvariant()} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$run/manifest.json"
Push-Location $run
try {
    & "$bin/vsim.exe" -version > version.log
    & "$bin/vlib.exe" work > library.log
    & "$bin/vlog.exe" -sv -timescale 1ns/1ps "+incdir+$run/source/rtl" -work work @sources -l compile.log > compile_console.log
    if($LASTEXITCODE) {throw 'Compile failed'}
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content -Encoding ascii run.do
    foreach($nf in @(0,1)) {
        & "$bin/vsim.exe" -c work.tb_week14_protocol "-gNF_EX0=$nf" "+VECTORS=$run/source/tb/protocol_expected.hex" -do run.do -l "mode$nf.log" -wlf "mode$nf.wlf" > "mode${nf}_console.log"
        if($LASTEXITCODE) {throw 'Protocol simulation failed'}
        $log=Get-Content "mode$nf.log" -Raw
        if($log -notmatch 'W14_PROTOCOL_PASS' -or $log -match '\*\*\s+(Error|Fatal):') {throw 'Protocol check failed'}
        Write-Output ($log -split "`n" | Where-Object {$_ -match 'W14_PROTOCOL_PASS'})
    }
    'COMPLETE' | Set-Content status.txt
} finally {Pop-Location}
