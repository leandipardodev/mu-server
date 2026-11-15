# arreglar-world7.ps1
#
# PROBLEMA (causa raiz encontrada en el codigo del cliente, MapManager.cpp):
#   iResult = OpenTerrainAttribute(FileName);
#   if (iMapWorld != iResult && -1 != iResult)  ->  "%s file corrupted."
#
# O sea: el numero de mapa guardado en la cabecera (byte 1) del archivo
# EncTerrainN.att DEBE ser igual al numero de World (N). Si no, el cliente
# muestra "file corrupted" y cierra.
#
# En este repack, EncTerrain7.att tiene el numero 6 -> error.
# EncTerrain7.map y EncTerrain7.obj ya tienen 7 -> estan bien.
#
# Este script:
#   1) restaura los 5 archivos originales del repack de World7 (el terreno real del Arena)
#   2) corrige el byte de numero de mapa del .att de 6 a 7
#   3) verifica los tres archivos (.att, .map, .obj)
#
# Uso:  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\arreglar-world7.ps1

param(
    [int]$World = 7
)

$ErrorActionPreference = 'Stop'

$worldDir = "C:\proyectos\servidor mu\Cliente\Data\World$World"
$bakDir   = Join-Path $worldDir "_bak_repack_terrain"

$MapXorKey       = [byte[]](0xD1,0x73,0x52,0xF6,0xD2,0x9A,0xCB,0x27,0x3E,0xAF,0x59,0x31,0x37,0xB3,0xE7,0xA2)
$BuxKey          = [byte[]](0xFC,0xCF,0xAB)
$InitialMapKey   = 0x5E
$MapKeyIncrement = 0x3D

function Decrypt-MapFile([byte[]]$src) {
    $dst = [byte[]]::new($src.Length)
    $mk = $InitialMapKey
    for ($i = 0; $i -lt $src.Length; $i++) {
        $s = [int]$src[$i]
        $k = [int]$MapXorKey[$i % 16]
        $dst[$i] = [byte]((($s -bxor $k) - $mk) -band 0xFF)
        $mk = ($s + $MapKeyIncrement) -band 0xFF
    }
    return ,$dst
}

function Apply-BuxKey([byte[]]$src) {
    $dst = [byte[]]::new($src.Length)
    for ($i = 0; $i -lt $src.Length; $i++) {
        $dst[$i] = [byte]([int]$src[$i] -bxor [int]$BuxKey[$i % 3])
    }
    return ,$dst
}

function Encrypt-MapFile([byte[]]$src) {
    $dst = [byte[]]::new($src.Length)
    $mk = $InitialMapKey
    for ($i = 0; $i -lt $src.Length; $i++) {
        $v = (([int]$src[$i] + $mk) -band 0xFF) -bxor [int]$MapXorKey[$i % 16]
        $dst[$i] = [byte]($v -band 0xFF)
        $mk = ([int]$dst[$i] + $MapKeyIncrement) -band 0xFF
    }
    return ,$dst
}

Write-Host "=== 1) Restaurando originales del repack para World$World ===" -ForegroundColor Cyan
$files = @("EncTerrain$World.att", "EncTerrain$World.map", "EncTerrain$World.obj", "TerrainHeight.OZB", "TerrainLight.OZJ")
if (-not (Test-Path $bakDir)) {
    Write-Host "  No hay carpeta de respaldo ($bakDir). Se omite la restauracion" -ForegroundColor Yellow
    Write-Host "  y solo se corrige el numero de mapa del .att actual." -ForegroundColor Yellow
} else {
    $restaurado = $false
    foreach ($f in $files) {
        $src = Join-Path $bakDir $f
        if (-not (Test-Path $src)) { continue }
        Copy-Item $src (Join-Path $worldDir $f) -Force
        $restaurado = $true
        Write-Host ("  restaurado {0,-22} {1} bytes" -f $f, (Get-Item $src).Length)
    }
    if (-not $restaurado) { Write-Host "  (el respaldo esta vacio)" -ForegroundColor Yellow }
}

Write-Host ""
Write-Host "=== 2) Corrigiendo numero de mapa en EncTerrain$World.att ===" -ForegroundColor Cyan
$att = Join-Path $worldDir "EncTerrain$World.att"
$bytes = [System.IO.File]::ReadAllBytes($att)

# Descifrar: MapFileDecrypt y luego BuxConvert (asi lo hace el cliente para .att)
$dec = Decrypt-MapFile $bytes
$dec = Apply-BuxKey $dec

Write-Host ("  antes  -> {0:X2} {1:X2} {2:X2} {3:X2}  (version={0} mapa={1})" -f $dec[0], $dec[1], $dec[2], $dec[3])

if ($dec[0] -ne 0 -or $dec[2] -ne 0xFF -or $dec[3] -ne 0xFF) {
    Write-Host "  ERROR: cabecera no valida; no se modifica." -ForegroundColor Red
    exit 2
}

$dec[1] = [byte]$World

# Volver a cifrar: BuxConvert y luego MapFileEncrypt
$enc = Apply-BuxKey $dec
$enc = Encrypt-MapFile $enc
[System.IO.File]::WriteAllBytes($att, $enc)

# Verificar el .att
$chk = [System.IO.File]::ReadAllBytes($att)
$chkD = Decrypt-MapFile $chk
$chkD = Apply-BuxKey $chkD
$high = 0
for ($i = 4; $i -lt $chkD.Length; $i++) { if ($chkD[$i] -ge 128) { $high++ } }
Write-Host ("  ahora  -> {0:X2} {1:X2} {2:X2} {3:X2}  (version={0} mapa={1})  tiles>=128: {4}" -f $chkD[0], $chkD[1], $chkD[2], $chkD[3], $high) -ForegroundColor Green

Write-Host ""
Write-Host "=== 3) Verificando .map y .obj (sin BuxConvert) ===" -ForegroundColor Cyan
foreach ($f in @("EncTerrain$World.map", "EncTerrain$World.obj")) {
    $p = Join-Path $worldDir $f
    $b = [System.IO.File]::ReadAllBytes($p)
    $d = Decrypt-MapFile $b
    $ok = ($d[0] -eq 0 -and $d[1] -eq $World)
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("  {0,-22} {1:X2} {2:X2} ...  version={1} mapa={2}  {3}" -f $f, $d[0], $d[1], $(if ($ok) { 'OK' } else { 'INCORRECTO' })) -ForegroundColor $color
}

Write-Host ""
Write-Host "Listo. Reinicia el cliente (cerrado por completo) y prueba /move stadium." -ForegroundColor Cyan
