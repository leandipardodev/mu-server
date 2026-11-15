# restaurar-world1-original.ps1
# Restaura Cliente\Data\World1 (Lorencia) exactamente como venia en el ZIP original del repack.
#
# - Copia los archivos del ZIP que faltan o que cambiaron.
# - Mueve a una carpeta de respaldo los archivos que NO estan en el ZIP (basura del editor).
# - Guarda copia de lo que habia antes en World1\_bak_edicion_usuario\
#
# Uso: .\restaurar-world1-original.ps1 [-QueHacer comparar|restaurar]

param(
    [string]$Zip = "C:\Users\leand\Downloads\Client-1.02.44.zip",
    [string]$Cliente = "C:\proyectos\servidor mu\Cliente",
    [ValidateSet('comparar','restaurar')][string]$QueHacer = 'restaurar'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$world = "World1"
$destino = Join-Path $Cliente "Data\$world"
$backup  = Join-Path $destino "_bak_edicion_usuario"

$archive = [System.IO.Compression.ZipFile]::OpenRead($Zip)
$entradas = $archive.Entries | Where-Object { $_.FullName -match "(?i)^Data/$world/" -and $_.Length -gt 0 }

function Get-StreamHash($stream) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return ([BitConverter]::ToString($sha.ComputeHash($stream)) -replace '-', '')
}
function Get-FileHashLocal($path) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $fs = [System.IO.File]::OpenRead($path)
    try { $h = $sha.ComputeHash($fs) } finally { $fs.Close() }
    return ([BitConverter]::ToString($h) -replace '-', '')
}

$nombresZip = @{}
$cambiados = @(); $faltantes = @(); $iguales = 0

foreach ($e in $entradas) {
    $nombre = [System.IO.Path]::GetFileName($e.FullName)
    $nombresZip[$nombre.ToLower()] = $true
    $local = Join-Path $destino $nombre
    $s = $e.Open()
    try { $hz = Get-StreamHash $s } finally { $s.Close() }
    if (-not (Test-Path $local)) { $faltantes += $nombre; continue }
    if ((Get-FileHashLocal $local) -eq $hz) { $iguales++ }
    else { $cambiados += [pscustomobject]@{ Nombre = $nombre; Zip = $e; HashZip = $hz } }
}

$sobrantes = Get-ChildItem $destino -File | Where-Object { -not $nombresZip.ContainsKey($_.Name.ToLower()) }

"=== Comparacion de $world contra el ZIP original ==="
"  iguales           : $iguales"
"  cambiados         : $($cambiados.Count)  -> " + (($cambiados | ForEach-Object { $_.Nombre }) -join ', ')
"  faltantes en disco: $($faltantes.Count)  -> " + ($faltantes -join ', ')
"  sobrantes (basura): $($sobrantes.Count)  -> " + (($sobrantes | ForEach-Object { $_.Name }) -join ', ')
""

if ($QueHacer -eq 'comparar') { $archive.Dispose(); return }

New-Item -ItemType Directory -Path $backup -Force | Out-Null
$marca = Get-Date -Format 'yyyyMMdd-HHmmss'

# 1) respaldar TODO lo que hay ahora en World1
foreach ($f in (Get-ChildItem $destino -File)) {
    Copy-Item $f.FullName (Join-Path $backup ($f.Name + ".$marca.bak")) -Force
}

# 2) restaurar cambiados y faltantes desde el ZIP
foreach ($c in $cambiados) {
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($c.Zip, (Join-Path $destino $c.Nombre), $true)
}
foreach ($nombre in $faltantes) {
    $e = $entradas | Where-Object { [System.IO.Path]::GetFileName($_.FullName) -eq $nombre } | Select-Object -First 1
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, (Join-Path $destino $nombre), $true)
}
$archive.Dispose()

# 3) mover sobrantes a una subcarpeta aparte
$artefactos = Join-Path $destino "_artefactos_editor"
if ($sobrantes) {
    New-Item -ItemType Directory -Path $artefactos -Force | Out-Null
    foreach ($f in $sobrantes) { Move-Item $f.FullName (Join-Path $artefactos $f.Name) -Force }
}

"=== Restaurado ==="
"  copia del estado anterior : $backup"
if ($sobrantes) { "  archivos del editor movidos a: $artefactos" }
""
"=== Archivos de World1 ahora ==="
Get-ChildItem $destino -File | Sort-Object Name | ForEach-Object { "  {0,-26} {1,10:N0} b  {2}" -f $_.Name, $_.Length, $_.LastWriteTime }
