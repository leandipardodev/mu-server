# Comandos del servidor (jugadores y administradores)

> Servidor: MuEmu Season 2 (1.02r). Los comandos se escriben en el chat, empezando con `/`.

---

## 1. Tu personaje administrador

Tu personaje **`Nega`** (cuenta `lean009`) tiene **nivel de GM = 64**, así que puede usar
**todos** los comandos de administrador.

El nivel de GM se define en:

```
MuServer\Data\Util\GameMaster.txt
```

Formato: `"Cuenta" "Personaje" Nivel`, y se termina con `end`:

```
//Account         Name         Level
"lean009"        "Nega"       64
end
```

> ⚠️ **Este archivo se lee solo cuando arranca el GameServer.**
> Si agregás o cambiás un GM, hay que reiniciar el GameServer
> (doble clic en `RECARGAR-GAMESERVER.cmd` **como administrador**).

> ⚠️ `MEMB_INFO.AccountLevel` **no** es el nivel de GM: ese campo es el nivel VIP.

### Niveles de GM usados por el servidor

| Nivel | Qué permite |
|------:|-------------|
| 8 | Comandos "básicos" de GM (moverse, avisos, skins, etc.) |
| 32 | Comandos "poderosos" (`/make`, `/setmoney`, `/disconnect`) |
| 64 | Todo lo anterior (es el nivel que tenés) |

---

## 2. Comandos de administrador (GM)

Se configuran en `MuServer\GameServer\DATA\GameServerInfo - Command.dat`.
La columna **Nivel** es el mínimo de GM necesario.

| Comando | Nivel | Sintaxis | Qué hace |
|---|---:|---|---|
| `/gmmove` | 8 | `/gmmove <personaje> <mapa> <x> <y>` | Teletransporta a otro personaje al mapa y coordenadas indicados |
| `/gmpost` | 8 | `/gmpost <mensaje>` | Manda un aviso global "de GM" |
| `!` | 8 | `! <mensaje>` | Aviso global en pantalla. **Es `!` solo, no `/notice`** (`CommandNoticeSwitch = 1`) |
| `/skin` | 8 | `/skin <personaje> <número>` | Cambia el aspecto (skin) de un personaje |
| `/hide` | 8 | `/hide <0\|1>` | Modo invisible (`1` = oculto, `0` = visible) |
| `/track` | 8 | `/track <personaje>` | Sigue / apunta a un personaje |
| `/trace` | 8 | `/trace <personaje>` | Te teletransporta **hasta** ese personaje |
| `/fireworks` | 8 | `/fireworks <mapa> <x> <y>` | Lanza fuegos artificiales en esa posición |
| `/disconnect` | 32 | `/disconnect <personaje>` | Desconecta a un jugador |
| `/make` | 32 | `/make <seccion> <tipo> <nivel> <skill> <luck> <option> <exc> <set>` | Crea un ítem en el inventario |
| `/makeset` | 32 | `/makeset <tipo> <nivel> <skill> <luck> <option> <exc> <set>` | Crea un set completo |
| `/setmoney` | 32 | `/setmoney <personaje> <zen>` | Le fija el zen a un personaje |
| `/readd` | — | `/readd` | Recalcula/reasigna los puntos de stats del personaje |

### Notas prácticas (probadas en el log del servidor)

- `/gmmove` acepta el **número de mapa** (`0` = Lorencia, `2` = Devias, `6` = Stadium/Arena, etc.)
  o el **nombre** del mapa. Ejemplos reales que funcionaron:
  - `/gmmove Nega 0 125 125`
  - `/gmmove Nega 2 30 30`
- `/skin` necesita el **nombre** y el **número**: `/skin Nega 13`.
- `/hide` lleva un **estado**, no un nombre: `/hide 1` (oculto), `/hide 0` (visible).
- `/fireworks` **no** funciona solo: hay que darle mapa y coordenadas.
- `/make` y `/makeset` piden **muchos** parámetros; si te falta uno, el comando falla.
  El formato de ítem es `seccion` + `tipo` (por ejemplo `7 5`).

---

## 3. Comandos de jugador (para todos)

Los nombres reales salen de `MuServer\Data\Command.txt` (son los que el servidor compara
en el chat). Las reglas salen de `GameServerInfo - Command.dat` + `Data\Util\ResetTable.txt`.

