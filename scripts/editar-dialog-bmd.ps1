param(
    [string]$Bmd    = "C:\proyectos\servidor mu\Cliente\Data\Local\Dialog.bmd",
    [string]$Textos = "C:\proyectos\servidor mu\scripts\dialog-textos.txt"
)

$ErrorActionPreference = 'Stop'

# Dialog.bmd = 200 registros de 1024 bytes, cada uno cifrado con XOR (FC,CF,AB)
# empezando de nuevo en el byte 0 de cada registro.
$key = [byte[]](0xFC, 0xCF, 0xAB)
$rec = 1024
$enc = [System.Text.Encoding]::GetEncoding(1252)

if (-not (Test-Path -LiteralPath $Bmd))    { throw "No existe: $Bmd" }
if (-not (Test-Path -LiteralPath $Textos)) { throw "No existe: $Textos" }

$bytes = [System.IO.File]::ReadAllBytes($Bmd)
if (($bytes.Length % $rec) -ne 0) { throw "Tamano invalido: $($bytes.Length) (no es multiplo de $rec)" }
$total = [int]($bytes.Length / $rec)

$bak = "$Bmd.bak"
if (-not (Test-Path -LiteralPath $bak)) {
    Copy-Item -LiteralPath $Bmd -Destination $bak
    Write-Host "  backup: $bak"
}

$cambios = 0
foreach ($linea in [System.IO.File]::ReadAllLines($Textos, [System.Text.Encoding]::UTF8)) {
    $l = $linea.Trim()
    if ($l.Length -eq 0 -or $l.StartsWith('//')) { continue }
    $pos = $l.IndexOf('|')
    if ($pos -lt 1) { continue }

    $idx = 0
    if (-not [int]::TryParse($l.Substring(0, $pos).Trim(), [ref]$idx)) { continue }
    if ($idx -lt 0 -or $idx -ge $total) { Write-Warning "indice fuera de rango: $idx"; continue }

    $texto = $l.Substring($pos + 1)
    $tb = $enc.GetBytes($texto)
    if ($tb.Length -gt ($rec - 1)) { Write-Warning "texto demasiado largo en $idx"; continue }

    $plain = New-Object byte[] $rec
    [Array]::Copy($tb, $plain, $tb.Length)

    $off = $idx * $rec
    for ($j = 0; $j -lt $rec; $j++) {
        $bytes[$off + $j] = $plain[$j] -bxor $key[$j % 3]
    }
    $cambios++
    Write-Host ("  entrada {0,3}: {1}" -f $idx, $texto)
}

[System.IO.File]::WriteAllBytes($Bmd, $bytes)
Write-Host ""
Write-Host ("Dialog.bmd: {0} entradas escritas de {1}." -f $cambios, $total)
