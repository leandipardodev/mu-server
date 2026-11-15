# Aplica los textos en espanol al servidor y al cliente.
# - MuServer\Data\Util\Notice.txt        (6 avisos rotativos)
# - Cliente\Data\Local\Slide.bmd         (tips de pantalla de carga, 32 slots)
# - Cliente\Data\Local\Text.bmd          (descripciones de items, indices 571+)
#
# Los textos se leen de scripts\textos-cliente\*.txt en UTF-8 y se escriben
# en CP1252 (ANSI), que es lo que leen el juego y el cliente.
#
# Uso:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\aplicar-textos-cliente.ps1

$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent $PSScriptRoot
$dataIn = Join-Path $PSScriptRoot 'textos-cliente'
$ansi   = [System.Text.Encoding]::GetEncoding(1252)
$utf8   = New-Object System.Text.UTF8Encoding($false)

function Get-AnsiBytes([string]$text, [string]$origen) {
    $bytes = $ansi.GetBytes($text)
    $vuelta = $ansi.GetString($bytes)
    if ($vuelta -ne $text) {
        throw "El texto de '$origen' tiene caracteres que no existen en ANSI/CP1252: $text"
    }
    return $bytes
}

function Backup-File([string]$path) {
    $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = "$path.bak-$stamp"
    Copy-Item -LiteralPath $path -Destination $backup -Force
    $bak = "$path.bak"
    if (-not (Test-Path -LiteralPath $bak)) {
        Copy-Item -LiteralPath $path -Destination $bak -Force
    }
    return $backup
}

function Read-Bmd([string]$path) {
    $key = [byte[]](0xFC, 0xCF, 0xAB)
    $buf = [System.IO.File]::ReadAllBytes($path)
    for ($i = 0; $i -lt $buf.Length; $i++) { $buf[$i] = $buf[$i] -bxor $key[$i % 3] }
    return ,$buf
}

function Write-Bmd([string]$path, [byte[]]$buf) {
    $key = [byte[]](0xFC, 0xCF, 0xAB)
    $out = New-Object byte[] $buf.Length
    [Array]::Copy($buf, $out, $buf.Length)
    for ($i = 0; $i -lt $out.Length; $i++) { $out[$i] = $out[$i] -bxor $key[$i % 3] }
    [System.IO.File]::WriteAllBytes($path, $out)
}

function Set-Slot([byte[]]$buf, [int]$offset, [int]$size, [string]$text, [string]$origen) {
    $bytes = Get-AnsiBytes $text $origen
    if ($bytes.Length -ge $size) {
        throw "El texto '$text' no entra en $size bytes (origen: $origen)"
    }
    for ($j = 0; $j -lt $size; $j++) { $buf[$offset + $j] = 0 }
    [Array]::Copy($bytes, 0, $buf, $offset, $bytes.Length)
}

# ---------------------------------------------------------------------------
# 1) Notice.txt (avisos que muestra el GameServer)
# ---------------------------------------------------------------------------
$noticePath = Join-Path $root 'MuServer\Data\Util\Notice.txt'
$noticeLines = [System.IO.File]::ReadAllLines((Join-Path $dataIn 'notice.txt'), $utf8) |
    Where-Object { $_.Trim().Length -gt 0 }
if ($noticeLines.Count -eq 0) { throw 'notice.txt esta vacio' }

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('//Message' + "`t`t`t`t`t`t`t`t`t`t`t`t`t" + 'Type' + "`t" + 'Count' + "`t" + 'Opacity' + "`t" + 'Delay' + "`t" + 'Red' + "`t" + 'Green' + "`t" + 'Blue' + "`t" + 'Speed' + "`t" + 'RepeatTime')
foreach ($line in $noticeLines) {
    $p = $line.Split('|')
    if ($p.Count -ne 10) { throw "Linea de notice.txt invalida (se esperan 10 campos): $line" }
    $msg = $p[0]
    [void]$sb.Append('"' + $msg + '"' + "`t" + ($p[1..9] -join "`t"))
    [void]$sb.AppendLine()
}
[void]$sb.AppendLine('end')

$noticeBackup = Backup-File $noticePath
[System.IO.File]::WriteAllBytes($noticePath, (Get-AnsiBytes $sb.ToString() 'Notice.txt'))
Write-Host ("[OK] Notice.txt  -> {0} avisos (backup: {1})" -f $noticeLines.Count, (Split-Path -Leaf $noticeBackup))

# ---------------------------------------------------------------------------
# 2) Slide.bmd (tips de pantalla de carga: 16 + 160*256 + 32 bytes)
# ---------------------------------------------------------------------------
$slidePath = Join-Path $root 'Cliente\Data\Local\Slide.bmd'
$slideOriginalSize = (Get-Item -LiteralPath $slidePath).Length
$slide = Read-Bmd $slidePath
if ($slide.Length -ne (16 + 160 * 256 + 32)) {
    throw ("Slide.bmd tiene un tamano inesperado: {0} bytes" -f $slide.Length)
}

$tipLines = [System.IO.File]::ReadAllLines((Join-Path $dataIn 'slide-tips.txt'), $utf8)
if ($tipLines.Count -gt 32) { throw "slide-tips.txt tiene $($tipLines.Count) lineas; el maximo es 32" }

$slideBackup = Backup-File $slidePath
for ($r = 0; $r -lt $tipLines.Count; $r++) {
    Set-Slot $slide (16 + 256 * $r) 256 $tipLines[$r].Trim() ("slide-tips.txt linea " + ($r + 1))
}
# limpia el slot 32, que tenia un caracter suelto
for ($j = 0; $j -lt 256; $j++) { $slide[16 + 256 * 32 + $j] = 0 }

