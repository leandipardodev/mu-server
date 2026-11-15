#Requires -Version 5.1
<#
.SYNOPSIS
  Abre (o cierra) en el Firewall de Windows los puertos que necesita el servidor MU.

.DESCRIPTION
  Crea reglas de entrada para que tus amigos puedan conectarse desde internet.
  Por defecto abre:
    - TCP: 44405 (ConnectServer), 55901 (GameServer), 55919 (CS), 55920 (EventServer)
    - UDP: 55901, 55919 (tráfico de juego)

  Requiere Administrador; si no lo sos, el script se auto-eleva (pide UAC).

.EJEMPLO
  .\abrir-puertos-firewall.ps1
  .\abrir-puertos-firewall.ps1 -TcpPorts 44405,55901
  .\abrir-puertos-firewall.ps1 -Remove        # borra las reglas "MU-*"
#>
[CmdletBinding()]
param(
    [int[]] $TcpPorts = @(44405, 55901, 55919, 55920),
    [int[]] $UdpPorts = @(55901, 55919),
    [switch] $Remove
)

# --- Auto-elevación ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Se necesitan permisos de Administrador. Abriendo ventana elevada..." -ForegroundColor Yellow
    $args = @("-NoProfile","-ExecutionPolicy","Bypass","-NoExit","-File","`"$PSCommandPath`"")
    if ($Remove) { $args += "-Remove" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $args
    return
}

if ($Remove) {
    Get-NetFirewallRule -DisplayName "MU-*" -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-NetFirewallRule -Name $_.Name
        "Eliminada: $($_.DisplayName)"
    }
    "Listo. Reglas MU-* eliminadas."
    return
}

foreach ($p in $TcpPorts) {
    $name = "MU-$p-TCP"
    if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) {
        "Ya existe: $name"
    } else {
        New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol TCP `
            -LocalPort $p -Action Allow -Profile Any | Out-Null
        "Creada: $name"
    }
}

foreach ($p in $UdpPorts) {
    $name = "MU-$p-UDP"
    if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) {
        "Ya existe: $name"
    } else {
        New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol UDP `
            -LocalPort $p -Action Allow -Profile Any | Out-Null
        "Creada: $name"
    }
}

""
"Reglas actuales:"
Get-NetFirewallRule -DisplayName "MU-*" -ErrorAction SilentlyContinue |
    Select-Object DisplayName, Enabled, Direction, Action | Format-Table -AutoSize
