$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Proje kok dizinine gec
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "            PortfoyApp - Site Erisim Sifresi Ayarlama" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Bu islem sitenize sadece sifreyi bilenlerin girmesini saglar." -ForegroundColor Gray
Write-Host "Sifre yerel bilgisayarinizda (gate_secret.json) saklanir ve" -ForegroundColor Gray
Write-Host "GitHub'a ASLA gonderilmez (.gitignore ile korunur)." -ForegroundColor Gray
Write-Host ""
Write-Host "Sitede sifre acik metin olarak tutulmaz; 10.000 turlu HMAC-SHA256" -ForegroundColor Gray
Write-Host "ile tuzlanmis kriptografik ozet haline getirilerek derlenir." -ForegroundColor Gray
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

$secretPath = Join-Path $projectRoot "gate_secret.json"
$currentEnabled = $true
$currentPassword = ""

if (Test-Path $secretPath) {
    try {
        $json = Get-Content -Raw -Path $secretPath -Encoding UTF8 | ConvertFrom-Json
        $currentEnabled = [bool]$json.enabled
        $currentPassword = [string]$json.password
        Write-Host "[*] Mevcut Durum : " -NoNewline
        if ($currentEnabled) {
            Write-Host "Aktif" -ForegroundColor Green
        } else {
            Write-Host "Devre Disi" -ForegroundColor Red
        }
        if ($currentPassword) {
            Write-Host "[*] Mevcut Sifre : $currentPassword" -ForegroundColor Yellow
        }
        Write-Host ""
    } catch {
        Write-Host "[!] Mevcut gate_secret.json okunamadi, yeni olusturulacak." -ForegroundColor Yellow
    }
}

$prompt = "Yeni site erisim sifresini girin (Vazgecmek icin Enter)"
$newPassword = Read-Host $prompt

if ([string]::IsNullOrWhiteSpace($newPassword)) {
    Write-Host ""
    Write-Host "[*] Hicbir degisiklik yapilmadi." -ForegroundColor Yellow
    Write-Host ""
    return
}

$newPassword = $newPassword.Trim()

$secretObj = [ordered]@{
    enabled  = $true
    password = $newPassword
}

$jsonOutput = $secretObj | ConvertTo-Json
[System.IO.File]::WriteAllText($secretPath, $jsonOutput + "`r`n", [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "[*] Kriptografik ozet uretiliyor..." -ForegroundColor Cyan

$dartScript = Join-Path $scriptDir "update_gate_security.dart"
& dart run $dartScript
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[HATA] Guvenlik yapilandirmasi uretilirken hata olustu!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "[BASARILI] Sifreniz basariyla guncellendi!" -ForegroundColor Green
Write-Host "Yeni sifrenin web sitesinde aktif olmasi icin scripts\deploy_web.bat" -ForegroundColor White
Write-Host "scriptini calistirarak siteyi deploy etmeniz yeterlidir." -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Green

