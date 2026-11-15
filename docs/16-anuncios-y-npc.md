# Anuncios y vida a los NPC

> Servidor MuEmu Season 2 (1.02r). Todo lo de esta guía se aplica con un solo script:
> `scripts\aplicar-anuncios.ps1` (no necesita administrador).

---

## 1. Dónde anuncia el servidor (4 lugares)

| Lugar | Archivo | Cuándo se ve |
|---|---|---|
| Avisos rotativos en pantalla | `MuServer\Data\Util\Notice.txt` | Cada X segundos, para todos, con color |
| Bienvenida al entrar | `MuServer\Data\Message.txt` (índice **256**) | Al loguear el personaje |
| Saludo del NPC al clickearlo | `MuServer\Data\Script\ScriptMain.lua` (tabla `NPC_SALUDOS`) | Cada vez que clickeás un NPC |
| Diálogo del NPC (burbuja) | `Cliente\Data\Local\Dialog.bmd` | Cada vez que clickeás un NPC |

Los dos primeros son **servidor** (hay que reiniciar el GameServer).
Los dos últimos son **cliente** (`Dialog.bmd`) o **servidor con Lua**
(`ScriptMain.lua`), y el cliente hay que reiniciarlo para ver el `Dialog.bmd`.

---

## 2. Avisos rotativos — `Notice.txt`

Formato (separado por tabs), una línea por aviso y `end` al final:

```
"Mensaje"   Type  Count  Opacity  Delay  R  G  B  Speed  RepeatTime
```

- `R G B` = color (0-255).
- `RepeatTime` = cada cuántos segundos vuelve a salir ese aviso.
- `Type` = 10 a 15 en el repack original (se dejó igual).

Config actual (6 avisos que rotan). Explican **solo lo particular de este
servidor**: `/move` y `/post` se sacaron porque ya son conocidos.

| # | Aviso | Color | Repite |
|---|---|---|---|
| 1 | `Reset: nivel 400 + 35M de zen = +1000 puntos. Mantenés los stats.` | amarillo | 20 s |
| 2 | `/pick zen junta el zen solo. También /pick bless, /pick soul.` | cian | 45 s |
| 3 | `/offattack: tu pj sigue peleando desconectado (gasta zen).` | verde | 62 s |
| 4 | `/store abre tu tienda; /offstore la deja abierta al salir.` | naranja | 73 s |
| 5 | `/bau 1 y /bau 2: cambiá de baúl para guardar más ítems.` | lila | 120 s |
| 6 | `/pk limpia el estado asesino (50M de zen). Los GM avisan con !` | rosa | 180 s |

**Para cambiarlos:** editá `scripts\textos-cliente\notice.txt` (UTF-8, campos
separados por `|`) y corré:

```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\aplicar-textos-cliente.ps1
```

Ese mismo script aplica los tips de `Slide.bmd` y las descripciones de
`Text.bmd` (ver `docs/17`). Guarda backups con fecha y mantiene los tamaños.

---

## 3. Bienvenida al entrar — `Message.txt` índice 256

```
256       "¡Bienvenido %s a Mu Nega! Tip: /reset en 400, /pick zen, /store"
```

`%s` = nombre del personaje.

El aviso de entrada del Lua (`ScriptMain.lua` → `OnCharacterEntry`) quedó alineado:

```
Tips: /reset en 400 - /pick zen - /store - /offattack
```

> El repack traía `"¡Bienvenido %s al servidor OnlySkill!"` (marca vieja del autor).

### Otros índices de `Message.txt` (arreglo del `Could not find message N!`)

El archivo del repack solo llegaba al índice **267**, pero el `GameServer.exe`
usa además:

| Índice | Cuándo sale | Texto aplicado |
|---:|---|---|
| **338** | al entrar al juego (era el `Could not find message 338!`) | `Bienvenido a Mu Nega - Temporada 2` |
| 800 / 801 | evento bonus (empieza / termina) | `Evento bonus activo: experiencia extra` / `El evento bonus ha terminado` |
| 802 / 803 / 804 | invasión (aparecen / se retiran / jefe) | `Invasión: aparecieron los monstruos` / `... se retiraron` / `El jefe de la invasión apareció` |

- Fuente editable: `scripts\textos-cliente\mensajes-servidor.txt` (UTF-8, `indice|texto`).
- Se aplican con `scripts\aplicar-mensajes-servidor.ps1`, que reescribe el
  `Message.txt` ordenado y completo (207 mensajes, 0..804) con backup.
- `Message.txt` se lee **al arrancar el GameServer**: hace falta
  `RECARGAR-GAMESERVER.cmd` (admin) para verlo.
- Si aparece otro número, se agrega la línea a ese `.txt` y se vuelve a correr el
  script.

---

