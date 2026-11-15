# El servidor en detalle

> Documento de referencia: qué trae este repack, comandos, rates, eventos y
> **todo lo que NO está en el MU clásico** (customs).
> Última actualización: 2026-11-11

---

## 1. ¿Qué es este servidor?

| Tema | Valor |
|---|---|
| Emulador | **MuEmu Season 2 (1.02r) + Unstable Moon** |
| Cliente | MU **1.02.44** (parcheado con `update 1.0`) |
| Autor / foro | "Reject" — TuServerMu `topic=386.0` |
| Motor | MuEmu (el mismo linaje que IGCN/Matrix) |
| Base de datos | **SQL Server**, 1 base `MuOnline` (`.bak`) |
| Licencia | Por **HardwareId** (tu PC) |

> Aunque la base es **Season 2**, el motor tiene **mucho código de Seasons
> posteriores** activado (Summoner, 380, Harmony, Gens, Master Reset…). Es un
> híbrido: "clásico" de sabor, pero con features modernas.

---

## 2. Arquitectura y componentes

| Componente | Función | Puerto |
|---|---|---|
| **ConnectServer** | Le dice al cliente a qué GameServer conectarse | 44405 |
| **JoinServer** | Login / cuentas | 55970 |
| **DataServer** | Persistencia (lee/escribe la base) | 55960 |
| **GameServer** | Lógica del juego (mundo "Principal") | 55901 |
| **GameServerCS** | Castle Siege (mundo "CastleSiege") | 55920 |
| **MHPServer** | Anti-hack / protección | 55999 |

Los arranca `INICIAR-SERVIDOR.cmd` en ese orden.

---

## 3. Clases disponibles (6)

| Clase | Código | Puntos por nivel | Notas |
|---|---|---|---|
| Dark Wizard | DW | 5 | |
| Dark Knight | DK | 5 | |
| Fairy Elf | FE | 5 | |
| Magic Gladiator | MG | **7** | Crear requiere nivel **220** |
| Dark Lord | DL | **7** | Crear requiere nivel **250** |
| Summoner | SU | **7** | ⚠️ **NO es del 1.02 base** (Season 3) |

> **Ojo:** el Summoner existe en la config. Si querés 100% clásico, se puede
> desactivar su creación.

---

## 4. Comandos

### 4.1 Comandos de jugador

| Comando | Qué hace | Requisitos / costo | Estado |
|---|---|---|---|
| `/post <mensaje>` | Mensaje global | Nivel 1, 1 seg de espera | ✅ |
| `/addpoint` | Reparte puntos de stats automáticamente | — | ✅ |
| `/pkclear` | Limpia el PK | 50M / 45M / 40M / 20M zen (según VIP) | ✅ |
| `/ware <n>` | Bóveda extra | +2 / +5 / +10 / +50 (según VIP) | ✅ |
| `/reset` | **Reset** | Nivel 400 + 35M zen | ✅ |
| `/store <bless\|soul\|chaos\|pcp>` | Tienda personal vendiendo por joyas | Nivel 30 | ✅ |
| `/offstore` | Tienda personal **offline** | Nivel 250 | ✅ |
| `/attack` | **Ataque automático** (+ auto-buff) | — | ✅ |
| `/offattack` | Ataque automático **offline** | Nivel 250 + 400k/300k/200k/100k zen | ✅ |
| `/money` | — | — | ❌ Deshabilitado |
| `/change` | Cambio de clase | — | ❌ Deshabilitado |
| `/masterreset` | Master Reset | — | ❌ Deshabilitado |

### 4.2 Comandos de GM

Requieren un **nivel de GM** (ver §10). Nivel 8:

`/gmmove`, `/post` (GM), `/track`, `/trace`, `/fireworks`, `/skin`, `/notice`, `/hide`

Nivel 32 (más alto):

`/disconnect`, `/make` (crear ítems), `/setmoney`

---

## 5. Rates y estadísticas

### 5.1 Experiencia

