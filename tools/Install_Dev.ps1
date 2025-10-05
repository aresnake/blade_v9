# --- Install_Dev.ps1 ---
# Branche l'add-on en "live" via Junction: addons\blade_v9 -> D:\V9\blade_v9

$ROOT = "D:\V9"
$ADDON_NAME = "blade_v9"
$BLENDER_VER = "4.5"
$USER_ADDONS = Join-Path $env:APPDATA "Blender Foundation\Blender\$BLENDER_VER\scripts\addons"
$SRC = Join-Path $ROOT $ADDON_NAME
$DST = Join-Path $USER_ADDONS $ADDON_NAME

if (-not (Test-Path $SRC)) { throw "Source introuvable: $SRC" }
if (-not (Test-Path (Join-Path $SRC '__init__.py'))) { throw "__init__.py manquant dans $SRC" }

New-Item -ItemType Directory -Path $USER_ADDONS -Force | Out-Null

if (Test-Path $DST) {
  Write-Host ">> Purge précédente: $DST"
  attrib -r -h -s $DST -Recurse -ErrorAction SilentlyContinue | Out-Null
  Remove-Item -LiteralPath $DST -Force -Recurse -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 150
}

Write-Host ">> Création d'une JUNCTION: $DST -> $SRC"
cmd /c "mklink /J `"$DST`" `"$SRC`"" | Out-Null

if (-not (Test-Path $DST)) { throw "Échec de création de la junction: $DST" }

Write-Host "OK. Dans Blender: Edit > Preferences > Add-ons > activer '$ADDON_NAME' (Reload si besoin)."
