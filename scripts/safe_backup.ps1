$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

if (-not (Test-Path "pubspec.yaml")) {
  Write-Error "No se encontró pubspec.yaml. Ejecuta desde la raíz del repo."
  exit 1
}

try {
  git --version | Out-Null
} catch {
  Write-Error "Git no está instalado o no está en el PATH."
  exit 1
}

$branch = "firebase-backend-safe"
git rev-parse --verify $branch 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Creando rama $branch..."
  git branch $branch
}

git checkout $branch

git add api scripts firebase.json firestore.rules firestore.indexes.json

git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
  Write-Host "No hay cambios para commitear en rutas permitidas."
  exit 0
}

git commit -m "Backend Firebase seguro antes de conectar Flutter"
Write-Host "Commit creado en rama $branch"

