#Requires -Version 5.1
<#
.SYNOPSIS
  Muestra el estado de los puertos típicos de un servidor MU 1.02N.
#>
[CmdletBinding()]
param(
    [int[]]$Ports = @(44405, 55901, 55919, 55920, 55921, 55970, 55960, 55962, 1433)
)

Write-Host "`nEstado de puertos MU Online 1.02N" -ForegroundColor Cyan
Write-Host ("{0,-8} {1,-12} {2,-10} {3}" -f "PUERTO", "ESTADO", "PID", "PROCESO")
Write-Host ("-" * 60)

foreach ($port in $Ports) {
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
            Select-Object -First 1

    if ($conn) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        Write-Host ("{0,-8} {1,-12} {2,-10} {3}" -f $port, "ESCUCHANDO", $conn.OwningProcess, $proc.ProcessName) -ForegroundColor Green
    } else {
        Write-Host ("{0,-8} {1,-12} {2,-10} {3}" -f $port, "libre", "-", "-") -ForegroundColor DarkGray
    }
}

Write-Host "`nNota: los puertos internos (55960, 55962, 55970) NO deben exponerse a internet." -ForegroundColor Yellow
Write-Host "Probar conectividad externa: Test-NetConnection -ComputerName IP -Port 44405`n" -ForegroundColor Yellow
