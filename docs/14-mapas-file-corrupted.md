# Error "file corrupted" al entrar a un mapa (Arena / Stadium)

## Síntoma

Al usar `/move stadium` (o al entrar a cualquier mapa nuevo) el cliente muestra:

```
Data\World7\EncTerrain7.att file corrupted.
```

y se cierra.

## Por qué pasa

El cliente (`MapManager.cpp`) abre los 3 archivos del mapa en este orden:

1. `EncTerrainN.map`
2. `EncTerrainN.att`
3. `EncTerrainN.obj`

Cada archivo tiene una **cabecera**: byte 0 = versión, **byte 1 = número de mapa**.

Después de abrirlo, el cliente compara el número de mapa del archivo con el número
del mundo (`N`). Si no coinciden, muestra `"archivo corrupto"` y cierra.

> O sea: en `Cliente\Data\World7\EncTerrain7.att`, el **byte 1 tiene que valer `7`**.
> En el repack valía `6`, y por eso fallaba.

## Qué archivos estaban mal en este repack

| Carpeta | Archivo | Byte 1 tenía | Debía tener |
|---|---|---|---|
| `World7` (Arena) | `EncTerrain7.att` | `06` | `07` |
| `World11` | `EncTerrain11.att` | `0A` | `0B` |
| `World12` | `EncTerrain12.att` | `0B` | `0C` |
| `World6` | los 3 archivos | mixto | (mapa sin uso; se dejó igual) |

Los demás mundos estaban bien.

## Cómo se arregla

```
RECARGAR-GAMESERVER.cmd   (como administrador)  -> recarga el terreno del servidor
```

y para el cliente:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\arreglar-world7.ps1 -World 7
```

El script:

1. Restaura los originales del repack desde `_bak_repack_terrain\` (si existe).
2. Descifra el `.att` (clave de mapa + XOR `FC CF AB`).
3. Cambia el byte 1 al número del mundo.
4. Lo vuelve a cifrar y verifica que los **tiles no cambiaron** (solo la cabecera).

Para otro mapa, cambiá el número:

```powershell
... -File scripts\arreglar-world7.ps1 -World 11
... -File scripts\arreglar-world7.ps1 -World 12
```

## Extra: el terreno del servidor

El cliente decide **cómo se ve** el mapa; el servidor decide **dónde se puede caminar**.
Si el terreno del servidor (`MuServer\Data\Terrain\Terrain7.att`) no coincide con el del
cliente, el personaje se traba contra paredes invisibles.

En este proyecto ya se alineó `Terrain7.att` para que sea **idéntico** al del cliente
(0 diferencias en 65536 tiles). El original quedó guardado como `Terrain7.att.bak`.

> El servidor usa estos archivos con un encabezado de **3 bytes** (`00 FF FF`),
> mientras que el cliente usa **4 bytes** (`00 07 FF FF`).

## Otro caso: archivos `.att` de 128 KB (2 bytes por tile)

Además del número de mapa equivocado, hay mapas que fallaban por el **tamaño** del `.att`.

Este cliente 1.02.44 usa el formato clásico: **65.540 bytes** (cabecera de 4 + 1 byte por tile).
Pero el repack traía estos mapas en formato "moderno" de **131.076 bytes** (2 bytes por tile):

| Carpeta | Mapa | Nombre |
|---|---|---|
| `World32` | 31 | Land of Trials |
| `World34` | 33 | Aida |
| `World35` | 34 | Crywolf |
| `World38` | 37 | Kanturu 1 |
| `World39` | 38 | Kanturu 2 |
| `World40` | 39 | Kanturu 3 |
| `World55` | 54 | (sin uso) |
| `World56` | 55 | (sin uso) |

Al entrar a esos mapas el cliente mostraba `file corrupted` y se cerraba.

**Solución aplicada:** convertir esos `.att` al formato de 65.540 bytes, tomando el byte bajo
de cada tile (el byte alto era `0` en todos, así que la conversión **no pierde nada**).
El original quedó guardado al lado como `EncTerrainN.att.128KB.bak`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\convertir-att-128kb.ps1 -QueHacer convertir
```

