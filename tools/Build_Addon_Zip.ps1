# --- Build_Addon_Zip.ps1 ---
$ROOT = "D:\V9"
$ADDON_NAME = "blade_v9"
$SRC = Join-Path $ROOT $ADDON_NAME
$DIST = Join-Path $ROOT "dist"
$OUT = Join-Path $DIST "$ADDON_NAME.zip"
$STAGE = Join-Path $DIST "__stage_blade_v9"

if (-not (Test-Path $SRC)) { throw "Source introuvable: $SRC" }
New-Item -ItemType Directory -Path $DIST -Force | Out-Null

# Nettoyage
if (Test-Path $OUT) { Remove-Item $OUT -Force }
if (Test-Path $STAGE) { Remove-Item $STAGE -Recurse -Force }
New-Item -ItemType Directory -Path $STAGE | Out-Null

# Met le dossier add-on sous un répertoire 'blade_v9' pour que Blender voie la racine correcte
Copy-Item -Path $SRC -Destination (Join-Path $STAGE $ADDON_NAME) -Recurse

# Zip avec le dossier racine 'blade_v9' inclus (indispensable pour l'installation Blender)
Compress-Archive -Path (Join-Path $STAGE $ADDON_NAME) -DestinationPath $OUT -Force

# Nettoyage stage
Remove-Item $STAGE -Recurse -Force

Write-Host "OK -> $OUT (installable via Preferences > Add-ons > Install...)"
