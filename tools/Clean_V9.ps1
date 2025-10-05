<# 
  Clean_V9.ps1 — Purge propre de l’addon Blade v9 dans Blender 4.5.x
  - Stoppe Blender si lancé
  - Localise les dossiers addons Blender (Roaming)
  - Supprime proprement l’addon cible (par défaut: blade_v9)
  - Optionnels: purge des zips installés, logs, modules orphelins
  - 100% idempotent, WhatIf support, sans wildcards dangereux

  Usage:
    .\Clean_V9.ps1
    .\Clean_V9.ps1 -AddonName blade_v9 -IncludeZips -IncludeModules -IncludeLogs -Verbose
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string]$AddonName = "blade_v9",
  [switch]$IncludeZips,      # supprime les zips installés portant AddonName
  [switch]$IncludeModules,   # supprime addons\modules\* liés (rare, si pack décompressé en modules)
  [switch]$IncludeLogs       # supprime logs Blade locaux (si connus)
)

function Stop-Blender {
  Write-Verbose "Stopping any running Blender process..."
  Get-Process blender -ErrorAction SilentlyContinue | ForEach-Object {
    try {
      if ($PSCmdlet.ShouldProcess($_.ProcessName, "Stop-Process -Force")) {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
      }
    } catch {
      Write-Warning "Failed to stop process: $($_.ProcessName) ($($_.Id)) : $($_.Exception.Message)"
    }
  }
}

function Get-AddonDirs {
  # Ex: C:\Users\<user>\AppData\Roaming\Blender Foundation\Blender\4.5\scripts\addons
  $base = Join-Path $env:APPDATA "Blender Foundation\Blender"
  if (-not (Test-Path $base)) {
    return @()
  }
  Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $addons = Join-Path $_.FullName "scripts\addons"
    if (Test-Path $addons) { $addons }
  }
}

function Remove-ItemSafe([string]$Path) {
  if (-not (Test-Path $Path)) { return $false }
  try {
    if ($PSCmdlet.ShouldProcess($Path, "Remove-Item -Recurse -Force")) {
      Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
    }
    return $true
  } catch {
    Write-Warning "Failed to remove: $Path — $($_.Exception.Message)"
    return $false
  }
}

function Remove-Addon([string]$AddonsDir, [string]$Name) {
  $target = Join-Path $AddonsDir $Name
  if (Test-Path $target) {
    Write-Host "[Clean] Purging addon dir: $target"
    [void](Remove-ItemSafe $target)
  } else {
    Write-Verbose "[Clean] Addon dir not found: $target"
  }
}

function Remove-AddonZips([string]$AddonsDir, [string]$Name) {
  $pattern = "*$Name*.zip"
  $zips = Get-ChildItem -Path $AddonsDir -Filter $pattern -ErrorAction SilentlyContinue
  foreach ($z in $zips) {
    Write-Host "[Clean] Purging addon zip: $($z.FullName)"
    [void](Remove-ItemSafe $z.FullName)
  }
}

function Remove-AddonModules([string]$AddonsDir, [string]$Name) {
  # Cas rares: quand l’addon a été installé dans addons\modules
  $modulesDir = Join-Path (Split-Path $AddonsDir -Parent) "addons\modules"
  if (-not (Test-Path $modulesDir)) { return }
  $hits = Get-ChildItem -Path $modulesDir -Recurse -Directory -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -like "*$Name*" }
  foreach ($h in $hits) {
    Write-Host "[Clean] Purging addon module dir: $($h.FullName)"
    [void](Remove-ItemSafe $h.FullName)
  }
}

function Remove-Logs([string]$Name) {
  # Adapter aux emplacements connus de Blade v9 si besoin
  $candidates = @()
  $candidates += "$env:USERPROFILE\blade_logs"
  $candidates += "$env:USERPROFILE\AppData\Local\blade_logs"
  $candidates += "$env:USERPROFILE\AppData\Local\Temp\blade_logs"
  foreach ($root in $candidates) {
    if (-not (Test-Path $root)) { continue }
    $hits = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*$Name*" -or $_.Name -like "*blade_v9*" }
    foreach ($h in $hits) {
      Write-Host "[Clean] Purging log: $($h.FullName)"
      [void](Remove-ItemSafe $h.FullName)
    }
  }
}

Write-Host "=== [Clean_V9] START ===" -ForegroundColor Cyan
Write-Host "AddonName    : $AddonName"
Write-Host "IncludeZips  : $IncludeZips"
Write-Host "IncludeModules: $IncludeModules"
Write-Host "IncludeLogs  : $IncludeLogs"
Write-Host "WhatIf       : $($WhatIfPreference -eq 'Continue')"

Stop-Blender

$addonDirs = Get-AddonDirs
if ($addonDirs.Count -eq 0) {
  Write-Warning "No Blender addons directory found under Roaming. Nothing to clean."
  Write-Host "=== [Clean_V9] END (No-Op) ===" -ForegroundColor Cyan
  exit 0
}

foreach ($dir in $addonDirs) {
  Write-Host "[Target] Addons dir: $dir"

  # 1) dossier principal
  Remove-Addon -AddonsDir $dir -Name $AddonName

  # 2) zips
  if ($IncludeZips) { Remove-AddonZips -AddonsDir $dir -Name $AddonName }

  # 3) modules orphelins
  if ($IncludeModules) { Remove-AddonModules -AddonsDir $dir -Name $AddonName }
}

# 4) logs
if ($IncludeLogs) { Remove-Logs -Name $AddonName }

Write-Host "=== [Clean_V9] DONE ===" -ForegroundColor Green
exit 0
