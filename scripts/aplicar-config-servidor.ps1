<#
.SYNOPSIS
  Aplica la configuracion de diseno del servidor MuEmu 1.02r.

.DESCRIPTION
  Modifica los archivos del MuServer segun el diseno acordado:
    - Rate de experiencia general (por defecto x3000).
    - Reset a nivel 400, conservando stats (CommandResetType = 0).
    - +1000 puntos de stat por reset.
  Es idempotente: se puede volver a ejecutar.

  NOTA: en estos files 100 = 1x (porcentaje). Por eso x3000 se escribe 300000.

.NOTES
  Los archivos se escriben en Latin1 (byte-safe) para no alterar acentos.
#>
param(
    [string] $MuServer   = (Join-Path (Split-Path $PSScriptRoot -Parent) "MuServer"),
    [int]    $ExpRate    = 3000,      # multiplicador deseado (3000 = x3000)
    [int]    $ResetPoints= 1000,      # puntos de stat por reset
    [int]    $ResetLevel = 400        # nivel requerido para resetear
)

$ErrorActionPreference = "Stop"
$lat = [System.Text.Encoding]::GetEncoding(28591)
$expFileValue = $ExpRate * 100   # 100 = 1x

function Get-Text([string]$p) { [System.IO.File]::ReadAllText($p, $lat) }
function Set-Text([string]$p,[string]$t) { [System.IO.File]::WriteAllText($p, $t, $lat) }

function Set-KeyValue([string]$path, [string]$key, [string]$value) {
    if (-not (Test-Path $path)) { Write-Host "  [SKIP] no existe: $path"; return }
    $c = Get-Text $path
    $pattern = "(?m)^([ \t]*" + [regex]::Escape($key) + "[ \t]*=[ \t]*)[^\r\n]*"
    $replacement = '${1}' + $value
    $new = [regex]::Replace($c, $pattern, $replacement)
    if ($new -ne $c) { Set-Text $path $new; Write-Host ("  [OK]   {0} = {1}   ({2})" -f $key, $value, (Split-Path $path -Leaf)) }
    else             { Write-Host ("  [----] {0} sin cambios o no encontrado ({1})" -f $key, (Split-Path $path -Leaf)) }
}

Write-Host "=== 1) Experience rate (x$ExpRate => valor en archivo $expFileValue) ==="
$commonFiles = @(
    (Join-Path $MuServer "GameServer\DATA\GameServerInfo - Common.dat"),
    (Join-Path $MuServer "GameServerCS\DATA\GameServerInfo - Common.dat")
)
foreach ($f in $commonFiles) {
    Set-KeyValue $f "AddExperienceRate_AL0" $expFileValue
    Set-KeyValue $f "AddExperienceRate_AL1" ([int]($expFileValue * 1.1))
    Set-KeyValue $f "AddExperienceRate_AL2" ([int]($expFileValue * 1.2))
    Set-KeyValue $f "AddExperienceRate_AL3" ([int]($expFileValue * 1.3))
}

Write-Host "`n=== 2) Resets: conservar stats + $ResetPoints puntos, nivel $ResetLevel ==="
$cmdFiles = @(
    (Join-Path $MuServer "GameServer\DATA\GameServerInfo - Command.dat"),
    (Join-Path $MuServer "GameServerCS\DATA\GameServerInfo - Command.dat")
)
foreach ($f in $cmdFiles) {
    Set-KeyValue $f "CommandResetType" 0          # 0 = conserva stats
    foreach ($al in 0..3) {
        Set-KeyValue $f "CommandResetLevel_AL$al" $ResetLevel
        Set-KeyValue $f "CommandResetPoint_AL$al" $ResetPoints
    }
}

Write-Host "`n=== 3) ExperienceTable.txt (neutral, el rate va en AddExperienceRate) ==="
$expTable = Join-Path $MuServer "Data\Util\ExperienceTable.txt"
$expContent = @"
//MinLevel   MaxLevel   MinMasterLevel   MaxMasterLevel   MinReset   MaxReset   MinMasterReset   MaxMasterReset   ExperienceRate
 1           400        *                *                0          50         *                *                100
 1           400        *                *                51         150        *                *                100
 1           400        *                *                151        350        *                *                100
 1           400        *                *                351        500        *                *                100

end
"@
Set-Text $expTable ($expContent -replace "`r`n","`n")
Write-Host "  [OK]   ExperienceTable.txt reescrito"

Write-Host "`n=== 4) ResetTable.txt (nivel $ResetLevel, $ResetPoints puntos) ==="
$resetTable = Join-Path $MuServer "Data\Util\ResetTable.txt"
$resetContent = @"
//MinReset   MaxReset   FREE        VIP BRONZ   VIP SILVE   VIP GOLD    Money_AL0   Money_AL1   Money_AL2   Money_AL3   Point_AL0   Point_AL1   Point_AL2   Point_AL3
  0          50         $ResetLevel         $ResetLevel         $ResetLevel         $ResetLevel         35000000    30000000    25000000    20000000    $ResetPoints       $ResetPoints       $ResetPoints       $ResetPoints
  51         150        $ResetLevel         $ResetLevel         $ResetLevel         $ResetLevel         35000000    30000000    25000000    20000000    $ResetPoints       $ResetPoints       $ResetPoints       $ResetPoints
  151        350        $ResetLevel         $ResetLevel         $ResetLevel         $ResetLevel         35000000    30000000    25000000    20000000    $ResetPoints       $ResetPoints       $ResetPoints       $ResetPoints
  351        500        $ResetLevel         $ResetLevel         $ResetLevel         $ResetLevel         35000000    30000000    25000000    20000000    $ResetPoints       $ResetPoints       $ResetPoints       $ResetPoints

end
"@
Set-Text $resetTable ($resetContent -replace "`r`n","`n")
Write-Host "  [OK]   ResetTable.txt reescrito"

Write-Host "`nListo. Reinicia el GameServer y el GameServerCS para aplicar los cambios."
