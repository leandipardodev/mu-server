@echo off
title Jugar MU
cd /d "%~dp0Cliente"

if not exist "MainInfo.ini" goto missing_info
if not exist "GetMainInfo.exe" goto missing_generator
if not exist "main.exe" goto missing_client

if exist "local.bmd" (
    if not exist "local.bmd.before-jugar.bak" (
        copy /y "local.bmd" "local.bmd.before-jugar.bak" >nul
        if errorlevel 1 goto backup_error
    )
)

echo Aplicando la configuracion de MainInfo.ini...
"GetMainInfo.exe"
if not exist "local.bmd" goto missing_output

echo Iniciando el cliente...
start "" /wait "main.exe"
set "CLIENT_EXIT_CODE=%ERRORLEVEL%"
if not "%CLIENT_EXIT_CODE%"=="0" echo main.exe termino con codigo %CLIENT_EXIT_CODE%.
echo El cliente se cerro. La ventana queda abierta para mostrar el resultado.
pause
exit /b %CLIENT_EXIT_CODE%

:missing_info
echo ERROR: No se encontro Cliente\MainInfo.ini.
goto failed

:missing_generator
echo ERROR: No se encontro Cliente\GetMainInfo.exe.
goto failed

:missing_client
echo ERROR: No se encontro Cliente\main.exe.
goto failed

:backup_error
echo ERROR: No se pudo respaldar local.bmd.
goto failed

:missing_output
echo ERROR: GetMainInfo.exe no genero local.bmd.
goto failed

:failed
pause
exit /b 1
