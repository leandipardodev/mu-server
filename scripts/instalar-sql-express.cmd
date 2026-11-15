@echo off
REM ============================================================================
REM  Instalador de SQL Server Express para el MuServer.
REM  Doble clic en este archivo. El script de PowerShell pedira permisos de
REM  Administrador (UAC) y abrira una ventana elevada con la instalacion.
REM ============================================================================
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar-sql-express.ps1"
echo.
echo (La instalacion continua en la ventana elevada que se acaba de abrir.)
pause
