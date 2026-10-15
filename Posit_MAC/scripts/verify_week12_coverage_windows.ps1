$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$run=Join-Path $project 'results/week12/coverage'
$env:TEMP=Join-Path $run 'tmp'
$env:TMP=$env:TEMP
Push-Location $project
try {
    & "$run/bin/coverage.exe" generate "$run/fixtures/windows.bin" | Set-Content "$run/windows_generator.log"
    if($LASTEXITCODE) {throw 'Windows coverage generator failed'}
    $linux=(Get-FileHash -LiteralPath "$run/fixtures/main.bin" -Algorithm SHA256).Hash
    $windows=(Get-FileHash -LiteralPath "$run/fixtures/windows.bin" -Algorithm SHA256).Hash
    if($linux -ne $windows) {throw 'Cross-platform coverage corpus mismatch'}
    & "$run/bin/coverage.exe" monitor "$run/fixtures/windows.bin" "$run/windows.json" | Set-Content "$run/windows.log"
    if($LASTEXITCODE) {throw 'Windows coverage monitor failed'}
    Set-Content -Encoding ascii "$run/status.txt" COMPLETE
    Write-Output "W12 COVERAGE WINDOWS PASS corpus_sha256=$($linux.ToLowerInvariant())"
} finally {Pop-Location}
