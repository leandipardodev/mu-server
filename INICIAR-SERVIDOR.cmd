@echo off
title Iniciar Servidor MU
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\iniciar-servidor.ps1"
echo.
pause
