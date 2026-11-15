#Requires -Version 5.1
# (El chequeo de Administrador se hace más abajo y el script se auto-eleva pidiendo UAC.)
<#
.SYNOPSIS
  Instala y configura SQL Server Express para el MuServer, todo automático.

.DESCRIPTION
  - Descarga e instala SQL Server Express (2019 o 2022) en modo silencioso.
  - Habilita TCP/IP en el puerto 1433 (estático).
  - Activa autenticación mixta (SQL + Windows) y pide la clave inicial de 'sa'.
  - Instala los Visual C++ Redistributable que necesita MuEmu.
  - Instala SQL Server Management Studio (SSMS).
  - Verifica la conexión al final.

  Si no se ejecuta como Administrador, se vuelve a lanzar solo pidiendo UAC.

.EJEMPLO
  # Recomendado: doble clic en instalar-sql-express.cmd (se auto-eleva solo).
  .\instalar-sql-express.ps1
  .\instalar-sql-express.ps1 -SqlVersion 2022
  .\instalar-sql-express.ps1 -SkipSSMS -SkipVCRedist
#>
[CmdletBinding()]
param(
    [ValidateSet("2019", "2022")]
    [string] $SqlVersion  = "2019",
    [string] $InstanceName = "SQLEXPRESS",
    [int]    $TcpPort      = 1433,

    [switch] $SkipSSMS,
    [switch] $SkipVCRedist
)

