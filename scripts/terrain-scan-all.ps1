# terrain-scan-all.ps1
# Escanea TODOS los archivos de terreno del cliente (EncTerrain*.att, .map y .obj)
# y verifica que el byte 1 de la cabecera coincida con el numero de carpeta WorldN.
#
# El cliente MU (MapManager.cpp) rechaza el mapa con "file corrupted" si no coincide.
# - .att : se descifra con MapFileDecrypt y DESPUES se aplica BuxConvert (XOR FC CF AB)
# - .map : solo MapFileDecrypt
# - .obj : solo MapFileDecrypt
#
# Uso: .\terrain-scan-all.ps1 [-Root "C:\...\Cliente\Data"] [-World 1]

param(
    [string]$Root = "C:\proyectos\servidor mu\Cliente\Data",
    [int]$World = 0
)

$ErrorActionPreference = 'Stop'

$MapXorKey       = [byte[]](0xD1,0x73,0x52,0xF6,0xD2,0x9A,0xCB,0x27,0x3E,0xAF,0x59,0x31,0x37,0xB3,0xE7,0xA2)
$BuxKey          = [byte[]](0xFC,0xCF,0xAB)
$InitialMapKey   = [byte]0x5E
$MapKeyIncrement = [byte]0x3D

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

$dirs = Get-ChildItem $Root -Directory -Filter "World*" | Sort-Object { [int]($_.Name -replace 'World','') }
if ($World -gt 0) { $dirs = $dirs | Where-Object { $_.Name -eq "World$World" } }

"{0,-34} {1,8}  {2,-14} {3,-6} {4}" -f "Archivo","Tamano","Cabecera","B1","Estado"
"-" * 100

foreach ($d in $dirs) {
    $n = [int]($d.Name -replace 'World','')
    $files = Get-ChildItem $d.FullName -File -Filter "EncTerrain$n.*" | Where-Object { $_.Extension -in '.att','.map','.obj' } | Sort-Object Extension
    # tambien variantes con otro nombre (p.ej. EncTerrain1.64KB.att) se ignoran a proposito
    foreach ($f in $files) {
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $dec = [byte[]]::new($bytes.Length)
        [Array]::Copy($bytes, $dec, $bytes.Length)
        Decrypt-MapFile $dec
        if ($f.Extension -eq '.att') { Apply-BuxKey $dec }

        $hdr = ($dec[0..([Math]::Min(7,$dec.Length-1))] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
        $b1 = $dec[1]
        $estado = if ($b1 -eq $n) { "OK" } else { "MAL (esperado $('{0:X2}' -f $n))" }
        if ($f.Extension -eq '.att') {
            $high = 0
            for ($i = 4; $i -lt $dec.Length; $i++) { if ($dec[$i] -ge 128) { $high++ } }
            if ($high -gt 0) { $estado += "  tiles>=128: $high" }
        }
        "{0,-34} {1,8}  {2,-14} {3,-6} {4}" -f ($d.Name + "\" + $f.Name), $bytes.Length, $hdr, ('{0:X2}' -f $b1), $estado
    }
}
