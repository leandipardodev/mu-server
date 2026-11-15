@echo off
cd /d "%~dp0"
py "Editor-Spots.py" 2>nul || python "Editor-Spots.py"
if errorlevel 1 (
  echo.
  echo No se pudo iniciar Python. Verifica que Python este instalado.
  pause
)
