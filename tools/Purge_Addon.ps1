# --- Purge_Addon.ps1 ---
$BLENDER_VER = "4.5"
$USER_ADDONS = Join-Path $env:APPDATA "Blender Foundation\Blender\$BLENDER_VER\scripts\addons"
$ADDON_NAME = "blade_v9"
$DST = Join-Path $USER_ADDONS $ADDON_NAME

if (Test-Path $DST) {
  Write-Host ">> Purge: $DST"
  attrib -r -h -s $DST -Recurse -ErrorAction SilentlyContinue | Out-Null
  Remove-Item -LiteralPath $DST -Force -Recurse -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 150
  Write-Host "OK."
} else {
  Write-Host "Rien à purger ($DST introuvable)."
}
