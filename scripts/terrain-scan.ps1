# terrain-scan.ps1
# Escanea todos los EncTerrain*.att del cliente y muestra, tras descifrar con el algoritmo
# de OpenMU, la cabecera resultante y cuantos tiles tienen el bit alto (>=128).
# Si el algoritmo coincide con el cliente, TODOS los mapas deben dar cabecera valida y 0 tiles altos.

param(
    [string]$Root = "C:\proyectos\servidor mu\Cliente\Data"
)

$ErrorActionPreference = 'Stop'

$ClientHeaderSize = 4
$MapXorKey        = [byte[]](0xD1,0x73,0x52,0xF6,0xD2,0x9A,0xCB,0x27,0x3E,0xAF,0x59,0x31,0x37,0xB3,0xE7,0xA2)
$BuxKey           = [byte[]](0xFC,0xCF,0xAB)
$InitialMapKey    = [byte]0x5E
$MapKeyIncrement  = [byte]0x3D

function Decrypt-MapFile([byte[]]$data) {
    [byte]$mapKey = $InitialMapKey
    for ($i = 0; $i -lt $data.Length; $i++) {
        $enc = $data[$i]
        $data[$i] = [byte]((($enc -bxor $MapXorKey[$i % 16]) - $mapKey) -band 0xFF)
        $mapKey = [byte](($enc + $MapKeyIncrement) -band 0xFF)
    }
}
function Apply-BuxKey([byte[]]$data) {
    for ($i = 0; $i -lt $data.Length; $i++) { $data[$i] = [byte]($data[$i] -bxor $BuxKey[$i % 3]) }
}

$root = $Root
"{0,-28} {1,8}  {2,-13} {3,8} {4,8}  {5}" -f "Archivo","Tamano","Cabecera","Valida","Tiles>=128","Mapa(1er tile)"
"-" * 90

Get-ChildItem $root -Directory -Filter "World*" | Sort-Object {
    [int]($_.Name -replace 'World','')
} | ForEach-Object {
    $w = $_.Name
    Get-ChildItem $_.FullName -File -Filter "EncTerrain*.att" | Sort-Object Name | ForEach-Object {
        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $dec = [byte[]]::new($bytes.Length)
        [Array]::Copy($bytes, $dec, $bytes.Length)
        Decrypt-MapFile $dec
        Apply-BuxKey $dec
        $ok = ($dec[0] -eq 0 -and $dec[2] -eq 0xFF -and $dec[3] -eq 0xFF)
        $high = 0
        for ($i = $ClientHeaderSize; $i -lt $dec.Length; $i++) { if ($dec[$i] -ge 128) { $high++ } }
        $hdr = "{0:X2} {1:X2} {2:X2} {3:X2}" -f $dec[0], $dec[1], $dec[2], $dec[3]
        "{0,-28} {1,8}  {2,-13} {3,8} {4,8}  {5}" -f "$w\$($_.Name)", $bytes.Length, $hdr, $ok, $high, ("{0:X2}" -f $dec[4])
    }
}
