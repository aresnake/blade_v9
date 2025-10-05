<# 
  Enable_Blade_V9.ps1 — active l'addon 'blade_v9' dans les préférences Blender.
  Usage:
    .\Enable_Blade_V9.ps1
#>

param(
  [string]$BlenderExe = "C:\Program Files\Blender Foundation\Blender 4.5\blender.exe"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BlenderExe)) {
  Write-Error "Blender executable not found: $BlenderExe"
  exit 2
}

& $BlenderExe -con --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blade_v9'); bpy.ops.wm.save_userpref(); print('Blade v9 enabled');"
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to enable blade_v9 (exit $LASTEXITCODE)"
  exit $LASTEXITCODE
}
Write-Host "Blade v9 enabled in user preferences." -ForegroundColor Green
exit 0