El script se saltea solo los mapas cuyos tiles tengan el byte alto distinto de 0
(`World31` y `World56` tienen "banderas"/safe-zone), porque ahí sí habría pérdida.

## El menú de transporte lo define el CLIENTE (`MoveReq.bmd`)

El menú de "mover a" del juego **no** se arma con `MuServer\Data\Move\Move.txt`.
Son dos listas distintas:

| Lado | Archivo | Qué hace |
|---|---|---|
| Servidor | `MuServer\Data\Move\Move.txt` | a qué mapa/coordenadas te manda cada índice |
| Cliente | `Cliente\Data\Local\MoveReq.bmd` | qué entradas se ven en el menú (índice, nombre, nivel, zen) |

Por eso `Crywolf` funcionaba con `/move Crywolf` pero no aparecía en el menú:
el servidor tenía el índice `26`, pero el BMD del cliente solo traía 28 entradas
(no estaban ni `Arena` ni `Crywolf`).

Formato verificado del `MoveReq.bmd`:

```
offset 0        : int32 cantidad de entradas (sin cifrar)
desde offset 4  : entradas de 80 bytes, cifradas con XOR FC CF AB
                  reiniciando el índice de la clave en CADA entrada
entrada:
  +0  int32   índice (el que el cliente manda al servidor)
  +4  char[32] nombre
  +36 char[32] nombre (segunda copia)
  +68 int32   nivel mínimo
  +72 int32   zen
  +76 int32   nivel mínimo (repetido)
```

Para agregar una entrada (ya se agregó `Crywolf`, índice 26):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\moverequest-agregar.ps1 -Listar
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\moverequest-agregar.ps1 -Index 26 -Nombre "Crywolf" -Nivel 190 -Zen 14000 -DespuesDe 25
```

El respaldo del original queda como `MoveReq.bmd.bak`.

## Mapas que "viven" en el otro GameServer (Castle Siege)

`MuServer\Data\MapServerInfo.dat` decide qué mapas atiende cada GameServer:

```
ServerCode  MapServerGroup  InitSetVal  IpAddress      Port
0           0               1           S192.168.0.85  55901   <- Principal
19          0               0           S192.168.0.85  55920   <- Castle Siege

ServerCode  NotMoveOption  NextMap  NextServerCode
0           0               30       19      <- Valley of Loren (mapa 30) -> CS
0           0               31       19      <- Land of Trials (mapa 31)  -> CS
0           0               34       19      <- Crywolf (mapa 34)         -> CS
0           0               41       19
0           0               42       19
```

O sea: **"Valley of Loren" es el mapa 30 y es el campo de batalla de Castle Siege**,
no un mapa de caza libre. Cuando pedís ir a un mapa de esos, el cliente **se cambia
de servidor** (de 55901 a 55920). Si ese segundo servidor no está levantado o el mapa
no carga, el cliente se cae y el personaje queda "conectado" unos segundos.

`Valley of Loren` (30) y `Land of Trials` (31) están en el menú de transporte de
**Castle Siege**, no en el menú normal. `Deep Loren` **no existe en este repack**
(no hay carpeta `World*`, ni terreno, ni nombre en los textos del cliente).

Si querés cazar en Crywolf sin pasar por el servidor de CS, sacá la línea `0 0 34 19`
(y su inversa `19 1 34 -1`) de `MapServerInfo.dat` y reiniciá todo. Así el mapa 34
lo atiende el servidor principal.

## Restaurar un mapa editado (ej. Lorencia)

Si se editó un mapa con el editor (`MU World Editor Studio`) y quedó raro, lo más limpio
es volver al archivo original del repack, que sigue estando en el ZIP del cliente:

```
C:\Users\leand\Downloads\Client-1.02.44.zip
```

```powershell
# solo comparar (no toca nada)
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\restaurar-world1-original.ps1 -QueHacer comparar

