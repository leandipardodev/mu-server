# comparar-cliente-original.ps1
# Compara los archivos de terreno del cliente (EncTerrain*.att/.map/.obj y luces)
# contra el ZIP original del repack, para detectar ediciones o corrupciones.
#
# Uso: .\comparar-cliente-original.ps1 [-Zip "C:\...\Client-1.02.44.zip"] [-Cliente "C:\...\Cliente"]

param(
    [string]$Zip = "C:\Users\leand\Downloads\Client-1.02.44.zip",
    [string]$Cliente = "C:\proyectos\servidor mu\Cliente"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-StreamHash($stream) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha.ComputeHash($stream)
    return ([BitConverter]::ToString($hash) -replace '-', '')
}
function Get-FileHashLocal($path) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $fs = [System.IO.File]::OpenRead($path)
    try { $hash = $sha.ComputeHash($fs) } finally { $fs.Close() }
    return ([BitConverter]::ToString($hash) -replace '-', '')
}

$archive = [System.IO.Compression.ZipFile]::OpenRead($Zip)
$patron = '(?i)Data/(World\d+)/(EncTerrain[^/]*\.(att|map|obj)|Terrain[^/]*\.(att|map|obj)|TerrainLight\.[^/]+|TerrainHeight\.[^/]+)$'

"{0,-46} {1,-10} {2,-10} {3}" -f "Archivo", "En ZIP", "En disco", "Estado"
"-" * 90

$faltan = 0; $distintos = 0; $iguales = 0
foreach ($e in ($archive.Entries | Where-Object { $_.FullName -match $patron })) {
    $rel = $e.FullName -replace '/', '\'
    $local = Join-Path $Cliente $rel
    $enZip = $e.Length
    if (-not (Test-Path $local)) {
        "  {0,-44} {1,-10:N0} {2,-10} {3}" -f $rel, $enZip, "-", "FALTA en disco"
        $faltan++
        continue
    }
    $enDisco = (Get-Item $local).Length
    if ($enDisco -ne $enZip) {
        "  {0,-44} {1,-10:N0} {2,-10:N0} {3}" -f $rel, $enZip, $enDisco, "TAMANO DISTINTO"
        $distintos++
        continue
    }
    $s = $e.Open()
    try { $h1 = Get-StreamHash $s } finally { $s.Close() }
    $h2 = Get-FileHashLocal $local
    if ($h1 -ne $h2) {
        "  {0,-44} {1,-10:N0} {2,-10:N0} {3}" -f $rel, $enZip, $enDisco, "CONTENIDO DISTINTO"
        $distintos++
    } else { $iguales++ }
}
$archive.Dispose()

""
"Resumen: $iguales iguales, $distintos distintos, $faltan faltantes."
