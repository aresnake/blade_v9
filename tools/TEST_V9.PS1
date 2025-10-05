# Test_V9.ps1 — wrapper simple pour lancer les tests
# On garde un point d'entrée stable, même si le script "réel" change de nom.

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$smoke = Join-Path $here "SmokeTest_V9.ps1"

if (Test-Path $smoke) {
  & $smoke
} else {
  Write-Error "SmokeTest_V9.ps1 introuvable dans tools/"
  exit 1
}
