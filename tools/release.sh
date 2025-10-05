#!/usr/bin/env bash
set -euo pipefail

# -------- Config --------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && (pwd -W 2>/dev/null || pwd))"   # chemin Windows si Git Bash
PS="powershell.exe -NoProfile -ExecutionPolicy Bypass"
TAG=""          # si vide => --bump patch par défaut
BUMP="patch"   # patch | minor | major
PUSH_REMOTE="origin"

usage() {
  cat <<USAGE
Usage:
  tools/release.sh [--tag vX.Y.Z] [--bump patch|minor|major] [--no-tests] [--no-zip] [--no-push]

Par défaut: bump patch + build + tests + zip daté + commit (si changements) + tag + push.
Exemples:
  tools/release.sh --tag v9.3.6
  tools/release.sh --bump minor
  tools/release.sh --bump patch --no-tests
USAGE
}

RUN_TESTS=1
MAKE_ZIP=1
DO_PUSH=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="${2:-}"; shift 2;;
    --bump) BUMP="${2:-patch}"; shift 2;;
    --no-tests) RUN_TESTS=0; shift;;
    --no-zip) MAKE_ZIP=0; shift;;
    --no-push) DO_PUSH=0; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Arg inconnu: $1"; usage; exit 2;;
  esac
done

cd "$ROOT"

# Sécurité exFAT/USB (inutile si déjà fait)
git config --global --add safe.directory "$(pwd -W 2>/dev/null || pwd)" || true

# Déterminer le tag si non fourni: on bump depuis le plus récent v*
latest_tag="$(git tag --list 'v*' | sort -V | tail -n1 || true)"
if [[ -z "$TAG" ]]; then
  if [[ -z "$latest_tag" ]]; then
    echo "Aucun tag v* trouvé. Utilise --tag vX.Y.Z pour initialiser."; exit 1
  fi
  ver="${latest_tag#v}"
  IFS='.' read -r MAJ MIN PAT <<< "$ver"
  case "$BUMP" in
    patch) PAT=$((PAT+1));;
    minor) MIN=$((MIN+1)); PAT=0;;
    major) MAJ=$((MAJ+1)); MIN=0; PAT=0;;
    *) echo "BUMP invalide: $BUMP"; exit 2;;
  esac
  TAG="v${MAJ}.${MIN}.${PAT}"
fi

echo "==> ROOT: $ROOT"
echo "==> TAG ciblé : $TAG (à partir de: ${latest_tag:-none})"
echo

# 1) Build (zip + install dev)
echo "==> Build addon"
$PS -File "$ROOT\tools\Make_V9.ps1" -Verbose

# 2) Tests (optionnels)
if [[ $RUN_TESTS -eq 1 ]]; then
  echo "==> Smoke tests"
  $PS -File "$ROOT\tools\Test_V9.ps1"
else
  echo "==> Tests désactivés (--no-tests)"
fi

# 3) Zip daté (optionnel)
if [[ $MAKE_ZIP -eq 1 ]]; then
  echo "==> Crée le zip daté dans dist/"
  $PS -File "$ROOT\tools\Release_V9.ps1"
else
  echo "==> Zip daté désactivé (--no-zip)"
fi

# 4) Git commit si changements
echo "==> Git stage & commit"
git add -A
if git diff --cached --quiet; then
  echo "Aucun changement à committer."
else
  git commit -m "chore: release $TAG"
fi

# 5) Tag (force si existe)
echo "==> Tag $TAG"
git tag -f "$TAG"

# 6) Push
if [[ $DO_PUSH -eq 1 ]]; then
  echo "==> Push main + tags -> $PUSH_REMOTE"
  current_branch="$(git branch --show-current)"
  git push -u "$PUSH_REMOTE" "$current_branch"
  git push --tags
else
  echo "==> Push désactivé (--no-push)"
fi

# 7) Affiche le dernier zip pour info
if [[ -d "dist" ]]; then
  latest_zip="$(ls -1t dist/blade_v9_*.zip 2>/dev/null | head -n1 || true)"
  [[ -n "$latest_zip" ]] && echo "Dernier ZIP: $latest_zip"
fi

echo "✅ Release terminée: $TAG"