| Tema | Valor |
|---|---|
| Exp general | **x3000** (AL0) / x3300 (AL1) / x3600 (AL2) / x3900 (AL3) |
| Exp Master | x1 (mínimo nivel de monstruo: 95) |
| Exp en eventos | x1 |

> Recordá: en los archivos **`100` = 1x**. x3000 se escribe `300000`.

### 5.2 Monstruos y drops

| Tema | Valor |
|---|---|
| Vida de monstruos | **x5** (`MonsterLifeRate = 500`) |
| Barra de vida del monstruo | ✅ Activada |
| Drop de ítems | 15% / 16% / 17% / 18% |
| Tiempo de ítem en el suelo | 30 seg |
| Drop de dinero | rate 5; dinero en el suelo 15 seg |
| **Dinero avanzado** | `(MoneyValue × nivel del monstruo)` → 1000 / 2000 / 3000 / 5000 |

### 5.3 Personaje

| Tema | Valor |
|---|---|
| Nivel máximo | 400 |
| Máx. puntos por stat | **32767** |
| Puntos por nivel | 5 (DW/DK/FE), 7 (MG/DL/SU) |
| Reset | A nivel **400**, conserva stats, **+1000 puntos**, límite **500** |
| Auto-reset | ✅ Activado (resetea solo al llegar a 400) |

### 5.4 Joyas / Chaos Machine (éxito)

| Mezcla | Rate |
|---|---|
| Jewel of Soul | 50% |
| Jewel of Life | 50% |
| Jewel of Harmony | 50% |
| Chaos Item (ítem +11…) | 70% |
| Ala nivel 1 (Wing1) | 25% / 35% / 45% / 60% |
| Ala nivel 2 (Wing2) | 20% / 30% / 40% / 50% |
| Ala nivel 3 (Wing3) | ❌ Desactivado (-1) |
| Dinorant | 25% / 35% / 45% / 55% |
| Pet (Fenrir/Horse/Raven) | 15% / 35% / 55% / 75% |
| Fruit (clásico) | 90% |
| Ítem 380 | 50% / 55% / 60% / 65% |

> Los 4 valores son por nivel de cuenta: AL0 (Free) / AL1 / AL2 / AL3 (VIP3).

### 5.5 Otros

| Tema | Valor |
|---|---|
| Buffer de Elfa | hasta nivel **220** |
| Durabilidad | `55500` (los ítems casi no se desgastan) |
| PK | **Abierto** (`NonPK = 0`), penalización 3600 |
| Duelo | ✅ Activado |
| Trade | ✅ Activado |
| Tienda personal | ✅ Activada |
| Gremio | Crear a nivel **100**, 40/80 miembros, 5 alianzas |
| Exp en party | 100 (normal) |
| Cash Shop | ❌ Deshabilitado |
| PC Point | ❌ Deshabilitado |
| Master Skill Tree | ❌ Deshabilitado |
| Fruit (clásico MU) | Suma 1–3 pts / resta 1–9 pts |

---

## 6. Eventos

| Evento | Estado |
|---|---|
| **Blood Castle** | ✅ (máx. 10 jugadores) |
| **Chaos Castle** | ✅ (mín. 1) |
| **Devil Square** | ✅ (máx. 15) |
| **Kanturu** | ✅ |
| **Invasion Manager** (invasiones) | ✅ |
| **Bonus Manager** | ✅ |
| **Castle Siege** | ✅ (fecha corregida — ver §10) |
| Castle Deep | ❌ |
| Crywolf | ❌ |
| Illusion Temple | ❌ |
| Raklion | ❌ |

---

## 7. Base de datos

### 7.1 Tablas principales del juego

