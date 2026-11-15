@echo off
cd /d "%~dp0"
py "Editor-Config-Servidor.py" 2>nul || python "Editor-Config-Servidor.py"
if errorlevel 1 (
  echo.
  echo No se pudo iniciar Python. Verifica que Python este instalado.
  pause
)
