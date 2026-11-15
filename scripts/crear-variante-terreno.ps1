# crear-variante-terreno.ps1
# Crea los archivos de una "variante" de terreno para un mundo del cliente.
#
# Este cliente (1.02.44) usa, para algunos mapas de evento (Crywolf, Kanturu 3,
# Valley of Loren/CS...), un segundo juego de archivos de terreno con el nombre
#   EncTerrain<world><variante>.att / .map / .obj
# Por ejemplo: World40 tiene EncTerrain401.att/.map/.obj (variante 1)
#              World31 tiene EncTerrain312.att        (variante 2)
#              World35 (Crywolf) NO los trae en el repack -> "file not found"
#
# El byte 1 de la cabecera de la variante tambien es el numero de mundo.
# Este script copia los archivos base (EncTerrain<world>.*) a la variante que falte.
#
# Uso:
#   .\crear-variante-terreno.ps1 -World 35 -Variante 1
#   .\crear-variante-terreno.ps1 -World 35 -Variante 1 -QueHacer listar

param(
    [Parameter(Mandatory = $true)][int]$World,
    [Parameter(Mandatory = $true)][int]$Variante,
    [string]$Root = "C:\proyectos\servidor mu\Cliente\Data",
    [ValidateSet('listar','crear')][string]$QueHacer = 'listar'
)

$ErrorActionPreference = 'Stop'

$dir = Join-Path $Root "World$World"
if (-not (Test-Path $dir)) { throw "No existe la carpeta $dir" }

"{0,-40} {1,10} {2}" -f "Archivo base / variante", "Tamano", "Estado"
"-" * 80

foreach ($ext in @('att','map','obj')) {
    $base = Join-Path $dir "EncTerrain$World.$ext"
    $dest = Join-Path $dir "EncTerrain$World$Variante.$ext"

    if (-not (Test-Path $base)) { continue }

    if (Test-Path $dest) {
        "{0,-40} {1,10:N0} {2}" -f "EncTerrain$World$Variante.$ext", (Get-Item $dest).Length, "ya existe"
        continue
    }

    if ($QueHacer -eq 'listar') {
        "{0,-40} {1,10:N0} {2}" -f "EncTerrain$World$Variante.$ext", 0, "FALTA (se copiaria de EncTerrain$World.$ext)"
        continue
    }

    Copy-Item $base $dest -Force
    "{0,-40} {1,10:N0} {2}" -f "EncTerrain$World$Variante.$ext", (Get-Item $dest).Length, "creado (copia del base)"
}
