param(
    [string]$VivadoBin = 'C:\AMDDesignTools\2026.1\Vivado\bin',
    [int]$Seed = 20261004,
    [string]$LicenseFile = ''
)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$resultPath = Join-Path $projectPath 'results/vivado_shifters'
New-Item -ItemType Directory -Force $resultPath | Out-Null
function Run-VivadoTool([string]$Name,[string[]]$ToolArguments,[string]$OutputName) {
    $toolPath = Join-Path $VivadoBin "$Name.bat"
    $output = & $toolPath @ToolArguments 2>&1
    $code = $LASTEXITCODE
    $output | Set-Content -LiteralPath (Join-Path $resultPath $OutputName)
    if($code -ne 0) {throw "$Name exit=$code; see $OutputName"}
}
$previousLicense = $env:XILINXD_LICENSE_FILE
if($LicenseFile) {
    if(!(Test-Path -LiteralPath $LicenseFile -PathType Leaf)) {throw 'LicenseFile does not exist.'}
    $env:XILINXD_LICENSE_FILE = (Resolve-Path -LiteralPath $LicenseFile).Path
}
Push-Location $resultPath
try {
    Run-VivadoTool 'xsim' @('-version') 'version.log'
    Run-VivadoTool 'xvlog' @('--sv','../../rtl/dyn_left_shifter.sv','../../rtl/dyn_right_shifter.sv',
        '../../tb/tb_dyn_left_shifter.sv','../../tb/tb_dyn_right_shifter.sv',
        '../../tb/tb_dyn_shifter_parameters.sv','-log','compile.log') 'compile_console.log'
    $results = @()
    foreach($item in @(@('left','tb_dyn_left_shifter'),@('right','tb_dyn_right_shifter'),@('parameters','tb_dyn_shifter_parameters'))) {
        $name = $item[0];$top = $item[1];$snapshot = "${name}_snapshot"
        Run-VivadoTool 'xelab' @("work.$top",'-s',$snapshot,'-debug','typical','-log',"elaborate_$name.log") "elaborate_${name}_console.log"
        # Argument file preserves '=' across the Windows batch wrapper.
        @('-runall', '-testplusarg', "SEED=$Seed", '-log', "simulate_$name.log") |
            Set-Content -LiteralPath "${name}_options.txt"
        Run-VivadoTool 'xsim' @($snapshot,'-f',"${name}_options.txt") "simulate_${name}_console.log"
        $simulation = Get-Content -Raw -LiteralPath "simulate_${name}_console.log"
        $marker = if($name -eq 'parameters') {'PARAMETER_MATRIX PASS configurations=27'} else {'VECTORS PASSED 100% (0 MISMATCHES)!'}
        $passed = $simulation.Contains($marker) -and $simulation -notmatch '(?im)^\s*(ERROR:|Fatal:|Error:)|Could not obtain.*license'
        $status = if($passed){'PASS'}elseif($simulation -match 'Could not obtain.*license'){'BLOCKED_LICENSE'}else{'FAIL_OR_NOT_RUN'}
        $results += [pscustomobject]@{top=$top;seed=$Seed;compile='PASS';elaborate='PASS';status=$status}
    }
    $results | ConvertTo-Json | Set-Content -LiteralPath 'summary.json'
    if(@($results | Where-Object {$_.status -ne 'PASS'}).Count) {throw 'Vivado simulation did not pass; see summary.json and simulate logs.'}
    Write-Output 'SHIFTERS VIVADO PASS'
} finally {Pop-Location;$env:XILINXD_LICENSE_FILE=$previousLicense}
