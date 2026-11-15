# Genera el valor cifrado que MuMaker espera en Config.ini (PassWord=...)
# Uso:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\mumaker-password.ps1 -Password "MuMaker#2026!"
#
# MuMaker cifra la contraseña con una función interna (clase "ab", método "c").
# Este script carga el propio MuMaker.exe por reflexión y usa esa misma función,
# así el valor generado es siempre compatible.

param(
    [Parameter(Mandatory = $true)]
    [string] $Password,

    [string] $MuMakerExe = "C:\proyectos\servidor mu\MuServer\Tools\MuMaker 1.12\MuMaker.exe",

    [switch] $EscribirEnConfig
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $MuMakerExe)) {
    Write-Host "No se encontro MuMaker.exe en: $MuMakerExe" -ForegroundColor Red
    exit 1
}

$dir = Split-Path $MuMakerExe

# Permite que MuMaker cargue sus DLLs vecinas (Interop.JRO.dll, etc.)
[System.AppDomain]::CurrentDomain.add_AssemblyResolve({
    param($sender, $e)
    $name = ($e.Name -split ',')[0] + '.dll'
    $path = Join-Path $dir $name
    if (Test-Path $path) { return [System.Reflection.Assembly]::LoadFrom($path) }
    return $null
})

$asm = [System.Reflection.Assembly]::LoadFile($MuMakerExe)
$flags = [System.Reflection.BindingFlags]::Public -bor `
         [System.Reflection.BindingFlags]::NonPublic -bor `
         [System.Reflection.BindingFlags]::Static

$type = $asm.GetType('ab')
if (-not $type) {
    Write-Host "No se encontro la clase 'ab' dentro de MuMaker.exe." -ForegroundColor Red
    exit 2
}

$enc = @($type.GetMethods($flags) | Where-Object {
    $_.Name -eq 'c' -and
    $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType -eq [string] -and
    $_.ReturnType -eq [string]
})[0]

$dec = @($type.GetMethods($flags) | Where-Object {
    $_.Name -eq 'b' -and
    $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType -eq [string] -and
    $_.ReturnType -eq [string]
})[0]

if (-not $enc) {
    Write-Host "No se encontro la funcion de cifrado." -ForegroundColor Red
    exit 3
}

$cifrado = $enc.Invoke($null, @($Password))
$vuelta = if ($dec) { $dec.Invoke($null, @($cifrado)) } else { '(sin verificacion)' }

Write-Host ""
Write-Host "Contrasena         : $Password"
Write-Host "Valor para Config.ini: $cifrado" -ForegroundColor Green
Write-Host "Verificacion       : $vuelta"
Write-Host ""

if ($vuelta -ne $Password) {
    Write-Host "ADVERTENCIA: la verificacion no coincide." -ForegroundColor Yellow
}

if ($EscribirEnConfig) {
    $cfg = Join-Path $dir 'Config.ini'
    if (-not (Test-Path $cfg)) {
        Write-Host "No existe $cfg" -ForegroundColor Red
        exit 4
    }
    if (-not (Test-Path "$cfg.bak")) { Copy-Item $cfg "$cfg.bak" -Force }
    $lines = Get-Content $cfg | ForEach-Object {
        if ($_ -match '^PassWord=') { "PassWord=$cifrado" } else { $_ }
    }
    [System.IO.File]::WriteAllLines($cfg, $lines, [System.Text.Encoding]::ASCII)
    Write-Host "Config.ini actualizado ($cfg)." -ForegroundColor Green
    Write-Host "Acordate de que el login de SQL debe tener esa misma contrasena." -ForegroundColor Yellow
}
