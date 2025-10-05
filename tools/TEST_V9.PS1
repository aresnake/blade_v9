<# 
  Test_V9.ps1 — lance le smoke test en background
  Usage:
    .\Test_V9.ps1
#>

param(
  [string]$BlenderExe = "C:\Program Files\Blender Foundation\Blender 4.5\blender.exe"
)

$ErrorActionPreference = "Stop"

$project = "D:\V9"
$test    = Join-Path $project "blade_v9\tests\smoke_forest.py"

if (-not (Test-Path $test)) { Write-Error "Test file not found: $test"; exit 2 }

# Assure install à jour
& (Join-Path $project "tools\Make_V9.ps1") -Verbose

# Exécute Blender en background avec l'addon
& $BlenderExe -b --addons blade_v9 --python $test
if ($LASTEXITCODE -ne 0) {
  Write-Error "Smoke test FAILED with exit code $LASTEXITCODE"
  exit $LASTEXITCODE
} else {
  Write-Host "Smoke test PASSED" -ForegroundColor Green
  exit 0
}