## 4. Saludos de NPC — `ScriptMain.lua` (Lua del servidor)

`OnNpcTalk(aIndex, bIndex)` se dispara cuando el cliente "habla" con un NPC.
`bIndex` puede venir como **índice de objeto**; el script lo resuelve con
`GetObjectType()` y busca el saludo por **tipo de NPC** (`Monster.txt`, columna `Type`):

```lua
local NPC_SALUDOS = {
    [238] = "Combino ítems: Joya del Caos + zen + ítem.",
    [253] = "¡Pociones frescas! Tip: /pick zen ahorra tiempo.",
    ...
}
```

Ya cargados: Trainer (226), Marlon (229), Alex (230), Pet Trainer (234),
Sebina (235), Golden Archer (236), Charon (237), Chaos Goblin (238), Arena Guard (239),
Baz (240), Guild Master (241), Elf Lala (242), Wizard (245), Zienna (246),
PK Clear Guard (249), Martin (250), Hanzo (251), Potion Girl (253), Pasi (254),
Lumen (255), Luke (258) y Oracle Layla (259).

**Cómo funciona el saludo:** se manda como aviso en el chat (`NoticeSend`, tipo 1).

**Para agregar uno:** sumá una línea `[tipo] = "texto",` a `NPC_SALUDOS` en
`scripts\scriptmain-nuevo.lua` y corré el script.

> Si un NPC no dice nada al clickearlo, primero fijate que su tipo esté en la tabla y
> que el `bIndex` esté llegando (ver sección 7). Si el cliente no manda el paquete de
> "hablar" (pasa con algunas tiendas), ese NPC solo se puede tocar por `Dialog.bmd`.

---

## 5. Diálogos del NPC — `Dialog.bmd`

Formato descubierto (esto no estaba documentado en ningún lado):

```
Cliente\Data\Local\Dialog.bmd
  - 200 entradas de 1024 bytes (204.800 bytes en total)
  - cada entrada está cifrada con XOR (FC, CF, AB) repitiendo,
    empezando de nuevo desde el byte 0 de CADA entrada
  - texto ANSI (1252), terminado en 0x00
```

El script `scripts\editar-dialog-bmd.ps1` lee `scripts\dialog-textos.txt` con líneas
`INDICE|TEXTO`, cifra y escribe el archivo. Guarda el original en `Dialog.bmd.bak`.

Entradas ya traducidas al español (0 a 9): vendedora de pociones, Pasi, Baz (x2),
el NPC del arpa, el de la Chaos Machine, el de bienvenida, la guía de Lorencia,
la de Noria y el de la web.

> ⚠️ **No se sabe con certeza qué NPC usa cada índice.** Se identificaron por el texto
> original en inglés. Las entradas 50-82 y 100-143 son textos de las misiones de
> cambio de clase (nivel 150 y 220): **no se tocaron**.

---

## 6. Aplicar todo

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\aplicar-anuncios.ps1
```

El script:

1. `Notice.txt` (respaldo `.bak`)
2. `Message.txt` índice 256 (respaldo `.bak`)
3. `ScriptMain.lua` (respaldo `.bak2`)
4. `Dialog.bmd` (respaldo `.bak`)

Después:

- **Servidor:** `RECARGAR-GAMESERVER.cmd` **como administrador** (o `INICIAR-SERVIDOR.cmd`
  si estaba apagado).
- **Cliente:** cerrar y abrir con `JUGAR.cmd`.

---

## 7. Si algo no se ve

| Síntoma | Causa probable | Solución |
|---|---|---|
| No sale ningún aviso rotativo | El GameServer no se reinició | `RECARGAR-GAMESERVER.cmd` |
| Sale la bienvenida vieja ("OnlySkill") | Falta reiniciar el GameServer | idem |
| Un NPC no dice nada | Ese NPC no manda `OnNpcTalk` (tiendas) | Usar `Dialog.bmd` |
| Los diálogos salen en inglés | Falta reiniciar el cliente | `JUGAR.cmd` |
| Los diálogos salen con símbolos raros | El texto se guardó en UTF-8 | Volver a correr el script (convierte a ANSI) |
| El servidor no arranca después de tocar Lua | Error de sintaxis en `ScriptMain.lua` | Restaurar `ScriptMain.lua.bak2` |

### Ver qué llega a `OnNpcTalk` (debug)

Si querés saber qué número manda cada NPC, poné esto temporalmente en `ScriptMain.lua`:

```lua
function OnNpcTalk(aIndex,bIndex)
    NoticeSend(aIndex,1,string.format("NPC debug: obj=%d tipo=%d", bIndex, GetObjectType(bIndex)))
    return 0
end
```

Reiniciás el GameServer, clickeás el NPC y leés el número en el chat. Con eso se
completa la tabla `NPC_SALUDOS` con los tipos exactos.
