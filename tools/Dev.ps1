param([switch]$Gui)

$ErrorActionPreference = "Stop"
$BL_VER = "4.5"
$ADDONS = Join-Path $env:APPDATA "Blender Foundation\Blender\$BL_VER\scripts\addons"
$SRC    = "D:\V9\blade_v9"
$DST    = Join-Path $ADDONS "blade_v9"
$BLENDER_EXE = "C:\Program Files\Blender Foundation\Blender 4.5\blender.exe"
$VERIFY_PY   = "D:\V9\tools\verify_blade.py"

Write-Host "== CLOSE BLENDER =="
Get-Process blender -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "== PURGE =="
Get-ChildItem -Path $ADDONS -Directory -Filter "blade_v*" -ErrorAction SilentlyContinue |
  ForEach-Object { Write-Host " - Removing $($_.FullName)"; Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
Get-ChildItem -Path $ADDONS -Recurse -Directory -Filter "__pycache__" -ErrorAction SilentlyContinue |
  ForEach-Object { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
Write-Host "PURGE OK"

Write-Host "== SYNC =="
if (Test-Path $DST) { Remove-Item $DST -Recurse -Force -ErrorAction SilentlyContinue }
cmd /c "mklink /J `"$DST`" `"$SRC`"" | Out-Null
if (-not (Test-Path $DST)) { Copy-Item -Path $SRC -Destination $DST -Recurse -Force }
Write-Host "SYNC OK -> $DST"

if ($Gui) {
  Write-Host "== RUN GUI (console) =="
  & $BLENDER_EXE -con --addons blade_v9
} else {
  Write-Host "== VERIFY background =="
  if (-not (Test-Path $VERIFY_PY)) { throw "Script de vérification manquant: $VERIFY_PY" }
  & $BLENDER_EXE -b -P $VERIFY_PY
}
Write-Host "== DONE =="