Write-Bmd $slidePath $slide
$slideNewSize = (Get-Item -LiteralPath $slidePath).Length
if ($slideNewSize -ne $slideOriginalSize) {
    throw ("Slide.bmd cambio de tamano: {0} -> {1}" -f $slideOriginalSize, $slideNewSize)
}
Write-Host ("[OK] Slide.bmd  -> {0} tips, {1:N0} bytes (backup: {2})" -f $tipLines.Count, $slideNewSize, (Split-Path -Leaf $slideBackup))

# ---------------------------------------------------------------------------
# 3) Text.bmd (descripciones de items: 3000 registros de 300 bytes)
# ---------------------------------------------------------------------------
$textPath = Join-Path $root 'Cliente\Data\Local\Text.bmd'
$textOriginalSize = (Get-Item -LiteralPath $textPath).Length
$textBuf = Read-Bmd $textPath
if (($textBuf.Length % 300) -ne 0) {
    throw ("Text.bmd no es multiplo de 300 bytes: {0}" -f $textBuf.Length)
}
$maxRegistro = ($textBuf.Length / 300) - 1

$textBackup = Backup-File $textPath
$cambios = 0
foreach ($line in [System.IO.File]::ReadAllLines((Join-Path $dataIn 'item-descripciones.txt'), $utf8)) {
    if ($line.Trim().Length -eq 0) { continue }
    $p = $line.Split('|')
    if ($p.Count -ne 2) { throw "Linea invalida en item-descripciones.txt: $line" }
    $idx = [int]$p[0]
    if ($idx -lt 0 -or $idx -gt $maxRegistro) { throw "Indice fuera de rango: $idx" }
    Set-Slot $textBuf ($idx * 300) 300 $p[1].Trim() ("item-descripciones.txt indice " + $idx)
    Write-Host ("     Text.bmd [{0,4}] {1}" -f $idx, $p[1].Trim())
    $cambios++
}
Write-Bmd $textPath $textBuf
$textNewSize = (Get-Item -LiteralPath $textPath).Length
if ($textNewSize -ne $textOriginalSize) {
    throw ("Text.bmd cambio de tamano: {0} -> {1}" -f $textOriginalSize, $textNewSize)
}
Write-Host ("[OK] Text.bmd   -> {0} descripciones, {1:N0} bytes (backup: {2})" -f $cambios, $textNewSize, (Split-Path -Leaf $textBackup))

# ---------------------------------------------------------------------------
# 4) CustomTooltip.txt (linea extra en el tooltip: que suelta cada caja)
# ---------------------------------------------------------------------------
$tipPath = Join-Path $root 'Cliente\Data\CustomTooltip.txt'
$tipEntradas = @([System.IO.File]::ReadAllLines((Join-Path $dataIn 'custom-tooltip.txt'), $utf8) |
    Where-Object { $_.Trim().Length -gt 0 })
if ($tipEntradas.Count -eq 0) { throw 'custom-tooltip.txt esta vacio' }

$marcaIni = '// >>> MuNega: contenido de las cajas'
$marcaFin = '// <<< MuNega: contenido de las cajas'

$bloque = New-Object System.Collections.Generic.List[string]
$bloque.Add($marcaIni)
foreach ($linea in $tipEntradas) {
    $p = $linea.Split('|')
    if ($p.Count -ne 5) { throw "Linea invalida en custom-tooltip.txt (se esperan 5 campos): $linea" }
    if ($p[0] -notmatch '^\d{1,2},\d{3}$') { throw "ItemIndex invalido (formato gg,iii): $($p[0])" }
    if ($p[1] -ne '*' -and $p[1] -notmatch '^\d{1,2}$') { throw "ItemLevel invalido (numero o *): $($p[1])" }
    $txt = $p[4].Trim()
    if ($txt.Length -gt 25) { throw "El texto '$txt' tiene $($txt.Length) caracteres; el maximo es 25" }
    $lineaTip = '{0}' + "`t" + '{1}' + "`t" + '{2}' + "`t" + '{3}' + "`t" + '"{4}"'
    $bloque.Add(($lineaTip -f $p[0], $p[1], $p[2], $p[3], $txt))
}
$bloque.Add($marcaFin)

$tipFinal = New-Object System.Collections.Generic.List[string]
$dentro = $false
$insertado = $false
foreach ($linea in [System.IO.File]::ReadAllLines($tipPath, $ansi)) {
    $t = $linea.Trim()
    if ($t -eq $marcaIni) { $dentro = $true; continue }
    if ($t -eq $marcaFin) { $dentro = $false; continue }
    if ($dentro) { continue }
    if (-not $insertado -and $t -eq 'end') {
        foreach ($b in $bloque) { $tipFinal.Add($b) }
        $insertado = $true
    }
    $tipFinal.Add($linea)
}
if (-not $insertado) { throw 'No se encontro la linea "end" en CustomTooltip.txt' }

$tipBackup = Backup-File $tipPath
[System.IO.File]::WriteAllBytes($tipPath, (Get-AnsiBytes (($tipFinal -join "`r`n") + "`r`n") 'CustomTooltip.txt'))
Write-Host ("[OK] CustomTooltip.txt -> {0} lineas (backup: {1})" -f $tipEntradas.Count, (Split-Path -Leaf $tipBackup))

Write-Host ''
Write-Host 'Listo. El cliente toma Slide.bmd/Text.bmd/CustomTooltip.txt al abrir el juego.'
Write-Host 'Notice.txt lo lee el GameServer al arrancar: reiniciar con RECARGAR-GAMESERVER.cmd (admin).'
