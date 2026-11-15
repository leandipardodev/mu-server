# terrain-att-tool.ps1
# Descifra / verifica / corrige archivos EncTerrain*.att del cliente MU Online.
#
# Formato del archivo de cliente (65540 bytes):
#   - 4 bytes de cabecera: version(0), numero de mapa, 255, 255
#   - 65536 bytes de tiles (1 por tile, 256x256, fila por fila)
#   - luego se aplica XOR con BuxKey (FC CF AB) y el cifrado del cliente.
#
# El cliente RECHAZA el archivo como "corrupted" si algun tile tiene el bit alto (>=128).
# Algoritmo tomado del proyecto OpenMU (TerrainFileConverter), verificado con su vector de prueba.
#
# Uso:
#   .\terrain-att-tool.ps1 -Path <archivo.att>            (solo verifica)
#   .\terrain-att-tool.ps1 -Path <archivo.att> -Mode fix  (corrige y re-cifra)

param(
    [Parameter(Mandatory = $true)][string]$Path,
    [ValidateSet('check', 'fix')][string]$Mode = 'check'
)

$ErrorActionPreference = 'Stop'

$TileCount        = 256 * 256
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
    for ($i = 0; $i -lt $data.Length; $i++) {
        $data[$i] = [byte]($data[$i] -bxor $BuxKey[$i % 3])
    }
}

function Encrypt-MapFile([byte[]]$data) {
    [byte]$mapKey = $InitialMapKey
    for ($i = 0; $i -lt $data.Length; $i++) {
        $data[$i] = [byte]((($data[$i] + $mapKey) -band 0xFF) -bxor $MapXorKey[$i % 16])
        $mapKey = [byte](($data[$i] + $MapKeyIncrement) -band 0xFF)
    }
}

$bytes = [System.IO.File]::ReadAllBytes($Path)
Write-Host "Archivo : $Path"
Write-Host "Tamano  : $($bytes.Length)"

if ($bytes.Length -ne ($ClientHeaderSize + $TileCount)) {
    Write-Host "AVISO: el tamano no es 65540; puede ser un mapa extendido (2 bytes/tile)." -ForegroundColor Yellow
}

# --- descifrar ---
$dec = [byte[]]::new($bytes.Length)
[Array]::Copy($bytes, $dec, $bytes.Length)
Decrypt-MapFile $dec
Apply-BuxKey $dec

$mapNum = $dec[1]
Write-Host ("Cabecera: {0:X2} {1:X2} {2:X2} {3:X2}   version={0} mapa={1} ancho-1={2} alto-1={3}" -f $dec[0], $dec[1], $dec[2], $dec[3])

$okHeader = ($dec[0] -eq 0 -and $dec[2] -eq 0xFF -and $dec[3] -eq 0xFF)

$tileStart = $ClientHeaderSize
$high = 0
for ($i = $tileStart; $i -lt $dec.Length; $i++) {
    if ($dec[$i] -ge 128) { $high++ }
}
Write-Host "Tiles con bit alto (>=128): $high"
Write-Host "Cabecera valida           : $okHeader"
Write-Host ("Primeros tiles: " + (($dec[$tileStart..($tileStart + 15)] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '))

if ($Mode -eq 'fix') {
    if (-not $okHeader) {
        Write-Host "ERROR: la cabecera no es valida; no se toca el archivo." -ForegroundColor Red
        exit 2
    }
    if ($high -eq 0) {
        Write-Host "No hay nada que corregir (ningun tile >=128)." -ForegroundColor Green
        exit 0
    }

    for ($i = $tileStart; $i -lt $dec.Length; $i++) {
        $dec[$i] = [byte]($dec[$i] -band 0x7F)
    }

    $enc = [byte[]]::new($dec.Length)
    [Array]::Copy($dec, $enc, $dec.Length)
    Apply-BuxKey $enc
    Encrypt-MapFile $enc

    $bak = "$Path.pre-fix.bak"
    if (-not (Test-Path $bak)) { Copy-Item $Path $bak -Force }
    [System.IO.File]::WriteAllBytes($Path, $enc)
    Write-Host "FIX aplicado: $high tiles corregidos. Backup: $bak" -ForegroundColor Green

    # verificar releyendo
    $v = [byte[]]::new($enc.Length)
    [Array]::Copy($enc, $v, $enc.Length)
    Decrypt-MapFile $v
    Apply-BuxKey $v
    $h2 = 0
    for ($i = $tileStart; $i -lt $v.Length; $i++) { if ($v[$i] -ge 128) { $h2++ } }
    Write-Host ("Verificacion -> cabecera: {0:X2} {1:X2} {2:X2} {3:X2}, tiles>=128: {4}" -f $v[0], $v[1], $v[2], $v[3], $h2)
}
