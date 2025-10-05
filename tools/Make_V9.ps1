<#
  Make_V9.ps1 — Pack & Install Blade v9 (compat PS5+)
  - Staging robuste (fonctionne lancé via script, CI, ou console)
  - Exclusions propres (legacy ares/, caches, artefacts)
  - Arrêt Blender avant install
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string]$AddonName   = "blade_v9",
  [string]$ProjectRoot = $null
)

$ErrorActionPreference = "Stop"

function Fail([string]$msg, [int]$code = 1) { Write-Error $msg; exit $code }

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
  $base = Join-Path $env:APPDATA "Blender Foundation\Blender"
  if (-not (Test-Path $base)) { return @() }
  Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $addons = Join-Path $_.FullName "scripts\addons"
    if (Test-Path $addons) { $addons }
  }
}

function Should-Exclude([string]$RelUnix, [string[]]$Patterns) {
  foreach ($p in $Patterns) { if ($RelUnix -like $p) { return $true } }
  return $false
}

function New-StagingFromSource([string]$SourceDir, [string]$StagingDir, [string[]]$ExcludePatterns) {
  if (-not (Test-Path $SourceDir)) { Fail "SourceDir not found: $SourceDir" 2 }
  if (Test-Path $StagingDir) { Remove-Item -Path $StagingDir -Recurse -Force -ErrorAction SilentlyContinue }
  New-Item -Path $StagingDir -ItemType Directory -Force | Out-Null

  $all = Get-ChildItem -Path $SourceDir -Recurse -File -ErrorAction Stop
  $count = 0
  foreach ($f in $all) {
    $rel = $f.FullName.Substring($SourceDir.Length).TrimStart('\','/')
    $relUnix = ($rel -replace '\\','/')
    if (Should-Exclude -RelUnix $relUnix -Patterns $ExcludePatterns) { continue }
    $dest = Join-Path $StagingDir $rel
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory -Force | Out-Null }
    Copy-Item -Path $f.FullName -Destination $dest -Force
    $count++
  }
  if ($count -eq 0) { Fail "Staging empty: no files copied (check exclusions/source)." 3 }
  Write-Host "[Make] Staged $count files -> $StagingDir"
}

function New-ZipFromStaging([string]$StagingDir, [string]$ZipPath) {
  if (Test-Path $ZipPath) { Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue }
  Compress-Archive -Path (Join-Path $StagingDir '*') -DestinationPath $ZipPath -Force
  if (-not (Test-Path $ZipPath)) { Fail "Zip creation failed: $ZipPath" 4 }
  Write-Host "[Make] Packed -> $ZipPath"
}

function Install-AddonFromZip([string]$ZipPath, [string]$AddonsDir, [string]$AddonName) {
  if (-not (Test-Path $ZipPath)) { Fail "Zip not found: $ZipPath" 5 }
  $targetDir = Join-Path $AddonsDir $AddonName
  if (Test-Path $targetDir) {
    Write-Host "[Make] Purging previous install: $targetDir"
    Remove-Item -Path $targetDir -Recurse -Force -ErrorAction SilentlyContinue
  }
  New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
  Expand-Archive -Path $ZipPath -DestinationPath $targetDir -Force
  Write-Host "[Make] Installed to: $targetDir"
}

try {
  # -- Résolution robuste des chemins (script, CI, ou console interactive) --
  if (-not $ProjectRoot) {
    if ($PSScriptRoot) {
      $ProjectRoot = Split-Path -Parent $PSScriptRoot
    } elseif ($MyInvocation.MyCommand.Path) {
      $scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
      $ProjectRoot = Split-Path -Parent $scriptDir
    } else {
      # Exécution directe en console: on prend le dossier courant comme racine
      $ProjectRoot = (Get-Location).Path
    }
  }

  $sourceDir = Join-Path $ProjectRoot $AddonName
  $zipPath   = Join-Path $ProjectRoot "$AddonName.zip"
  $staging   = Join-Path $ProjectRoot "_pack_$AddonName.tmp"

  Write-Host "=== [Make_V9] START ===" -ForegroundColor Cyan
  Write-Host "AddonName  : $AddonName"
  Write-Host "ProjectRoot: $ProjectRoot"
  Write-Host "SourceDir  : $sourceDir"
  Write-Host "ZipPath    : $zipPath"

  if (-not (Test-Path (Join-Path $sourceDir "__init__.py"))) { Fail "Missing __init__.py in $sourceDir" 6 }

  Stop-Blender

  # Exclusions: legacy ares/, caches, artefacts, outils/tests, fichiers temporaires
  $exclusions = @(
    "ares/*",           # legacy (exclu du package)
    "__pycache__/*",
    ".git/*",
    "tests/*",
    "tools/*",
    "dist/*",
    "archives/*",
    "logs/*",
    "_zip_check/*",
    "*.ps1",
    "*.bat",
    "*.log",
    "*.tmp",
    "*.pyc",
    "*.bak",
    "*.bak_*"
  )

  New-StagingFromSource -SourceDir $sourceDir -StagingDir $staging -ExcludePatterns $exclusions
  New-ZipFromStaging     -StagingDir $staging  -ZipPath        $zipPath

  $addonDirs = Get-AddonDirs
  if ($addonDirs.Count -eq 0) {
    Write-Warning "No Blender addons directory found under Roaming. Skipping install."
  } else {
    foreach ($dir in $addonDirs) {
      Write-Host "[Target] Addons dir: $dir"
      Install-AddonFromZip -ZipPath $zipPath -AddonsDir $dir -AddonName $AddonName
    }
  }

  Remove-Item -Path $staging -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "=== [Make_V9] DONE ===" -ForegroundColor Green
  exit 0
}
catch {
  Fail ("[Make_V9] FAILED: " + $_.Exception.Message)
}