| Tabla | Contenido |
|---|---|
| `MEMB_INFO` | Cuentas (`memb___id`, `memb__pwd`, `AccountLevel`, `AccountExpireDate`) |
| `Character` | Personajes (`cLevel`, `Class`, `ResetCount`, `MasterResetCount`, `FruitPoint`, `FruitAddPoint`, `FruitSubPoint`, `CtlCode`, stats, `Money`, PK, etc.) |
| `MuCastle_DATA` | Calendario y estado de **Castle Siege** |
| `MuCastle_*` | NPCs, registro, guild list de Castle Siege |
| `RankingBloodCastle`, `RankingChaosCastle` | Rankings de eventos |
| `warehouse`, `Guild`, `GuildMember`, `OptionData`, etc. | Ítems, gremios, etc. |

Campos interesantes de `Character`:
`ResetCount`, `MasterResetCount`, `FruitPoint`, `FruitAddPoint`, `FruitSubPoint`,
`CtlCode` (nivel de GM), `WCoinMoney`, `RuudMoney`, `PCPointMoney`,
`Married`/`MarryCouple`, `PatentId`, `Avatar`.

### 7.2 CMS web (¡sorpresa!)

La base trae **~70 tablas `mw_*`** que son un **CMS web completo**:

`mw_users`, `mw_shop_items`, `mw_market_items`, `mw_auctions`, `mw_lootboxes`,
`mw_coupons`, `mw_events`, `mw_guides`, `mw_polls`, `mw_raffles`,
`mw_achievements`, `mw_patents`, `mw_streamers`, `mw_trackers`,
`mw_viptype_services`, `mw_bank_accounts`, etc.

> ⚠️ En el repack **no vienen los archivos web** (PHP/site), solo las tablas.
> Si conseguís el CMS compatible ("MWEB"/MuWeb), ya tendrías web de registro,
> mercado, rankings, etc. **Es una pista importante para la web que querés.**

---

## 8. Customs: lo que NO está en el MU base

### 8.1 En el servidor

| Custom | Qué es | Estado |
|---|---|---|
| **Custom Arena** | Arena PvP con puntajes | ❌ Desactivado |
| **Custom Event Drop** | Eventos de drop programados | ✅ |
| **Custom Store** (`/store`) | Tienda personal vendiendo por joyas | ✅ |
| **Custom Store Offline** (`/offstore`) | Tienda personal sin estar conectado | ✅ |
| **Custom Attack** (`/attack`) | Auto-ataque + auto-buff | ✅ |
| **Custom Attack Offline** (`/offattack`) | Farmeo offline | ✅ |
| **Custom RankUser** | Ranking de usuarios por resets/nivel | ✅ |
| **Monster Health Bar** | Barra de vida sobre los monstruos | ✅ |
| **Sin "recuo"** | Quita el empuje/retroceso de skills (Lightning, Cyclone, Twist, Lung, Falling, UpperCut) | ✅ |
| **`CommandResetPointRate` por clase** | Ajusta los puntos de reset por clase | ✅ (100 c/u) |

### 8.2 En el cliente

| Custom | Qué es | Config |
|---|---|---|
| **Info Bar** | Barra de información | `MainInfo.ini` → `InfoBar = 1` |
| **Barra de título con info** | Muestra nombre + nivel + resets + FPS en la ventana | `MainInfo.ini` → `[Custom]` |
| **Reconnect** | Reconexión automática | `MainInfo.ini` → `[ReconnectInfo]` |
| **F5 – Status extra** | Ventana de estado adicional (tecla F5) | — |
| **HPBar** | Barra de vida | — |
| **Custom Items** | Ítems nuevos | `Data\CustomItem.txt` |
| **Custom Wings** | Alas custom | `Data\CustomWing.txt` |
| **Custom Tooltip** | Textos personalizados en ítems | `Data\CustomTooltip.txt` |

Ítems custom detectados en el cliente:
- `Mace50` (ítem `02,050`)
- Sets custom (grupo `100` y `018`) con modelos `Male2` / `Male19`
- Alas custom: ítems `6194` y `6149` (modelo `Wing50`)

### 8.3 Features de seasons modernas presentes

