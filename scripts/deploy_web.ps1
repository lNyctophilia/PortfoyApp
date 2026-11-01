$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Proje kok dizinine gec
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "         PortfoyApp Web Deploy & Versiyon Guncelleme Scripti" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# 1. Tarih ve saati dd.MM.yyyy-HH.mm formatinda al
$buildTime = Get-Date -Format "dd.MM.yyyy-HH.mm"
$versionStr = "Versiyon ($buildTime)"

Write-Host "[*] Yeni Versiyon Belirlendi: $versionStr" -ForegroundColor Yellow
Write-Host "[*] Commit Basligi          : $versionStr" -ForegroundColor Yellow
Write-Host ""

# 2. Dart kodundaki AppVersion dosyasini guncelle
Write-Host "[1/5] lib/core/constants/app_version.dart guncelleniyor..." -ForegroundColor Green
$versionDartPath = Join-Path $projectRoot "lib/core/constants/app_version.dart"
$versionDir = Split-Path -Parent $versionDartPath
if (-not (Test-Path $versionDir)) {
    New-Item -ItemType Directory -Path $versionDir -Force | Out-Null
}
$dartContent = @"
/// Uygulama versiyonu. scripts/deploy_web.bat tarafindan otomatik guncellenir.
class AppVersion {
  static const String current = '$versionStr';
}
"@
[System.IO.File]::WriteAllText($versionDartPath, $dartContent, (New-Object System.Text.UTF8Encoding($false)))

# 3. web/version.json olustur / guncelle (UTF-8 without BOM)
Write-Host "[2/5] web/version.json guncelleniyor..." -ForegroundColor Green
$webDir = Join-Path $projectRoot "web"
if (-not (Test-Path $webDir)) {
    New-Item -ItemType Directory -Path $webDir -Force | Out-Null
}
$versionJsonObj = @{
    version = $versionStr
    build_time = $buildTime
    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
}
$jsonContent = $versionJsonObj | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText((Join-Path $webDir "version.json"), $jsonContent, (New-Object System.Text.UTF8Encoding($false)))

# 3.5. Site erisim guvenligi (gate_security_config.dart) guncelle
Write-Host "[*] Site erisim guvenligi yapilandirmasi hazirlaniyor..." -ForegroundColor Green
$gateScriptPath = Join-Path $projectRoot "scripts/update_gate_security.dart"
dart run $gateScriptPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "[HATA] Guvenlik yapilandirmasi olusturulamadi!" -ForegroundColor Red
    exit 1
}

# 4. Flutter Web Release Build (GitHub Pages base-href ile)
Write-Host "[3/5] Flutter Web derlemesi baslatiliyor (Release + base-href: /PortfoyApp/)..." -ForegroundColor Green
flutter build web --release --base-href /PortfoyApp/
if ($LASTEXITCODE -ne 0) {
    Write-Host "[HATA] Flutter web derlemesi basarisiz oldu!" -ForegroundColor Red
    exit 1
}

# 5. docs/ klasorunu hazirla
Write-Host "[4/5] Derleme ciktilari docs/ klasorune tasiniyor..." -ForegroundColor Green
$docsDir = Join-Path $projectRoot "docs"
if (Test-Path $docsDir) {
    Get-ChildItem -Path $docsDir -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
} else {
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
}

$buildWebDir = Join-Path $projectRoot "build/web"
Copy-Item -Path "$buildWebDir/*" -Destination $docsDir -Recurse -Force

# flutter_bootstrap.js icindeki mainJsPath'e versiyon cache-buster ekle
$bootstrapPath = Join-Path $docsDir "flutter_bootstrap.js"
if (Test-Path $bootstrapPath) {
    $bootstrapContent = [System.IO.File]::ReadAllText($bootstrapPath, [System.Text.Encoding]::UTF8)
    $encodedVersion = [System.Uri]::EscapeDataString($versionStr)
    $bootstrapContent = $bootstrapContent.Replace('"mainJsPath":"main.dart.js"', "`"mainJsPath`":`"main.dart.js?v=$encodedVersion`"")
    [System.IO.File]::WriteAllText($bootstrapPath, $bootstrapContent, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "[OK] flutter_bootstrap.js mainJsPath cache-buster ($versionStr) eklendi." -ForegroundColor Green
}

# GitHub Pages icin .nojekyll ve 404.html (SPA Fallback) olustur
New-Item -ItemType File -Path (Join-Path $docsDir ".nojekyll") -Force | Out-Null
Copy-Item -Path (Join-Path $docsDir "index.html") -Destination (Join-Path $docsDir "404.html") -Force
[System.IO.File]::WriteAllText((Join-Path $docsDir "version.json"), $jsonContent, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "[OK] docs/ klasoru basariyla hazirlandi (.nojekyll ve 404.html dahil)." -ForegroundColor Green
Write-Host ""

# 6. Git commit ve push islemleri
Write-Host "[5/5] Git degisiklikleri kaydediliyor ve gonderiliyor..." -ForegroundColor Green
git add .
git commit -m "$versionStr"
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host " [BASARILI] Web surumu basariyla derlendi ve GitHub'a gonderildi!" -ForegroundColor Green
    Write-Host " Versiyon : $versionStr" -ForegroundColor Yellow
    Write-Host " Branch   : main -> /docs" -ForegroundColor Yellow
    Write-Host " URL      : https://lnyctophilia.github.io/PortfoyApp/" -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
} else {
    Write-Host "[UYARI] git push sirasinda bir uyari olustu veya degisiklik bulunamadi." -ForegroundColor Yellow
}

