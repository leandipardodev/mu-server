# Agrega o corrige mensajes en MuServer\Data\Message.txt sin tocar el resto.
#
# Message.txt lo lee el GameServer al arrancar (no en caliente), asi que despues
# de correr este script hay que reiniciar con RECARGAR-GAMESERVER.cmd (admin).
#
# Los mensajes nuevos salen de scripts\textos-cliente\mensajes-servidor.txt
# (UTF-8, formato  indice|texto ) y se escriben en CP1252 (ANSI).
#
# Uso:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\aplicar-mensajes-servidor.ps1

$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent $PSScriptRoot
$dataIn = Join-Path $PSScriptRoot 'textos-cliente'
$ansi   = [System.Text.Encoding]::GetEncoding(1252)
$utf8   = New-Object System.Text.UTF8Encoding($false)

$path = Join-Path $root 'MuServer\Data\Message.txt'

function Get-AnsiBytes([string]$text, [string]$origen) {
    $bytes  = $ansi.GetBytes($text)
    $vuelta = $ansi.GetString($bytes)
    if ($vuelta -ne $text) {
        throw "El texto de '$origen' tiene caracteres que no existen en ANSI/CP1252: $text"
    }
    return $bytes
}

# --- 1) lee el Message.txt actual (indice -> texto) -------------------------
$mapa  = @{}
$orden = New-Object System.Collections.Generic.List[int]
foreach ($linea in [System.IO.File]::ReadAllLines($path, $ansi)) {
    if ($linea -match '^\s*(\d+)\s+"(.*)"\s*$') {
        $i = [int]$matches[1]
        if (-not $mapa.ContainsKey($i)) { $orden.Add($i) }
        $mapa[$i] = $matches[2]
    }
}
if ($orden.Count -eq 0) { throw 'No se pudo leer ningun mensaje de Message.txt' }

# --- 2) aplica los mensajes nuevos ----------------------------------------
$nuevos = @([System.IO.File]::ReadAllLines((Join-Path $dataIn 'mensajes-servidor.txt'), $utf8) |
    Where-Object { $_.Trim().Length -gt 0 })
if ($nuevos.Count -eq 0) { throw 'mensajes-servidor.txt esta vacio' }

Write-Host 'Mensajes a aplicar:'
foreach ($linea in $nuevos) {
    $p = $linea.Split('|', 2)
    if ($p.Count -ne 2) { throw "Linea invalida en mensajes-servidor.txt: $linea" }
    $i   = [int]$p[0]
    $txt = $p[1].Trim()
    if ($txt.Length -gt 200) { throw "El mensaje $i pasa de 200 caracteres" }
    [void](Get-AnsiBytes $txt "mensajes-servidor.txt indice $i")
    if ($mapa.ContainsKey($i)) {
        Write-Host ("  [{0,4}] (actualiza)  {1}" -f $i, $txt)
    } else {
        Write-Host ("  [{0,4}] (nuevo)     {1}" -f $i, $txt)
        $orden.Add($i)
    }
    $mapa[$i] = $txt
}

# --- 3) escribe el archivo completo ordenado ------------------------------
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('//Index' + "`t" + 'Message')
foreach ($i in ($orden | Sort-Object)) {
    [void]$sb.AppendLine(('{0,-9} "{1}"' -f $i, $mapa[$i]))
}

$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = "$path.bak-$stamp"
Copy-Item -LiteralPath $path -Destination $backup -Force
[System.IO.File]::WriteAllBytes($path, (Get-AnsiBytes $sb.ToString() 'Message.txt'))

$total = ($orden | Sort-Object)
Write-Host ''
Write-Host ("[OK] Message.txt -> {0} mensajes (0..{1}), {2:N0} bytes" -f $total.Count, $total[-1], (Get-Item -LiteralPath $path).Length)
Write-Host ("     backup: {0}" -f (Split-Path -Leaf $backup))
Write-Host ''
Write-Host 'Reiniciar el GameServer para que tome los mensajes: RECARGAR-GAMESERVER.cmd (admin).'