- **Summoner (SU)** — clase de Season 3.
- **Ítems 380**, **Harmony**, **Socket** — Season 4.
- **Gens** (familia/rango) — Season 4.
- **Master Reset** (desactivado) y **Master Skill Tree** (desactivado).
- **WCoin / Ruud / PCPoint** — monedas modernas (en la base).

---

## 9. Herramientas incluidas (`MuServer\Tools`)

| Herramienta | Para qué |
|---|---|
| **MuMaker 1.12** | Editor de ítems/personajes (crear ítems, editar stats) |
| **GetHardwareId** | Genera el HWID para la licencia |
| **GetMainInfo** | Aplica `MainInfo.ini` y genera `Cliente\local.bmd` |
| **AH_INFO** | Anticheat (GameGuard) |

---

## 10. Notas importantes / gotchas

1. **Castle Siege — fechas.** La tabla `MuCastle_DATA` traía fechas de **2022**,
   y el GameServerCS **se cerraba** con:
   `CASTLE SIEGE DATA SETTING FAILED [0x81]`.
   **Arreglado** el 2026-11-11: `SIEGE_START_DATE = 2026-11-08`,
   `SIEGE_END_DATE = 2026-11-15`. El asedio quedó agendado para **2026-11-14 17:30**.
   Se corrige con `scripts\arreglar-castle-siege.ps1`.

2. **Nivel de GM.** Los comandos GM piden `GameMasterLevel` 8 o 32. En MuEmu eso
   se corresponde con el campo **`CtlCode` de la tabla `Character`** (y/o
   `AccountLevel`). Está **por confirmar** cuál usar — se prueba cuando crees un
   personaje.

3. **Nombres de "Fruit".** ⚠️ Ojo: el MU clásico **ya tiene** un sistema de
   *Fruit* (`FruitMixRate`, `FruitAddPoint/SubPoint` en `Common.dat` y
   `ChaosMix.dat`) que sirve para **sumar/restar puntos de stats**, y se crea en
   la Chaos Machine. **Es distinto** de tu "Fruit" custom (requisito de reset).
   Conviene **renombrar tu ítem custom** para no confundir (p. ej. "Esencia de
   Reset" / "Orbe de Reset").

4. **Lua inestable.** `ScriptMain.lua` llamaba funciones inexistentes
   (`NpcOfPresent_*`) y la carpeta `Data\Script\Bridge` está **vacía**. Se limpió
   el script (respaldo en `ScriptMain.lua.bak`).

5. **`CustomRankUser`** — el usuario confirmó que no existe/no funciona en este
   repack (aunque la config `CustomRankUserSwitch` sí está).

6. **Reiniciar tras cambios.** El GameServer lee la config **al arrancar**. Tras
   editar cualquier `.dat`/`.txt`: `DETENER-SERVIDOR.cmd` + `INICIAR-SERVIDOR.cmd`.

---

## 11. Archivos de configuración (referencia rápida)

| Archivo | Contenido |
|---|---|
| `GameServer\DATA\GameServerInfo - Common.dat` | Rates, PK, joyas, party, durabilidad, Fruit clásico |
| `GameServer\DATA\GameServerInfo - Command.dat` | Todos los comandos |
| `GameServer\DATA\GameServerInfo - Custom.dat` | Customs (store, attack, arena, rankuser) |
| `GameServer\DATA\GameServerInfo - Character.dat` | Daño, defensa, velocidad, HP/MP |
| `GameServer\DATA\GameServerInfo - ChaosMix.dat` | Rates de la Chaos Machine |
| `GameServer\DATA\GameServerInfo - Event.dat` | Eventos on/off |
| `GameServer\DATA\GameServerInfo - Skill.dat` | Skills |
| `Data\Util\ExperienceTable.txt` | Exp por rango de resets |
| `Data\Util\ResetTable.txt` | Nivel/puntos/dinero por rango de resets |
| `Data\MapManager.txt` | Rate por mapa (exp, drop) |
| `Data\Script\ScriptMain.lua` | Scripts Lua |
| `Cliente\MainInfo.ini` | IP, versión, serial, customs de UI |