| Comando | Sintaxis | Qué hace | Requisitos en este servidor |
|---|---|---|---|
| `/move` | `/move <mapa>` | Teletransporta al mapa/muelle | Depende del mapa (`MuServer\Data\Move\Move.txt`): algunos piden nivel o zen. Los nombres son los del menú de movimiento del cliente |
| `/post` | `/post <mensaje>` | Mensaje global | Nivel 1, gratis, 1 segundo de espera entre mensajes |
| `/reset` | `/reset` | Reset del personaje | Nivel **400**, **35M de zen** (VIP Bronce 30M / Plata 25M / Oro 20M), +**1000 puntos**, límite 500 resets |
| `/pk` | `/pk` | Limpia el estado PK (los asesinos) | **50M de zen** (VIP: 45M / 40M / 20M). El token es `/pk`, **no** `/limparpk` |
| `/a` | `/a` | Reparte puntos de stats | `CommandAddPointSwitch = 1`. Con `CommandAddPointAutoEnable = 1` los puntos se reparten solos |
| `/bau` | `/bau <número>` | Cambia de baúl (depósito) | Baúles disponibles: 2 (normal), 5 (VIP Bronce), 10 (Plata), 50 (Oro) |
| `/store` | `/store` | Abre tu tienda personal | — |
| `/offstore` | `/offstore` | Deja la tienda personal abierta al desconectarte | — |
| `/attack` | `/attack` | Activa el **ataque automático** | — |
| `/offattack` | `/offattack` | Ataque automático **mientras estás desconectado** | Cuesta zen (`CustomAttackOfflineRequireMoney` en `GameServerInfo - Common.dat`) |
| `/pick` | `/pick <ítem>` | Recoge solo un ítem del suelo (zen, bless, soul, chaos, life, creation, gem, moon, wing…) | Lista en `MuServer\Data\Custom\CustomPick.txt` |
| `/evo` | `/evo` | Evolución / cambio de clase | Probarlo en nivel 150 (mensaje del servidor: *"Has evolucionado con éxito"*) |
| `/re` | `/re` | Reset automático on/off | Mensajes 116-117 de `Message.txt` |
| `/war` | `/war <guild>` | Declarar guerra de guilds | Comando de Dark Lord / guild |
| `/soccer` | `/soccer` | Evento pelota (fútbol) | Solo si el evento está activo |
| `/zen` | — | **Desactivado** (`CommandMoneySwitch = 0`) | — |
| `/c` | — | **Desactivado** (`CommandChangeSwitch = 0`) | — |
| `/mreset` | — | **Desactivado** (`CommandMasterResetSwitch = 0`) | Season 2 no tiene master level |
| `/f` `/v` `/e` | — | Alias del repack **sin documentar** | Probarlos; no tienen mensajes ni configuración |

### Comandos que maneja el **cliente** (ayuda F1)

Estos no están en `Command.txt` porque los resuelve el cliente; funcionan igual:

| Comando | Qué hace |
|---|---|
| `/trade` | Comerciar con el jugador que estás apuntando |
| `/party` | Invitar a party |
| `/guild` | Invitar a guild |
| `/war <guild>` | Declarar guerra de guild |
| `/whisper on` / `/whisper off` | Activar/apagar susurros privados |
| `/filter <palabra>` | Ver solo los chats que contengan esa palabra |
| `/personal store` | Abrir tienda personal |
| `/view store on` / `/view store off` | Ver tiendas de otros |
| `/buy` | Comprar de la tienda que estás mirando |
| `/duelchallenge` / `/duelcancel` | Desafiar a duelo / cancelar |
| `/exchange` | Intercambiar (Chaos?) |
| `/firecracker` | Petardo |
| `/scissor` / `/rock` / `/paper` | Piedra, papel o tijera |
| `/<nombre de ítem>` | Muestra la info de ese ítem |
| `/website` / `/alliance` | Web del servidor / alianza de guilds |
| `/move <mapa>` | Igual que el del servidor |

> **Tip:** el reset **no** exige sacarte los ítems (`CommandResetCheckItem = 0`), y los
> puntos se mantienen (`CommandResetType = 0`). Después de cada cambio en `Command.dat`
> hay que reiniciar el GameServer (`RECARGAR-GAMESERVER.cmd`).

---

## 4. Activar / desactivar comandos

Todo se controla en:

```
MuServer\GameServer\DATA\GameServerInfo - Command.dat
```

Ejemplos:

- Desactivar un comando: `CommandMakeSwitch = 0`
- Cambiar el nivel de GM necesario: `CommandMakeGameMasterLevel = 32`
- Reset: `CommandResetLevel_AL0 = 400`, `CommandResetPoint_AL0 = 1000`
- `/reset` mantiene stats porque `CommandResetType = 0`

> Después de tocar este archivo hay que reiniciar el GameServer (`RECARGAR-GAMESERVER.cmd`).

### ¿Qué significa `_AL0`, `_AL1`, `_AL2`, `_AL3`?

Son los 4 **niveles de cuenta (VIP)**. Cada jugador usa la fila que corresponde a su
`MEMB_INFO.AccountLevel`. `_AL0` = jugador normal.

---

## 5. GMs que vinieron en el repack (ya limpiados)

`GameMaster.txt` traía 3 GMs de prueba del autor (`franky`, `gmem`, `fsmatheus`) que
**no existen** en tu base de datos. Ya se borraron (respaldo: `GameMaster.txt.bak`).
El archivo quedó así:

```
//Account         Name         Level
"lean009"        "Nega"       64
end
```

---

## 6. ¿Y los comandos `/arena1`, `/hunt`, `/bar`, `/bank`...?

Figuran en `Command.txt` (índices 188–209) pero **no están implementados**: la carpeta
`MuServer\Data\Script\Bridge\` está vacía y `ScriptMain.lua` no los define.
Si querés alguno de esos comandos, hay que escribirlo en Lua (`ScriptMain.lua`).