# restaurar de verdad
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\restaurar-world1-original.ps1 -QueHacer restaurar
```

Qué hace:

1. Compara **todos** los archivos de `World1` contra el ZIP (por SHA-256).
2. Restaura los que cambiaron (`EncTerrain1.att/.map/.obj`, `TerrainLight.OZJ`, `TerrainHeight.OZB`...).
3. Mueve a `World1\_artefactos_editor\` los archivos que el editor agregó
   (`Terrain1.att`, `(Server)Terrain1.att`, `EncTerrain1.128KB.att`, `mws_fences.txt`,
   `TerrainLight.OZB`, `TerrainLight.jpg`).
4. Guarda copia del estado anterior en `World1\_bak_edicion_usuario\`.

> El editor toca también `TerrainLight.OZJ` (luces) y `TerrainHeight.OZB` (alturas).
> Por eso un mapa puede cargar sin error pero verse mal (oscuro, plano, sin objetos).

Para comparar **todo** el cliente contra el ZIP original:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\comparar-cliente-original.ps1
```

## Tercer caso: `EncTerrain351.att file not found` (mapas con 2 terrenos)

Este cliente usa, para algunos mapas de evento, **más de un juego de terreno**:

```
EncTerrain<world>.<att|map|obj>    <- terreno normal
EncTerrain<world><variante>.<ext>  <- terreno alternativo (estado de evento)
```

Ejemplos que ya venían en el repack:

| Carpeta | Archivos normales | Variantes |
|---|---|---|
| `World31` (Valley of Loren / CS) | `EncTerrain31.att`... | `EncTerrain312.att` (variante 2) |
| `World40` (Kanturu 3) | `EncTerrain40.*` | `EncTerrain401.att/.map/.obj` (variante 1) |
| `World35` (Crywolf) | `EncTerrain35.*` | **ninguna** ← error del repack |

Al entrar a Crywolf el cliente pide `Data\World35\EncTerrain351.att` y, como el repack
no lo trae, tira `file not found` y se cierra.

La cabecera de la variante sigue la misma regla: **byte 1 = número de mundo**
(en `EncTerrain351.att` el byte 1 es `23` hex = 35).

**Solución:** copiar los archivos base a los nombres de la variante que falta:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\crear-variante-terreno.ps1 -World 35 -Variante 1 -QueHacer listar
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\crear-variante-terreno.ps1 -World 35 -Variante 1 -QueHacer crear
```

Quedan así (ya hecho en este proyecto):

```
World35\EncTerrain351.att   65.540 b
World35\EncTerrain351.map  196.610 b
World35\EncTerrain351.obj  199.324 b
```

> Si otro mapa tira `file not found` con un nombre de 3 cifras (ej. `EncTerrain401.att`,
> `EncTerrain312.att`), es el mismo caso: fijate qué mundo y qué variante pide el error
> y corré el script con esos números.
>
> También se convirtió `EncTerrain401.att` (Kanturu 3 variante 1) al formato de 64 KB,
> porque seguía en 128 KB.

## Si aparece otro "file corrupted"

1. Mirá qué archivo nombra el error (`...\WorldN\EncTerrainN.xxx`).
2. Ese archivo es el primero que falló (puede haber más detrás).
3. Corré:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\terrain-scan.ps1 -Root "Cliente\Data"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\terrain-scan-all.ps1
```

`terrain-scan.ps1` revisa todos los `EncTerrain*.att` y te dice cuáles tienen el número de
mapa equivocado o tiles inválidos (`>= 128`).
`terrain-scan-all.ps1` además revisa `.map` y `.obj`, y avisa si el `.att` no es de 65.540 bytes.

## Cuando el error te deja el personaje "conectado"

El cartel de error **no cierra el juego**: el proceso queda vivo con el cartel abierto y la
conexión sigue abierta, así que el servidor te sigue viendo online y no te deja volver a entrar.

Solución: cerrá el cartel y el juego (o matá `main.exe` desde el Administrador de tareas).
Si aun así queda trabado, esperá ~1 minuto o reiniciá el GameServer.
