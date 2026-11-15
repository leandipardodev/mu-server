@echo off
title Recargar GameServer (lista de GMs)
echo Este script reinicia SOLO el GameServer para recargar la lista de administradores.
echo Debe ejecutarse como Administrador.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\recargar-gameserver.ps1" %*
echo.
pause
