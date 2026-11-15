<#
.SYNOPSIS
  Detiene todos los componentes del servidor MuEmu 1.02r.
#>
$names = "ConnectServer", "JoinServer", "DataServer", "GameServer", "GameServerCS", "MHPServer"
Write-Host "=== Deteniendo servidor MU ===" -ForegroundColor Cyan
foreach ($n in $names) {
    $procs = Get-Process -Name $n -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force
        Write-Host ("  [OK] {0} detenido (PID {1})" -f $n, (($procs | ForEach-Object Id) -join ",")) -ForegroundColor Green
    } else {
        Write-Host ("  [--] {0} no estaba corriendo" -f $n) -ForegroundColor DarkGray
    }
}
Write-Host "Servidor detenido." -ForegroundColor Cyan
