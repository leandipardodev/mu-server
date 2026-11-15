# Aplica los anuncios y textos personalizados del servidor.
#   1) MuServer\Data\Util\Notice.txt   -> avisos rotativos en pantalla
#   2) MuServer\Data\Message.txt       -> indice 256 (bienvenida al entrar)
#   3) MuServer\Data\Script\ScriptMain.lua -> saludos de NPC
#   4) Cliente\Data\Local\Dialog.bmd   -> dialogos de NPC en espanol
#
# Uso:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\aplicar-anuncios.ps1

$ErrorActionPreference = 'Stop'

$raiz    = "C:\proyectos\servidor mu"
$enc1252 = [System.Text.Encoding]::GetEncoding(1252)
$encUtf8 = [System.Text.Encoding]::UTF8

function Convertir-Utf8aAnsi([string]$origen, [string]$destino) {
    if (-not (Test-Path -LiteralPath $origen)) { throw "Falta el archivo: $origen" }
    $texto = [System.IO.File]::ReadAllText($origen, $encUtf8)
    [System.IO.File]::WriteAllText($destino, $texto, $enc1252)
}

# ---------------------------------------------------------------
# 1) Notice.txt
# ---------------------------------------------------------------
$notice = Join-Path $raiz "MuServer\Data\Util\Notice.txt"
if (-not (Test-Path -LiteralPath "$notice.bak")) { Copy-Item -LiteralPath $notice -Destination "$notice.bak" }
Convertir-Utf8aAnsi (Join-Path $raiz "scripts\nuevo-notice.txt") $notice
Write-Host "[1/4] Notice.txt actualizado (avisos rotativos)."

# ---------------------------------------------------------------
# 2) Message.txt -> indice 256 (mensaje de bienvenida)
# ---------------------------------------------------------------
$msg = Join-Path $raiz "MuServer\Data\Message.txt"
if (-not (Test-Path -LiteralPath "$msg.bak")) { Copy-Item -LiteralPath $msg -Destination "$msg.bak" }

$nuevo = [System.IO.File]::ReadAllText((Join-Path $raiz "scripts\welcome-256.txt"), $encUtf8).Trim()
$nuevo = $nuevo.Replace('$', '$$')

$contenido = [System.IO.File]::ReadAllText($msg, $enc1252)
$rx = [regex]'(?m)^(\s*256\s+)"[^"\r\n]*"'
if (-not $rx.IsMatch($contenido)) { throw "No se encontro el indice 256 en Message.txt" }

$reemplazo = '${1}"' + $nuevo + '"'
$resultado = $rx.Replace($contenido, $reemplazo, 1)
[System.IO.File]::WriteAllText($msg, $resultado, $enc1252)
Write-Host "[2/4] Message.txt (bienvenida 256): $nuevo"

# ---------------------------------------------------------------
# 3) ScriptMain.lua
# ---------------------------------------------------------------
$lua = Join-Path $raiz "MuServer\Data\Script\ScriptMain.lua"
if (-not (Test-Path -LiteralPath "$lua.bak2")) { Copy-Item -LiteralPath $lua -Destination "$lua.bak2" }
Convertir-Utf8aAnsi (Join-Path $raiz "scripts\scriptmain-nuevo.lua") $lua
Write-Host "[3/4] ScriptMain.lua actualizado (saludos de NPC)."

# ---------------------------------------------------------------
# 4) Dialog.bmd
# ---------------------------------------------------------------
Write-Host "[4/4] Dialog.bmd:"
& (Join-Path $raiz "scripts\editar-dialog-bmd.ps1")

Write-Host ""
Write-Host "Listo. Reinicia el GameServer (RECARGAR-GAMESERVER.cmd) y el cliente."
