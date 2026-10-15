$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$oracle=Join-Path $project 'results/week12/oracle'
$window=Join-Path $project 'results/week12/window'
$env:TEMP=Join-Path $window 'tmp'
$env:TMP=$env:TEMP
Push-Location $project
try {
    & "$oracle/bin/oracle.exe" "$oracle/windows.json" 100000 100000 | Set-Content "$oracle/windows.log"
    if($LASTEXITCODE) {throw 'Windows oracle failed'}
    & "$window/bin/generator.exe" "$window/fixtures/windows.bin" 1000000 | Set-Content "$window/windows_generator.log"
    if($LASTEXITCODE) {throw 'Windows generator failed'}
    $original=(Get-FileHash -LiteralPath "$window/fixtures/main.bin" -Algorithm SHA256).Hash
    $replay=(Get-FileHash -LiteralPath "$window/fixtures/windows.bin" -Algorithm SHA256).Hash
    if($original -ne $replay) {throw 'Windows/Linux corpus differs'}
    & "$window/bin/window.exe" "$window/fixtures/windows.bin" 1000000 32 "$window/windows" | Set-Content "$window/windows.log"
    if($LASTEXITCODE) {throw 'Windows window acceptance failed'}
    Set-Content -Encoding ascii "$oracle/status.txt" COMPLETE
    Set-Content -Encoding ascii "$window/status.txt" COMPLETE
    Write-Output "W12 WINDOWS PASS corpus_sha256=$($original.ToLowerInvariant())"
} finally {Pop-Location}
