$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

if (-not (Test-Path "pubspec.yaml")) {
  Write-Error "No se encontró pubspec.yaml. Ejecuta desde la raíz del repo."
  exit 1
}

Write-Host "Estado de git:"
git status

$allowed = @(
  "api/",
  "scripts/",
  "firebase.json",
  "firestore.rules",
  "firestore.indexes.json"
)

$changes = git status --porcelain
$violations = @()

foreach ($line in $changes) {
  if (-not $line) { continue }
  $pathPart = $line.Substring(3)
  if ($pathPart -match " -> ") {
    $parts = $pathPart -split " -> "
    $pathPart = $parts[-1]
  }
  $normalized = ($pathPart.Trim()) -replace "\\", "/"

  $isAllowed = $false
  foreach ($allow in $allowed) {
    if ($normalized.StartsWith($allow)) {
      $isAllowed = $true
      break
    }
  }

  if (-not $isAllowed) {
    $violations += $normalized
  }
}

if ($violations.Count -gt 0) {
  Write-Host "ALERTA: Cambios fuera de rutas permitidas:" -ForegroundColor Red
  $violations | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
  exit 1
}

Write-Host "SAFE: Flutter no fue tocado."

