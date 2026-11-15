#Requires -Version 5.1
<#
.SYNOPSIS
  Restaura las bases de datos de MU Online (MuOnline, Me_MuOnline, Ranking)
  desde archivos .bak, detectando automáticamente los nombres lógicos.

.EJEMPLO
  .\restaurar-bases.ps1 -BakDir "..\sql\bak" -DataDir "C:\MuServerDB"

.EJEMPLO (con autenticación SQL)
  .\restaurar-bases.ps1 -SqlUser muuser -SqlPassword "TuPass"
#>
[CmdletBinding()]
param(
    [string]   $ServerInstance = ".\SQLEXPRESS",
    [string]   $BakDir         = "",
    [string]   $DataDir        = "C:\MuServerDB",
    [string]   $SqlUser        = "",
    [string]   $SqlPassword    = "",
    [string[]] $Databases      = @("MuOnline", "Me_MuOnline", "Ranking")
)

$ErrorActionPreference = "Stop"

# $PSScriptRoot no está disponible dentro del bloque param con comment-based help,
# por eso se resuelve acá.
if (-not $BakDir) { $BakDir = Join-Path $PSScriptRoot "..\sql\bak" }

if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Error "No se encontró 'sqlcmd'. Instalá las SQL Server Command Line Utilities o SSMS."
    exit 1
}

if (-not (Test-Path $BakDir)) {
    Write-Error "No existe la carpeta de backups: $BakDir"
    exit 1
}

if (-not (Test-Path $DataDir)) {
    Write-Host "Creando carpeta de datos: $DataDir"
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

function Invoke-Sql {
    param([string]$Query)
    $common = @("-S", $ServerInstance, "-Q", $Query, "-s", "|", "-W", "-h", "-1")
    if ($SqlUser) { $common += @("-U", $SqlUser, "-P", $SqlPassword) }
    else          { $common += "-E" }
    return & sqlcmd @common
}

function Restore-Backup {
    param([string]$DbName, [string]$BakPath)

    Write-Host "`n=== Restaurando '$DbName' desde '$BakPath' ===" -ForegroundColor Cyan

    $listQuery = "SET NOCOUNT ON; RESTORE FILELISTONLY FROM DISK = N'$BakPath'"
    $rows = Invoke-Sql -Query $listQuery

    $moves = @()
    foreach ($row in $rows) {
        if ([string]::IsNullOrWhiteSpace($row)) { continue }
        $cols = $row -split "\|"
        if ($cols.Count -lt 3) { continue }
        $logical = $cols[0].Trim()
        $type    = $cols[2].Trim().ToUpper()
        if ($logical -eq "" -or $type -notin @("D", "L")) { continue }

        $ext  = if ($type -eq "D") { ".mdf" } else { ".ldf" }
        $dest = Join-Path $DataDir ($logical + $ext)
        $moves += "MOVE N'$logical' TO N'$dest'"
    }

    if ($moves.Count -eq 0) {
        Write-Warning "No se pudieron leer los archivos lógicos de $BakPath. Revisá el .bak."
        return
    }

    $moveClause = $moves -join ", "
    $restoreQuery = "SET NOCOUNT ON; RESTORE DATABASE [$DbName] FROM DISK = N'$BakPath' WITH $moveClause, REPLACE, RECOVERY"
    Invoke-Sql -Query $restoreQuery | Out-Null

    Write-Host "OK: $DbName restaurada." -ForegroundColor Green
}

$found = 0
foreach ($db in $Databases) {
    $bak = Join-Path $BakDir "$db.bak"
    if (-not (Test-Path $bak)) {
        $bak = (Get-ChildItem -Path $BakDir -Filter "*.bak" |
                Where-Object { $_.BaseName -like "*$db*" } |
                Select-Object -First 1 -ExpandProperty FullName)
    }
    if ($bak -and (Test-Path $bak)) {
        Restore-Backup -DbName $db -BakPath $bak
        $found++
    } else {
        Write-Warning "No encontré un .bak para '$db' en $BakDir"
    }
}

if ($found -eq 0) {
    Write-Warning "No se restauró ninguna base. Revisá que los .bak estén en: $BakDir"
} else {
    Write-Host "`nListo. Verificá con:" -ForegroundColor Yellow
    Write-Host "  sqlcmd -S `"$ServerInstance`" -Q `"SELECT name FROM sys.databases`""
}
