param([string]$ModelSimBin='C:\altera\13.0sp1\modelsim_ase\win32aloem',[int]$Seed=20261004)
$ErrorActionPreference='Stop'
$projectPath=Split-Path $PSScriptRoot -Parent
$resultPath=Join-Path $projectPath 'results/modelsim_shifters'
New-Item -ItemType Directory -Force $resultPath | Out-Null
function Run-ModelSimTool([string]$Name,[string[]]$ToolArguments,[string]$LogName) {
    $toolOutput=& (Join-Path $ModelSimBin "$Name.exe") @ToolArguments 2>&1
    $code=$LASTEXITCODE
    $toolOutput | Set-Content -LiteralPath $LogName
    if($code -ne 0) {throw "$Name failed: exit=$code; see $LogName"}
}
Push-Location $resultPath
try {
    Run-ModelSimTool 'vsim' @('-version') 'version.log'
    if(!(Test-Path 'work')) {Run-ModelSimTool 'vlib' @('work') 'library.log'}
    Run-ModelSimTool 'vlog' @('-sv','-work','work','../../rtl/dyn_left_shifter.sv','../../rtl/dyn_right_shifter.sv',
        '../../tb/tb_dyn_left_shifter.sv','../../tb/tb_dyn_right_shifter.sv',
        '../../tb/tb_dyn_shifter_parameters.sv','-l','compile.log') 'compile_console.log'
    # Use a macro so onerror/onbreak apply to commands inside it.
    @('onerror {quit -code 1}','onbreak {quit -code 1}','run -all','quit -code 0') | Set-Content 'run.do'
    $results=@()
    foreach($item in @(@('left','tb_dyn_left_shifter'),@('right','tb_dyn_right_shifter'),@('parameters','tb_dyn_shifter_parameters'))) {
        $name=$item[0];$top=$item[1];$log="simulate_$name.log"
        Run-ModelSimTool 'vsim' @('-c',"work.$top","+SEED=$Seed",'-l',$log,'-do','run.do') "simulate_${name}_console.log"
        $text=Get-Content -Raw -LiteralPath $log
        $marker=if($name -eq 'parameters'){'PARAMETER_MATRIX PASS configurations=27'}else{'VECTORS PASSED 100% (0 MISMATCHES)!'}
        if(!$text.Contains($marker) -or $text -match '\*\*\s+(Error|Fatal):|PARAM FAIL|TEST RESULT: FAILED') {throw "$top did not pass; see $log"}
        $comparisons=if($name -eq 'parameters') {
            $sum=0L;foreach($match in [regex]::Matches($text,'PARAM PASS .*comparisons=(\d+)')) {$sum+=[long]$match.Groups[1].Value};$sum
        } else {[long][regex]::Match($text,'ALL (\d+) VECTORS PASSED').Groups[1].Value}
        $results+=[pscustomobject]@{top=$top;seed=$Seed;comparisons=$comparisons;status='PASS'}
    }
    $results | ConvertTo-Json | Set-Content 'summary.json'
    $sourceNames=@('rtl/dyn_left_shifter.sv','rtl/dyn_right_shifter.sv','tb/tb_dyn_left_shifter.sv',
        'tb/tb_dyn_right_shifter.sv','tb/tb_dyn_shifter_parameters.sv','scripts/verify_shifters_modelsim.ps1')
    $sourceNames | ForEach-Object {(Get-FileHash -LiteralPath (Join-Path $projectPath $_) -Algorithm SHA256).Hash.ToLowerInvariant()+'  '+$_} |
        Set-Content 'sources.sha256'
    Write-Output 'SHIFTERS MODELSIM PASS'
} finally {Pop-Location}
