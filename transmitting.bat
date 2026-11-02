@echo off
tasklist /FI "IMAGENAME eq scrcpy.exe" 2>nul | find /I /N "scrcpy.exe" >nul
if "%ERRORLEVEL%"=="0" (
    taskkill /F /IM scrcpy.exe >nul 2>&1
    adb disconnect >nul 2>&1
    exit
)

set "TARGET=%~1"
if "%TARGET%"=="" (
    if exist "%~dp0phone_ip.txt" (
        set /p TARGET=<"%~dp0phone_ip.txt"
    )
)

if "%TARGET%"=="" (
    echo Nenhum IP de celular configurado. Conecte pelo app ou passe o IP como argumento.
    exit /b 1
)

echo %TARGET% | findstr /C:":" >nul
if %ERRORLEVEL% NEQ 0 (
    set "TARGET=%TARGET%:5555"
)

adb connect %TARGET% >nul 2>&1
scrcpy -s %TARGET% --window-title "Meu Celular"
adb disconnect %TARGET% >nul 2>&1
exit
