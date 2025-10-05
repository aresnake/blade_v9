<# Release_V9.ps1 — copie le zip packagé vers un dossier dist/ daté. #>
$ErrorActionPreference="Stop"
$project="D:\V9"; $zip=Join-Path $project "blade_v9.zip"
if(-not(Test-Path $zip)){ Write-Error "Zip not found: $zip. Run tools\Make_V9.ps1 first."; exit 2 }
$dist=Join-Path $project "dist"; if(-not(Test-Path $dist)){ New-Item -ItemType Directory -Path $dist | Out-Null }
$stamp=Get-Date -Format "yyyyMMdd_HHmmss"; $dest=Join-Path $dist "blade_v9_$stamp.zip"
Copy-Item -Path $zip -Destination $dest -Force
Write-Host "Release created: $dest" -ForegroundColor Green
