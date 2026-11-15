# moverequest-agregar.ps1
# Agrega (o reemplaza) una entrada del menu de transporte del cliente: Data\Local\MoveReq.bmd
#
# Formato verificado del archivo:
#   offset 0        : int32 cantidad de entradas (sin cifrar)
#   desde offset 4  : entradas de 80 bytes, cada una cifrada con XOR FC CF AB
#                     REINICIANDO el indice de la clave en cada entrada
#   entrada:
#     +0  int32  indice (el que el cliente manda al servidor; debe existir en Move.txt)
#     +4  char[32] nombre
#     +36 char[32] nombre (segunda copia)
#     +68 int32  nivel minimo
#     +72 int32  zen
#     +76 int32  nivel minimo (repetido)
#
# Uso:
#   .\moverequest-agregar.ps1 -Index 26 -Nombre "Crywolf" -Nivel 190 -Zen 14000
#   .\moverequest-agregar.ps1 -Listar

param(
    [string]$Path = "C:\proyectos\servidor mu\Cliente\Data\Local\MoveReq.bmd",
    [int]$Index = 0,
    [string]$Nombre = "",
    [int]$Nivel = 0,
    [int]$Zen = 0,
    [int]$DespuesDe = -1,
    [switch]$Listar
)

$ErrorActionPreference = 'Stop'
$BuxKey = [byte[]](0xFC,0xCF,0xAB)
$EntrySize = 80

function Leer-Entradas([byte[]]$raw) {
    $count = [BitConverter]::ToInt32($raw, 0)
    $lista = @()
    for ($e = 0; $e -lt $count; $e++) {
        $start = 4 + $e * $EntrySize
        $d = [byte[]]::new($EntrySize)
        for ($j = 0; $j -lt $EntrySize; $j++) { $d[$j] = [byte]($raw[$start + $j] -bxor $BuxKey[$j % 3]) }
        $nombre = ""
        for ($p = 4; $p -lt 36; $p++) { if ($d[$p] -ne 0) { $nombre += [char]$d[$p] } }
        $lista += [pscustomobject]@{
            Index  = [BitConverter]::ToInt32($d, 0)
            Nombre = $nombre
            Nivel  = [BitConverter]::ToInt32($d, 68)
            Zen    = [BitConverter]::ToInt32($d, 72)
            Bytes  = $d
        }
    }
    return ,$lista
}

$raw = [System.IO.File]::ReadAllBytes($Path)
$entradas = Leer-Entradas $raw

if ($Listar) {
    "{0,3} {1,-14} {2,7} {3,9}" -f "#", "Nombre", "Nivel", "Zen"
    "-" * 40
    $i = 0
    foreach ($e in $entradas) { "{0,3} {1,-14} {2,7} {3,9}" -f $e.Index, $e.Nombre, $e.Nivel, $e.Zen; $i++ }
    "Total: $($entradas.Count) entradas"
    return
}

if ($Index -le 0 -or [string]::IsNullOrWhiteSpace($Nombre)) {
    throw "Indique -Index y -Nombre (o use -Listar)."
}

# entrada nueva cifrada
$nueva = [byte[]]::new($EntrySize)
[Array]::Copy([BitConverter]::GetBytes([int]$Index), 0, $nueva, 0, 4)
$nb = [System.Text.Encoding]::ASCII.GetBytes($Nombre)
[Array]::Copy($nb, 0, $nueva, 4, [Math]::Min($nb.Length, 31))
[Array]::Copy($nb, 0, $nueva, 36, [Math]::Min($nb.Length, 31))
[Array]::Copy([BitConverter]::GetBytes([int]$Nivel), 0, $nueva, 68, 4)
[Array]::Copy([BitConverter]::GetBytes([int]$Zen), 0, $nueva, 72, 4)
[Array]::Copy([BitConverter]::GetBytes([int]$Nivel), 0, $nueva, 76, 4)

# armar la lista resultante (reemplaza si ya existe ese indice)
$resultado = New-Object System.Collections.ArrayList
$insertado = $false
$posicion = 0
foreach ($e in $entradas) {
    if ($e.Index -eq $Index) {
        # reemplaza en el mismo lugar
        [void]$resultado.Add($nueva)
        $insertado = $true
        continue
    }
    if (-not $insertado -and $DespuesDe -ge 0 -and $e.Index -eq $DespuesDe) {
        [void]$resultado.Add($e.Bytes)
        [void]$resultado.Add($nueva)
        $insertado = $true
        continue
    }
    [void]$resultado.Add($e.Bytes)
}
if (-not $insertado) { [void]$resultado.Add($nueva) }

$salida = [byte[]]::new(4 + $resultado.Count * $EntrySize)
[Array]::Copy([BitConverter]::GetBytes([int]$resultado.Count), 0, $salida, 0, 4)
for ($e = 0; $e -lt $resultado.Count; $e++) {
    $start = 4 + $e * $EntrySize
    for ($j = 0; $j -lt $EntrySize; $j++) {
        $salida[$start + $j] = [byte]($resultado[$e][$j] -bxor $BuxKey[$j % 3])
    }
}

$bak = "$Path.bak"
if (-not (Test-Path $bak)) { Copy-Item $Path $bak -Force }
[System.IO.File]::WriteAllBytes($Path, $salida)

"Escrito: $Path  ($($salida.Length) bytes, $($resultado.Count) entradas)"
""
$verif = Leer-Entradas ([System.IO.File]::ReadAllBytes($Path))
"{0,3} {1,-14} {2,7} {3,9}" -f "#", "Nombre", "Nivel", "Zen"
"-" * 40
foreach ($e in $verif) { "{0,3} {1,-14} {2,7} {3,9}" -f $e.Index, $e.Nombre, $e.Nivel, $e.Zen }
