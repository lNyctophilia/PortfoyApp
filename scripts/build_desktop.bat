@echo off
setlocal
echo ========================================================
echo  PortfoyApp Desktop - Visual Studio MSVC Build
echo ========================================================

call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
if %ERRORLEVEL% NEQ 0 (
    echo [HATA] Visual Studio C++ araclari yuklenemedi.
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "DESKTOP_DIR=%ROOT_DIR%\desktop"
set "OUTPUT_DIR=%ROOT_DIR%\build\desktop"

cd /d "%DESKTOP_DIR%"

if not exist "bin\Release" mkdir "bin\Release"
if not exist "obj" mkdir "obj"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo [1/3] Kaynak dosyalari derleniyor (Resource)...
rc.exe /fo "obj\app.res" "src\app.rc"
if %ERRORLEVEL% NEQ 0 (
    echo [HATA] Resource derleme basarisiz.
    exit /b 1
)

echo [2/3] C++ kodu derleniyor ve baglaniyor (Release /MT)...
cl.exe /nologo /O2 /MT /W3 /EHsc /std:c++17 ^
    /D "UNICODE" /D "_UNICODE" /D "NDEBUG" ^
    /I "src" /I "packages\Microsoft.Web.WebView2\build\native\include" ^
    /Fo"obj\\" /Fe"bin\Release\PortfoyApp.exe" ^
    "src\main.cpp" "obj\app.res" ^
    /link /NOLOGO /SUBSYSTEM:WINDOWS ^
    /LIBPATH:"packages\Microsoft.Web.WebView2\build\native\x64" ^
    WebView2LoaderStatic.lib dwmapi.lib shell32.lib ole32.lib user32.lib gdi32.lib advapi32.lib ^
    /MANIFEST:EMBED /MANIFESTINPUT:"src\app.manifest"

if %ERRORLEVEL% NEQ 0 (
    echo [HATA] Derleme basarisiz.
    exit /b 1
)

echo [3/3] Dagitim dosyalari build\desktop klasorune kopyalaniyor...
copy /Y "bin\Release\PortfoyApp.exe" "%OUTPUT_DIR%\PortfoyApp.exe" >nul
copy /Y "assets\app.ico" "%OUTPUT_DIR%\app.ico" >nul
copy /Y "packages\Microsoft.Web.WebView2\build\native\x64\WebView2Loader.dll" "%OUTPUT_DIR%\WebView2Loader.dll" >nul

echo ========================================================
echo  BASARILI! PortfoyApp.exe hazirlandi:
echo  1) %DESKTOP_DIR%\bin\Release\PortfoyApp.exe
echo  2) %OUTPUT_DIR%\PortfoyApp.exe
echo ========================================================
