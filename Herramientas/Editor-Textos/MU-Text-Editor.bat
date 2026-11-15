@echo off
cd /d "%~dp0"
py "MU-Text-Editor.py" 2>nul || python "MU-Text-Editor.py"
if errorlevel 1 (
  echo.
  echo No se pudo iniciar Python. Verifica que Python este instalado.
  pause
)
