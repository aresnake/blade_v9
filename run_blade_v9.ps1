param(
    [string]$BlenderExe = "C:\Program Files\Blender Foundation\Blender 4.5\blender.exe",
    [string]$Root = "D:\V9",
    [switch]$PrePurge = $true,   # purge AVANT install (par défaut: ON)
    [switch]$Inspect   = $false   # dump des 20 premières lignes du __init__ installé
)

$ErrorActionPreference = "Stop"

Write-Host "[Blade v9 bootstrap] Addons dir: $env:APPDATA\Blender Foundation\Blender\4.5\scripts\addons"
Write-Host "[Blade v9 bootstrap] Root: $Root"

# --- (1) Pré-purge optionnelle ---
$addonsDir = Join-Path $env:APPDATA "Blender Foundation\Blender\4.5\scripts\addons"
$installed = Join-Path $addonsDir "blade_v9"
if ($PrePurge) {
    if (Test-Path $installed) {
        Remove-Item $installed -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[Blade v9 bootstrap] Purged old installed addon: $installed"
    }
}

# --- (2) Zip correct: inclure le dossier "blade_v9" ---
$zip = Join-Path $Root "blade_v9.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
  (Join-Path $Root "blade_v9"), $zip,
  [System.IO.Compression.CompressionLevel]::Optimal, $true
)
Write-Host "[Blade v9 bootstrap] Zip: $zip"

# --- (3) Enable script ---
$enableV9 = Join-Path $Root "tools\enable_blade_v9.py"
if (!(Test-Path $enableV9)) { Write-Host "⚠️ enable_blade_v9.py introuvable" -ForegroundColor Yellow; exit 1 }

# --- (4) Lancer Blender (factory + python) ---
& $BlenderExe -con --factory-startup --python $enableV9

# --- (5) Inspection optionnelle après install ---
if ($Inspect) {
    $init = Join-Path $installed "__init__.py"
    if (Test-Path $init) {
        Write-Host "`n[Inspect] First lines of installed __init__.py:" -ForegroundColor Cyan
        Get-Content $init -TotalCount 20
    } else {
        Write-Host "[Inspect] Installed path not found (maybe PrePurge was on or install failed)." -ForegroundColor Yellow
    }
}
