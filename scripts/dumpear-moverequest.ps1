# dumpear-moverequest.ps1
# Descifra Cliente\Data\Local\MoveReq.bmd y lista las entradas del menu de transporte.
#
# Formato verificado: int32 cantidad en offset 0 (sin cifrar).
# A partir del offset 4: XOR con BuxKey (FC CF AB) con el indice de la clave CONTINUANDO
# por todo el archivo (no se reinicia por entrada).
# Entradas de 80 bytes: int32 index, char[?] nombre...

param(
    [string]$Path = "C:\proyectos\servidor mu\Cliente\Data\Local\MoveReq.bmd"
)

$ErrorActionPreference = 'Stop'
$BuxKey = [byte[]](0xFC,0xCF,0xAB)
$EntrySize = 80

$bytes = [System.IO.File]::ReadAllBytes($Path)
$count = [BitConverter]::ToInt32($bytes, 0)

# La clave XOR se reinicia en cada entrada (80 bytes, divisible? no: 80 % 3 = 2, por eso
# el indice hay que reiniciarlo por entrada y no continuar por el archivo).
$dec = [byte[]]::new($bytes.Length)
[Array]::Copy($bytes, $dec, $bytes.Length)
$entradas = [math]::Floor(($dec.Length - 4) / $EntrySize)
for ($e = 0; $e -lt $entradas; $e++) {
    $start = 4 + $e * $EntrySize
    for ($j = 0; $j -lt $EntrySize; $j++) {
        $dec[$start + $j] = [byte]($dec[$start + $j] -bxor $BuxKey[$j % 3])
    }
}

"Archivo : $Path"
"Tamano  : $($bytes.Length)   entradas: $count   (cabrian: $([math]::Floor(($dec.Length-4)/$EntrySize)))"
""
"{0,5} {1,-24} {2}" -f "#", "Nombre", "campos int32 (index, y siguientes)"
"-" * 96

$max = [math]::Min($count, [math]::Floor(($dec.Length - 4) / $EntrySize))
for ($e = 0; $e -lt $max; $e++) {
    $off = 4 + $e * $EntrySize
    $name = ""
    for ($p = $off + 4; $p -lt $off + 40; $p++) {
        if ($dec[$p] -ge 32 -and $dec[$p] -lt 127) { $name += [char]$dec[$p] }
        elseif ($name.Length -gt 0) { break }
    }
    $ints = @()
    for ($k = 0; $k -lt 8; $k++) { $ints += [BitConverter]::ToInt32($dec, $off + $k * 4) }
    "{0,5} {1,-24} {2}" -f $e, $name, ($ints -join ', ')
}
