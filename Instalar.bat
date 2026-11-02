@echo off
chcp 65001 >nul
title Instalador - Espelhar Tela (scrcpy sem cabos)
color 0A

echo ========================================================
echo   INSTALADOR - ESPELHAR TELA (SCRCPY WIRELESS TOGGLE)
echo ========================================================
echo.

set "INSTALL_DIR=%~dp0"
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

echo [1/5] Verificando scrcpy e adb...
where scrcpy >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   - scrcpy nao encontrado. Instalando via winget...
    winget install --id Genymobile.scrcpy -e --accept-source-agreements --accept-package-agreements
) else (
    echo   - scrcpy ja instalado!
)

echo.
echo [2/5] Configurando atalhos com a logo oficial no Menu Iniciar e Desktop...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$dir = '%INSTALL_DIR%';" ^
    "$sh = New-Object -ComObject WScript.Shell;" ^
    "$paths = @(" ^
    "  \"$dir\Espelhar Tela.lnk\"," ^
    "  \"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Espelhar Tela.lnk\"," ^
    "  \"$([Environment]::GetFolderPath('Desktop'))\Espelhar Tela.lnk\"" ^
    ");" ^
    "foreach ($p in $paths) {" ^
    "  $lnk = $sh.CreateShortcut($p);" ^
    "  $lnk.TargetPath = \"$dir\listener_udp.exe\";" ^
    "  $lnk.Arguments = '--toggle';" ^
    "  $lnk.WorkingDirectory = $dir;" ^
    "  $lnk.IconLocation = \"$dir\celular.ico,0\";" ^
    "  $lnk.Description = 'Espelhar a tela do celular no PC sem fios via scrcpy';" ^
    "  $lnk.Save();" ^
    "}"
echo   - Atalho "Espelhar Tela" registrado com sucesso!

echo.
echo [3/5] Configurando Ouvinte em Segundo Plano (Agendador de Tarefas)...
taskkill /F /IM listener_udp.exe >nul 2>&1
schtasks /Create /TN "Ouvinte do Celular" /TR "\"%INSTALL_DIR%\listener_udp.exe\"" /SC ONLOGON /RL HIGHEST /F >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    schtasks /Create /TN "Ouvinte do Celular" /TR "\"%INSTALL_DIR%\listener_udp.exe\"" /SC ONLOGON /F >nul 2>&1
)
schtasks /Run /TN "Ouvinte do Celular" >nul 2>&1
echo   - Tarefa "Ouvinte do Celular" ativa e rodando na porta UDP 8888!

echo.
echo [4/5] Liberando porta UDP 8888 no Firewall do Windows (se executado como Admin)...
netsh advfirewall firewall delete rule name="Espelhar Tela UDP 8888" >nul 2>&1
netsh advfirewall firewall add rule name="Espelhar Tela UDP 8888" dir=in action=allow protocol=UDP localport=8888 >nul 2>&1

echo.
echo [5/5] Verificando se ha um celular conectado via cabo USB para pareamento inicial...
adb devices 2>nul | findstr /R /C:"device$" >nul
if %ERRORLEVEL% EQU 0 (
    echo   - Celular detectado no USB!
    echo   - Ativando ADB TCP/IP na porta 5555...
    adb tcpip 5555
    if exist "%INSTALL_DIR%\EspelharTela.apk" (
        echo   - Instalando aplicativo EspelharTela.apk no celular...
        adb install -r "%INSTALL_DIR%\EspelharTela.apk"
    )
    echo   - Tudo pronto! Voce ja pode desconectar o cabo USB.
) else (
    echo   - DICA: Conecte o celular no USB na primeira vez (com Depuracao USB ativa)
    echo     e rode este instalador novamente para ativar o modo sem fio e instalar o APK automaticamente.
)

echo.
echo ========================================================
echo   INSTALACAO CONCLUIDA COM SUCESSO!
echo   - Pesquise "Espelhar Tela" no Menu Iniciar do Windows
echo   - Ou toque em "Espelhar Agora" no app do celular!
echo ========================================================
pause
