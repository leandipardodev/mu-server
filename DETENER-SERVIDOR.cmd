@echo off
title Detener Servidor MU
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\detener-servidor.ps1"
echo.
pause
