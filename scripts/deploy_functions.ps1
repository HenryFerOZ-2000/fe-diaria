$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot
Write-Host "Repo root:" (Get-Location)

Set-Location (Join-Path $repoRoot "api")
Write-Host "Working in" (Get-Location)

$nodeModulesPath = Join-Path (Get-Location) "node_modules"
if (Test-Path $nodeModulesPath) {
  Write-Host "Removing node_modules..."
  Remove-Item $nodeModulesPath -Recurse -Force
}

$lockPath = Join-Path (Get-Location) "package-lock.json"
if (Test-Path $lockPath) {
  Write-Host "Removing package-lock.json..."
  Remove-Item $lockPath -Force
}

Write-Host "Installing dependencies..."
npm install

Write-Host "Running lint..."
npm run lint

Write-Host "Building..."
npm run build

Set-Location $repoRoot
Write-Host "Deploying functions (codebase api)..."
firebase deploy --only functions:api

$seedUrl = "https://<region>-<project-id>.cloudfunctions.net/seedFirestore"
Write-Host ""
Write-Host "Para ejecutar seed (requiere SEED_KEY):"
Write-Host '  $env:SEED_KEY="coloca-tu-clave"'
Write-Host "  curl -X POST -H `"x-seed-key: $env:SEED_KEY`" $seedUrl"
Write-Host ""
Write-Host "Verifica en Firestore:"
Write-Host "  daily_content/{YYYYMMDD} (UTC)"
Write-Host "  users/TEST_UID"
Write-Host "  live_posts/seed_oracion_prueba"

