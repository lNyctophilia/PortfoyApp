@echo off
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_web.ps1"
if errorlevel 1 (
    echo.
    echo Script hata ile sonlandi.
    exit /b %errorlevel%
)
