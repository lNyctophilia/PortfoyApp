@echo off
chcp 65001 >nul
title PortfoyApp Site Şifresi Ayarla

echo ======================================================================
echo             PortfoyApp - Site Erişim Şifresi Ayarlama
echo ======================================================================
echo.
echo Bu işlem sitenize sadece şifreyi bilenlerin girmesini sağlar.
echo Şifre yerel bilgisayarınızda (gate_secret.json) saklanır ve
echo GitHub'a ASLA gönderilmez (gitignore korumalıdır).
echo.
echo Sitede şifre açık metin olarak tutulmaz; 10.000 turlu HMAC-SHA256
echo ile tuzlanmış kriptografik özet haline getirilerek derlenir.
echo ======================================================================
echo.

set /p NEW_PASSWORD="Yeni site erişim şifresini girin (Vazgeçmek için Enter): "

if "%NEW_PASSWORD%"=="" (
    echo.
    echo Hiçbir değişiklik yapılmadı.
    pause
    exit /b 0
)

powershell -NoProfile -Command "$json = @{ enabled = $true; password = '%NEW_PASSWORD%' } | ConvertTo-Json; Set-Content -Path 'gate_secret.json' -Value $json -Encoding utf8"

echo.
echo [*] Kriptografik özet üretiliyor...
dart run "%~dp0update_gate_security.dart"

if errorlevel 1 (
    echo [HATA] Güvenlik yapılandırması üretilirken hata oluştu!
    pause
    exit /b 1
)

echo.
echo ======================================================================
echo [BAŞARILI] Şifreniz başarıyla güncellendi!
echo Yeni şifrenin web sitesinde aktif olması için scripts\deploy_web.bat
echo scriptini çalıştırarak siteyi deploy etmeniz yeterlidir.
echo ======================================================================
echo.
pause