# ---------------------------------------------------------------- 0. Auto-elevación
# Si no estamos como Administrador, relanzamos el script pidiendo UAC (una sola vez).
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Se necesitan permisos de Administrador. Abriendo una ventana elevada (aceptá el UAC)..." -ForegroundColor Yellow
    $relaunchArgs = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-NoExit", "-File", "`"$PSCommandPath`"",
        "-SqlVersion", $SqlVersion,
        "-InstanceName", "`"$InstanceName`"",
        "-TcpPort", $TcpPort
    )
    if ($SkipSSMS)     { $relaunchArgs += "-SkipSSMS" }
    if ($SkipVCRedist) { $relaunchArgs += "-SkipVCRedist" }
    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $relaunchArgs
    return
}

$ErrorActionPreference = "Stop"
$log = Join-Path $env:TEMP "mu-sql-install.log"

function Log([string]$msg, [string]$color = "Gray") {
    $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
    Write-Host $line -ForegroundColor $color
    Add-Content -Path $log -Value $line
}

Log "=== Instalación de SQL Server Express para MuServer ===" "Cyan"
Log "Versión: $SqlVersion | Instancia: $InstanceName | Puerto: $TcpPort"

# ---------------------------------------------------------------- 1. Descargar
# Forzar TLS 1.2 (PowerShell 5.1 a veces negocia TLS 1.0 y Microsoft lo rechaza)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Instalador "Core" directo (es el Setup.exe real, acepta todos los parámetros).
# El bootstrapper SQL20xx-SSEI-Expr.exe NO sirve para instalación desatendida.
$urls = @{
    "2019" = "https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLEXPR_x64_ENU.exe"  # Express Core ~249 MB
    "2022" = "https://download.microsoft.com/download/3/8/d/38de7036-2433-4207-8eae-06e247e17b25/SQLEXPR_x64_ENU.exe"  # Express Core ~266 MB
}
$installer = Join-Path $env:TEMP "SQL${SqlVersion}-SQLEXPR_x64_ENU.exe"

$serviceName = "MSSQL`$$InstanceName"
$alreadyInstalled = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($alreadyInstalled) {
    Log "La instancia '$InstanceName' ya existe. Se saltea la instalación." "Yellow"
} else {
    # Limpiar descargas viejas (el bootstrapper SSEI ya no se usa) e incompletas
    $staleSsei = Join-Path $env:TEMP "SQL${SqlVersion}-SSEI-Expr.exe"
    if (Test-Path $staleSsei) { Remove-Item $staleSsei -Force -ErrorAction SilentlyContinue }
    if ((Test-Path $installer) -and ((Get-Item $installer).Length -lt 100MB)) {
        Log "Descartando descarga previa inválida o incompleta." "Yellow"
        Remove-Item $installer -Force
    }

    if (-not (Test-Path $installer)) {
        Log "Descargando el instalador de SQL Server $SqlVersion (~250 MB)..." "Cyan"
        try {
            $ProgressPreference = "SilentlyContinue"   # acelera mucho Invoke-WebRequest
            Invoke-WebRequest -Uri $urls[$SqlVersion] -OutFile $installer -UseBasicParsing
        } catch {
            Log "Falló la descarga automática: $($_.Exception.Message)" "Red"
            Log "Descargalo a mano desde: https://www.microsoft.com/en-us/sql-server/sql-server-downloads" "Yellow"
            Log "y guardalo como: $installer" "Yellow"
            throw
        }
    }

    $size = (Get-Item $installer).Length
    Log "Instalador: $installer ($([math]::Round($size/1MB,2)) MB)"
    if ($size -lt 100MB) { throw "El archivo descargado parece inválido ($size bytes)." }

    Log "Instalando (puede tardar 10-30 min)..." "Cyan"
    $saSecret = Read-Host "Elegí una contraseña única para sa (mínimo 16 caracteres)" -AsSecureString
    try {
        if ($saSecret.Length -lt 16) { throw "La contraseña de sa debe tener al menos 16 caracteres." }
        $secretPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($saSecret)
        try {
            $saPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer)
        } finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer)
        }

        # Setup requires SAPWD as a process argument; never write it to logs.
        $argString = "/Q /ACTION=Install /FEATURES=SQLEngine /INSTANCENAME=$InstanceName " +
                     "/SQLSVCACCOUNT=`"NT AUTHORITY\NETWORK SERVICE`" " +
                     "/SQLSYSADMINACCOUNTS=`"BUILTIN\Administrators`" `"$env:USERDOMAIN\$env:USERNAME`" " +
                     "/SECURITYMODE=SQL /SAPWD=`"$saPassword`" /TCPENABLED=1 " +
                     "/IACCEPTSQLSERVERLICENSETERMS /UpdateEnabled=False"
        Log "Ejecutando el instalador (argumentos omitidos del log)..." "Cyan"
        $proc = Start-Process -FilePath $installer -ArgumentList $argString -Wait -PassThru
    } finally {
        $saPassword = $null
        $argString = $null
        $saSecret.Dispose()
    }
    Log "El instalador terminó con código: $($proc.ExitCode)"

    # El auto-extractor a veces devuelve 0 aunque Setup falle: verificamos el servicio real.
    Start-Sleep -Seconds 5
    if (-not (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)) {
        throw "La instalación no creó el servicio '$serviceName' (código $($proc.ExitCode)). Revisá $log y los logs en 'C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log'."
    }
    if ($proc.ExitCode -notin @(0, 3010)) {
        Log "El instalador devolvió el código $($proc.ExitCode), pero el servicio existe. Continuo." "Yellow"
    }
}

# ---------------------------------------------------------------- 2. Configurar red
Log "Configurando TCP/IP en el puerto $TcpPort..." "Cyan"
$instanceKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
$instanceId  = (Get-ItemProperty -Path $instanceKey -Name $InstanceName).$InstanceName
if (-not $instanceId) { throw "No pude determinar el ID de la instancia '$InstanceName'." }
Log "Instance ID: $instanceId"

$tcpKey   = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\MSSQLServer\SuperSocketNetLib\Tcp"
$ipAllKey = Join-Path $tcpKey "IPAll"
$serverKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\MSSQLServer"

Set-ItemProperty -Path $tcpKey    -Name Enabled          -Value 1 -Type DWord
Set-ItemProperty -Path $ipAllKey  -Name TcpPort          -Value "$TcpPort" -Type String
Set-ItemProperty -Path $ipAllKey  -Name TcpDynamicPorts  -Value "" -Type String
Set-ItemProperty -Path $serverKey -Name LoginMode        -Value 2 -Type DWord

# ---------------------------------------------------------------- 3. Reiniciar servicio
Log "Reiniciando el servicio '$serviceName'..." "Cyan"
Restart-Service -Name $serviceName -Force
Start-Sleep -Seconds 5
Log "Servicio: $((Get-Service $serviceName).Status)"

# ---------------------------------------------------------------- 4. Redistributables
if (-not $SkipVCRedist) {
    Log "Instalando Visual C++ Redistributable (x64 servidor / x86 cliente)..." "Cyan"
    foreach ($id in @("Microsoft.VCRedist.2015+.x64", "Microsoft.VCRedist.2010.x86")) {
        Log "  winget install $id"
        winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements 2>&1 |
            ForEach-Object { Add-Content -Path $log -Value $_ }
    }
}

# ---------------------------------------------------------------- 5. SSMS
if (-not $SkipSSMS) {
    Log "Instalando SQL Server Management Studio (SSMS)..." "Cyan"
    winget install --id Microsoft.SQLServerManagementStudio.22 -e --silent `
        --accept-package-agreements --accept-source-agreements 2>&1 |
        ForEach-Object { Add-Content -Path $log -Value $_ }
}

# ---------------------------------------------------------------- 6. Verificar
Log "Verificando la conexión..." "Cyan"
$sqlcmd = (Get-Command sqlcmd -ErrorAction SilentlyContinue).Source
if (-not $sqlcmd) {
    $candidates = Get-ChildItem "C:\Program Files\Microsoft SQL Server" -Recurse -Filter sqlcmd.exe -ErrorAction SilentlyContinue |
                  Select-Object -First 1 -ExpandProperty FullName
    $sqlcmd = $candidates
}

if ($sqlcmd) {
    try {
        $result = & $sqlcmd -S ".\$InstanceName" -E -h -1 -W -Q "SET NOCOUNT ON; SELECT @@VERSION;"
        Log "Conexión OK. Versión:" "Green"
        $result | ForEach-Object { Log "  $_" }
    } catch {
        Log "No pude verificar con sqlcmd: $_" "Yellow"
    }
} else {
    Log "sqlcmd no está en el PATH todavía. Verificá manualmente desde SSMS." "Yellow"
}

Log "" 
Log "=== LISTO ===" "Green"
Log "Instancia : .\$InstanceName"
Log "Administración: autenticación de Windows"
Log "Puerto    : $TcpPort"
Log ""
Log "No reutilices ni guardes la contraseña de sa en archivos del proyecto." "Yellow"
Log "Log completo: $log"
