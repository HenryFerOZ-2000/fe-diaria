$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$catalog = Get-Content (Join-Path $projectRoot 'lib/bible/domain/catholic_bible_catalog.dart') -Raw
$pages = [regex]::Matches($catalog, '__P[A-Z0-9]+\.HTM') | ForEach-Object { $_.Value } | Sort-Object -Unique
$index = Invoke-WebRequest 'https://www.vatican.va/archive/ESL0506/_INDEX.HTM' -UseBasicParsing
foreach ($page in $pages) {
    if (-not $index.Content.Contains($page)) { throw "Page absent from official index: $page" }
}
if ($pages.Count -ne 76) { throw "Expected 73 books and 3 supplementary links; found $($pages.Count)" }
foreach ($page in @('__P2.HTM', '__PQV.HTM', '__PSN.HTM', '__PU7.HTM', '__PU8.HTM', '__P10X.HTM')) {
    $result = Invoke-WebRequest "https://www.vatican.va/archive/ESL0506/$page" -UseBasicParsing
    if ($result.StatusCode -ne 200) { throw "Unavailable: $page" }
}
Write-Output 'OK: 76 links found in the official index; six representative destinations responded HTTP 200.'
