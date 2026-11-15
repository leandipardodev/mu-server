<#
.SYNOPSIS
  Arranca todos los componentes del servidor MuEmu 1.02r en el orden correcto.
#>
param(
    [string] $MuServer = (Join-Path (Split-Path $PSScriptRoot -Parent) "MuServer")
)

$ErrorActionPreference = "Continue"

$components = @(
    @{ Name = "ConnectServer"; Dir = "ConnectServer"; Exe = "ConnectServer.exe"; Port = 44405 },
    @{ Name = "JoinServer";    Dir = "JoinServer";    Exe = "JoinServer.exe";    Port = 55970 },
    @{ Name = "DataServer";    Dir = "DataServer";    Exe = "DataServer.exe";    Port = 55960 },
    @{ Name = "GameServer";    Dir = "GameServer";    Exe = "GameServer.exe";    Port = 55901 },
    @{ Name = "GameServerCS";  Dir = "GameServerCS";  Exe = "GameServerCS.exe";  Port = 55920 },
    @{ Name = "MHPServer";     Dir = "MHPServer";     Exe = "MHPServer.exe";     Port = 55999 }
)

$logDir = Join-Path $MuServer "_logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Write-Host "=== Iniciando servidor MU (MuEmu 1.02r) ===" -ForegroundColor Cyan

foreach ($c in $components) {
    $dir = Join-Path $MuServer $c.Dir
    $exe = Join-Path $dir $c.Exe
    if (-not (Test-Path $exe)) { Write-Host ("  [ERROR] no existe {0}" -f $exe) -ForegroundColor Red; continue }

    $procName = $c.Exe -replace '\.exe$', ''
    $existing = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host ("  [SKIP]  {0} ya esta corriendo (PID {1})" -f $c.Name, (($existing | ForEach-Object Id) -join ",")) -ForegroundColor Yellow
        continue
    }

    $out = Join-Path $logDir ($c.Name + ".out.txt")
    $err = Join-Path $logDir ($c.Name + ".err.txt")
    $p = Start-Process -FilePath $exe -WorkingDirectory $dir -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
    Write-Host ("  [OK]    {0} -> PID {1}" -f $c.Name, $p.Id) -ForegroundColor Green
    Start-Sleep -Seconds 2
}

Start-Sleep -Seconds 4
Write-Host "`n=== Estado de puertos ===" -ForegroundColor Cyan
foreach ($c in $components) {
    $conn = Get-NetTCPConnection -LocalPort $c.Port -State Listen -ErrorAction SilentlyContinue
    if ($conn) { Write-Host ("  {0,-14} {1,5}  LISTEN  (PID {2})" -f $c.Name, $c.Port, $conn[0].OwningProcess) -ForegroundColor Green }
    else       { Write-Host ("  {0,-14} {1,5}  ----    (NO escucha)" -f $c.Name, $c.Port) -ForegroundColor Red }
}
Write-Host "`nServidor iniciado. Ejecuta DETENER-SERVIDOR.cmd para apagarlo." -ForegroundColor Cyan
