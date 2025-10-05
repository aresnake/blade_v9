# Push_V9.ps1 — commit + tag + push
param(
  [string]$RepoRoot = "D:\V9",
  [string]$Tag = "v9.3.1",
  [string]$Message = "chore: bump to $Tag"
)

$ErrorActionPreference = "Stop"
Set-Location $RepoRoot
git config --global --add safe.directory D:/V9

# commit si modifs
git add -A
$staged = git diff --cached --name-only
if ($staged) {
  git commit -m $Message
} else {
  Write-Host "Aucune modification à committer." -ForegroundColor Yellow
}

# tag + push
git tag -f $Tag
git push -u origin (git branch --show-current)
git push --tags
Write-Host "✅ Pushed $Tag" -ForegroundColor Green
