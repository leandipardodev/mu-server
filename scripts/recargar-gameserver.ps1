<#
.SYNOPSIS
  Reinicia SOLO el GameServer (y opcionalmente el GameServerCS) para recargar
  la lista de administradores (MuServer\Data\Util\GameMaster.txt) sin apagar
  todo el servidor.

.NOTES
  Requiere permisos de administrador (los procesos del servidor corren elevados).
  Usar -IncluirCS si tambien queres recargar el GameServer de Castle Siege.
#>
param(
    [string] $MuServer = (Join-Path (Split-Path $PSScriptRoot -Parent) "MuServer"),
    [switch] $IncluirCS
)

$ErrorActionPreference = "Continue"

$targets = @(
    @{ Name = "GameServer"; Dir = "GameServer"; Exe = "GameServer.exe"; Port = 55901 }
)
if ($IncluirCS) {
    $targets += @{ Name = "GameServerCS"; Dir = "GameServerCS"; Exe = "GameServerCS.exe"; Port = 55920 }
}

$logDir = Join-Path $MuServer "_logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Write-Host "=== Reiniciando GameServer (recargar lista de GMs) ===" -ForegroundColor Cyan

# 1) Detener
foreach ($c in $targets) {
    $procName = $c.Exe -replace '\.exe$', ''
    $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force
        Write-Host ("  [OK] {0} detenido (PID {1})" -f $c.Name, (($procs | ForEach-Object Id) -join ",")) -ForegroundColor Green
    } else {
        Write-Host ("  [--] {0} no estaba corriendo" -f $c.Name) -ForegroundColor DarkGray
    }
    # esperar a que se libere el puerto
    for ($i = 0; $i -lt 20; $i++) {
        $conn = Get-NetTCPConnection -LocalPort $c.Port -State Listen -ErrorAction SilentlyContinue
        if (-not $conn) { break }
        Start-Sleep -Milliseconds 500
    }
}

Start-Sleep -Seconds 2

# 2) Volver a arrancar
foreach ($c in $targets) {
    $dir = Join-Path $MuServer $c.Dir
    $exe = Join-Path $dir $c.Exe
    if (-not (Test-Path $exe)) { Write-Host ("  [ERROR] no existe {0}" -f $exe) -ForegroundColor Red; continue }

    $out = Join-Path $logDir ($c.Name + ".out.txt")
    $err = Join-Path $logDir ($c.Name + ".err.txt")
    $p = Start-Process -FilePath $exe -WorkingDirectory $dir -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
    Write-Host ("  [OK] {0} iniciado -> PID {1}" -f $c.Name, $p.Id) -ForegroundColor Green
    Start-Sleep -Seconds 4
}

Write-Host "`n=== Estado de puertos ===" -ForegroundColor Cyan
foreach ($c in $targets) {
    $conn = Get-NetTCPConnection -LocalPort $c.Port -State Listen -ErrorAction SilentlyContinue
    if ($conn) { Write-Host ("  {0,-14} {1,5}  LISTEN" -f $c.Name, $c.Port) -ForegroundColor Green }
    else       { Write-Host ("  {0,-14} {1,5}  ----    (NO escucha)" -f $c.Name, $c.Port) -ForegroundColor Red }
}

Write-Host "`nGameServer reiniciado. La lista de GMs (Data\Util\GameMaster.txt) quedo recargada." -ForegroundColor Cyan
Write-Host "Nota: si habia jugadores conectados, se desconectan y pueden reconectar." -ForegroundColor DarkGray
