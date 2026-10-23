# Publish Flutter web via GitHub Actions (push master) or local preview build.
# Live URL: https://guoshuaipeng.github.io/vocab_helper/
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "==> flutter build web (local check, base-href /vocab_helper/)"
flutter build web --release --base-href /vocab_helper/
Copy-Item -Force (Join-Path $root "build\web\index.html") (Join-Path $root "build\web\404.html")

Write-Host ""
Write-Host "Local build OK. To publish: push master to github remote."
Write-Host "  git push github master"
Write-Host "Site: https://guoshuaipeng.github.io/vocab_helper/"
