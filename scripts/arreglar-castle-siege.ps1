<#
.SYNOPSIS
  Corrige las fechas de Castle Siege en la base MuOnline.

.DESCRIPTION
  El GameServerCS se cierra con "CASTLE SIEGE DATA SETTING FAILED [0x81]"
  cuando la fecha de fin del asedio (SIEGE_END_DATE) ya paso.

  Este script reescribe el ciclo actual:
    SIEGE_START_DATE = ultimo domingo
    SIEGE_END_DATE   = proximo domingo
  y reinicia el GameServerCS si estaba corriendo.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\arreglar-castle-siege.ps1
#>
param(
    [string] $Instance = ".\SQLEXPRESS",
    [string] $Database = "MuOnline"
)

$ErrorActionPreference = "Stop"
$sqlcmd = "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"
if (-not (Test-Path $sqlcmd)) { throw "No se encontro sqlcmd en: $sqlcmd" }

# --- Calcular el ciclo actual (domingo a domingo) ---
$today    = Get-Date
$dow      = [int]$today.DayOfWeek        # Domingo = 0
$lastSun  = $today.AddDays(-$dow)
$nextSun  = $lastSun.AddDays(7)

$startStr = $lastSun.ToString("yyyy-MM-dd") + " 00:00:00"
$endStr   = $nextSun.ToString("yyyy-MM-dd") + " 00:00:00"

Write-Host "=== Corrigiendo fechas de Castle Siege ===" -ForegroundColor Cyan
Write-Host ("  Hoy            : {0}" -f $today.ToString("yyyy-MM-dd (dddd)"))
Write-Host ("  SIEGE_START    : {0}" -f $startStr) -ForegroundColor Green
Write-Host ("  SIEGE_END      : {0}" -f $endStr) -ForegroundColor Green

$sql = @"
UPDATE MuCastle_DATA
SET SIEGE_START_DATE = '$startStr',
    SIEGE_END_DATE   = '$endStr',
    SIEGE_ENDED      = 0,
    SIEGE_GUILDLIST_SETTED = 0
WHERE MAP_SVR_GROUP = 0;
"@

$tmp = Join-Path $env:TEMP "fix-castle-siege.sql"
Set-Content -Path $tmp -Value $sql -Encoding UTF8
& $sqlcmd -S $Instance -E -d $Database -f 65001 -i $tmp | Out-Null

Write-Host "`n--- Estado actual ---" -ForegroundColor Cyan
& $sqlcmd -S $Instance -E -d $Database -W -s "|" -Q "SET NOCOUNT ON; SELECT MAP_SVR_GROUP, SIEGE_START_DATE, SIEGE_END_DATE, SIEGE_ENDED FROM MuCastle_DATA"

# --- Reiniciar GameServerCS si estaba corriendo ---
$cs = Get-Process -Name GameServerCS -ErrorAction SilentlyContinue
if ($cs) {
    Write-Host "`nReiniciando GameServerCS..." -ForegroundColor Yellow
    $cs | Stop-Process -Force
    Start-Sleep -Seconds 2
    $dir = Join-Path (Split-Path $PSScriptRoot -Parent) "MuServer\GameServerCS"
    Start-Process -FilePath (Join-Path $dir "GameServerCS.exe") -WorkingDirectory $dir
    Start-Sleep -Seconds 8
    $c = Get-NetTCPConnection -LocalPort 55920 -State Listen -ErrorAction SilentlyContinue
    if ($c) { Write-Host "  GameServerCS OK - LISTEN 55920" -ForegroundColor Green }
    else    { Write-Host "  GameServerCS NO escucha - revisar LOG" -ForegroundColor Red }
} else {
    Write-Host "`nGameServerCS no estaba corriendo. Arrancalo con INICIAR-SERVIDOR.cmd." -ForegroundColor DarkGray
}

Write-Host "`nListo." -ForegroundColor Cyan
