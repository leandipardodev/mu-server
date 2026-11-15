# convertir-att-128kb.ps1
# Convierte los EncTerrain*.att de 131.076 bytes (2 bytes por tile, formato "128KB")
# al formato clasico de 65.540 bytes (1 byte por tile) que usa este cliente 1.02.44.
#
# - Guarda el original como <archivo>.128KB.bak
# - Mantiene la cabecera (byte 1 = numero de mundo) intacta
# - Toma el byte BAJO de cada tile (el alto es 0 en estos mapas)
#
# Uso: .\convertir-att-128kb.ps1 [-Root "C:\...\Cliente\Data"] [-QueHacer listar|convertir]

param(
    [string]$Root = "C:\proyectos\servidor mu\Cliente\Data",
    [ValidateSet('listar','convertir')][string]$QueHacer = 'listar',
    [switch]$Forzar
)

$ErrorActionPreference = 'Stop'

$MapXorKey       = [byte[]](0xD1,0x73,0x52,0xF6,0xD2,0x9A,0xCB,0x27,0x3E,0xAF,0x59,0x31,0x37,0xB3,0xE7,0xA2)
$BuxKey          = [byte[]](0xFC,0xCF,0xAB)
$InitialMapKey   = [byte]0x5E
$MapKeyIncrement = [byte]0x3D
$Tamano128       = 131076
$Tamano64        = 65540

function Decrypt-MapFile([byte[]]$data) {
    [byte]$k = $InitialMapKey
    for ($i = 0; $i -lt $data.Length; $i++) {
        $enc = $data[$i]
        $data[$i] = [byte]((($enc -bxor $MapXorKey[$i % 16]) - $k) -band 0xFF)
        $k = [byte](($enc + $MapKeyIncrement) -band 0xFF)
    }
}
function Encrypt-MapFile([byte[]]$data) {
    [byte]$k = $InitialMapKey
    for ($i = 0; $i -lt $data.Length; $i++) {
        $data[$i] = [byte]((($data[$i] + $k) -band 0xFF) -bxor $MapXorKey[$i % 16])
        $k = [byte](($data[$i] + $MapKeyIncrement) -band 0xFF)
    }
}
function Apply-BuxKey([byte[]]$data) {
    for ($i = 0; $i -lt $data.Length; $i++) { $data[$i] = [byte]($data[$i] -bxor $BuxKey[$i % 3]) }
}

$archivos = Get-ChildItem $Root -Directory -Filter "World*" | Sort-Object { [int]($_.Name -replace 'World','') } | ForEach-Object {
    $n = [int]($_.Name -replace 'World','')
    Get-ChildItem $_.FullName -File -Filter "EncTerrain$n.att" -ErrorAction SilentlyContinue
} | Where-Object { $_.Length -eq $Tamano128 }

"{0,-30} {1,10} {2,8} {3}" -f "Archivo", "Tamano", "Mundo", "Accion"
"-" * 70

foreach ($f in $archivos) {
    $n = [int]($f.Directory.Name -replace 'World','')
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $dec = [byte[]]::new($bytes.Length)
    [Array]::Copy($bytes, $dec, $bytes.Length)
    Decrypt-MapFile $dec
    Apply-BuxKey $dec

    $hdr = ($dec[0..3] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
    if ($dec[1] -ne $n) { "  AVISO: $($f.FullName) byte1=$('{0:X2}' -f $dec[1]) esperado $('{0:X2}' -f $n)" }

    # contar tiles con byte alto distinto de 0 (banderas / safe zone)
    $conFlags = 0
    for ($t = 0; $t -lt 65536; $t++) { if ($dec[5 + $t * 2] -ne 0) { $conFlags++ } }

    if ($QueHacer -eq 'listar') {
        $nota = if ($conFlags -eq 0) { "convertible sin perdida" } else { "tiene $conFlags tiles con bandera (alto!=0)" }
        "{0,-30} {1,10} {2,8} {3}" -f ($f.Directory.Name + "\" + $f.Name), $bytes.Length, $n, "$nota  cabecera $hdr"
        continue
    }

    if ($conFlags -gt 0 -and -not $Forzar) {
        "{0,-30} {1,10} {2,8} {3}" -f ($f.Directory.Name + "\" + $f.Name), $bytes.Length, $n, "SALTADO (tiene $conFlags banderas)"
        continue
    }

    $out = [byte[]]::new($Tamano64)
    for ($i = 0; $i -lt 4; $i++) { $out[$i] = $dec[$i] }
    for ($t = 0; $t -lt 65536; $t++) { $out[4 + $t] = $dec[4 + $t * 2] }

    $enc = [byte[]]::new($out.Length)
    [Array]::Copy($out, $enc, $out.Length)
    Apply-BuxKey $enc
    Encrypt-MapFile $enc

    $bak = "$($f.FullName).128KB.bak"
    if (-not (Test-Path $bak)) { Copy-Item $f.FullName $bak -Force }
    [System.IO.File]::WriteAllBytes($f.FullName, $enc)

    # verificar releyendo
    $v = [byte[]]::new($enc.Length)
    [Array]::Copy($enc, $v, $enc.Length)
    Decrypt-MapFile $v
    Apply-BuxKey $v
    $ok = ($v[1] -eq $n -and $v[2] -eq 0xFF -and $v[3] -eq 0xFF)
    "{0,-30} {1,10} {2,8} {3}" -f ($f.Directory.Name + "\" + $f.Name), "$($bytes.Length)->$($enc.Length)", $n, $(if ($ok) { "OK convertido (cabecera $($v[0..3] | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')" } else { "ERROR: cabecera invalida" })
}

""
"Total: $($archivos.Count) archivo(s) de 128KB."
