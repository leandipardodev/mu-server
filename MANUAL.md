# Manual del servidor — Mu Nega

> **Qué es esto:** el instructivo completo del servidor, escrito para que lo
> entiendas sin saber de programación. Explica **qué tiene el server, cómo
> funciona y cómo se cambia cada cosa**.
>
> **Es un manual vivo:** cada vez que aprendemos algo nuevo, se agrega acá y en
> la **bitácora** (§17). Si algo dice ⚠️ o ❓ es porque todavía no se probó en el
> juego.

**Leyenda**

| Marca | Significa |
|---|---|
| ✅ | Comprobado: funciona o está confirmado en el juego |
| ⚠️ | Está configurado así, pero falta probarlo en el juego |
| ❓ | Sin confirmar / no lo sabemos todavía |

---

## 1. Resumen en 1 minuto

| Cosa | Valor |
|---|---|
| Juego | **MU Online Season 2** (cliente **1.02.44**) |
| Emulador | **MuEmu 1.02r + Unstable Moon** (repack de TuServerMu) |
| Experiencia | **x3000** (sube muy rápido) |
| Nivel máximo | **400**, después **reset** |
| Reset | a nivel 400, cuesta **35.000.000 zen**, da **+1000 puntos**, **mantenés los stats** |
| Vida de los monstruos | **x5** (500%) |
| Drop de ítems | bajo (15 sobre 100) — es a propósito por la exp alta |
| Zen | cae poco por bicho; tope **2.000.000.000** por personaje |
| Clases | Dark Wizard, Dark Knight, Elf, Magic Gladiator, Dark Lord |
| Eventos | Blood Castle, Devil Square, Chaos Castle, invasiones y bonus |
| Apagados | Castle Siege, Crywolf, Illusion Temple, Raklion, Castle Deep |
| Máximo online | **50** cuentas a la vez |
| Idioma | español (textos, avisos, tips y descripciones) |

---

## 2. Glosario (para entender el resto)

| Palabra | Qué es, en simple |
|---|---|
| **Cliente** | El juego que abre el jugador (`Cliente\main.exe`). |
| **Servidor** | Los programas que dan vida al mundo (la carpeta `MuServer\`). |
| **SQL Server** | La base de datos: ahí viven las cuentas, personajes e ítems. |
| **GameServer** | El "cerebro": monstruos, drops, mapas, comandos. |
| **GameServerCS** | Segundo GameServer, solo para los mapas de asedio (Castle Siege). |
| **DataServer** | Guarda y lee los datos del personaje desde SQL. |
| **JoinServer** | Maneja el login de las cuentas. |
| **ConnectServer** | Le dice al cliente a qué IP y puerto conectarse. |
| **MHPServer** | Anti-hack del cliente (por ahora no se usa). |
| **Puerto** | "Puerta" numerada por donde se conectan los programas (ej. 55901). |
| **Rate** | Multiplicador. `100` = normal, `300000` = x3000. |
| **Drop** | Lo que suelta un monstruo o una caja. |
| **Reset** | Volver a nivel 1 conservando los stats, a cambio de zen y con premio de puntos. |
| **Master Level** | Niveles extra que se ganan al 400 (en este cliente casi no se ven). |
| **`.dat` / `.txt`** | Archivos de configuración del servidor (texto). |
| **`.bmd`** | Archivos empaquetados del cliente (textos, ítems, mapas). Se editan con scripts. |
| **CP1252 / ANSI** | Codificación de texto que entiende el juego (los acentos funcionan). |
| **Backup** | Copia de seguridad de un archivo antes de tocarlo. |

---

## 3. Ficha técnica completa

### 3.1 El servidor

| Ajuste | Valor | Dónde se cambia |
|---|---|---|
| Nombre del servidor | `Principal` (código 0) | `GameServerInfo - Common.dat` |
| Versión | 1.02.44 | idem |
| Puerto del juego | 55901 | idem |
| Máximo de usuarios | 50 | idem |
| Experiencia (AL0/1/2/3) | 300000 / 330000 / 360000 / 390000 → **x3000 a x3900** | idem |
| Vida de monstruos | `500` = **x5** | idem |
| Drop de ítems (AL0..3) | 15 / 16 / 17 / 18 | idem |
| Zen: `MoneyAmountDropRate` | 5 (todos los AL) | idem |
| Zen: `MoneyValue` (AL0..3) | 1000 / 2000 / 3000 / 5000 | idem |
| Tiempo del ítem en el suelo | 30 s | idem |
| Tiempo del zen en el suelo | 15 s | idem |
| Puntos por nivel | 5 (7 para MG/DL) | idem |
| Punto extra por nivel | +1 (`PlusStatPoint`) | idem |
| Límite de un stat | 32767 | idem |
| PK libre | Sí (`NonPK = 0`) | idem |
| Guild | se crea desde nivel **100** | idem |
| Joya del Alma / Vida / Harmony | 50% de éxito | idem |
| Cash Shop / PcPoint | apagados | idem |
| Master Skill Tree | activado, hasta 200 ⚠️ | idem |

### 3.2 Reset y comandos

| Ajuste | Valor |
|---|---|
| Nivel para resetear | 400 |
| Costo del reset (AL0/1/2/3) | 35M / 30M / 25M / **20M** zen |
| Puntos que da | **+1000** |
| Qué pasa con los stats | se **mantienen** (`CommandResetType = 0`) |
| Qué pasa con el nivel | vuelve a **1** |
| Límite de resets | 500 (sin límite diario/semanal/mensual real) |
| Auto-reset | activado ⚠️ (falta confirmar cuándo se dispara) |
| Costo de `/pk` | 50M / 45M / 40M / **20M** |
| Baúles (`/bau`) | 2 / 5 / 10 / **50** |

### 3.3 Niveles VIP (`AccountLevel`)

**Ojo:** `AccountLevel` **no** es nivel de GM: es el nivel VIP de la cuenta.

| | AL0 | AL1 | AL2 | AL3 |
|---|---|---|---|---|
| Exp | x3000 | x3300 | x3600 | **x3900** |
| Reset | 35M | 30M | 25M | **20M** |
| `/pk` | 50M | 45M | 40M | **20M** |
| Baúles | 2 | 5 | 10 | **50** |
| Zen por bicho (`MoneyValue`) | 1000 | 2000 | 3000 | **5000** |

Tu cuenta **`lean009` está en AL3** (el nivel más alto).

---

## 4. Prender, apagar y jugar (paso a paso)

### 4.1 Prender

1. Doble clic en **`INICIAR-SERVIDOR.cmd`** (pide permiso de administrador: aceptá).
2. Se abren **6 ventanas negras** en este orden:

| Orden | Programa | Puerto | Para qué |
|---:|---|---:|---|
| 1 | ConnectServer | 44405 | dice a dónde conectarse |
| 2 | JoinServer | 55970 | login |
| 3 | DataServer | 55960 | guarda/lee personajes |
| 4 | GameServer | 55901 | el mundo (Lorencia, Devias…) |
| 5 | GameServerCS | 55920 | mapas de asedio |
| 6 | MHPServer | 55999 | anti-hack |

3. Al final el script muestra si cada puerto quedó **LISTEN**. Si alguno dice
   `NO escucha`, esa ventana se cerró o falló.
4. **No cierres esas ventanas** mientras haya gente jugando.

### 4.2 Jugar (en tu PC)

Doble clic en **`JUGAR.cmd`**. Ese script:

1. Regenera `Cliente\local.bmd` desde `Cliente\MainInfo.ini` (con `GetMainInfo.exe`).
2. Abre el cliente.

> Si cambiás la IP del servidor, se cambia **en `MainInfo.ini`** y volvés a
> ejecutar `JUGAR.cmd`. No se toca `local.bmd` a mano.

### 4.3 Apagar

Doble clic en **`DETENER-SERVIDOR.cmd`** (admin). Cierra los 6 programas.

### 4.4 Reiniciar solo el GameServer

Cuando cambiás algo del servidor (avisos, mensajes, comandos, rates):

```
RECARGAR-GAMESERVER.cmd            -> reinicia GameServer
RECARGAR-GAMESERVER.cmd -IncluirCS -> también GameServerCS
```

### 4.5 La regla de oro

| Si cambiás… | Hay que… |
|---|---|
| Archivos del **servidor** (`.dat`, `.txt`) | reiniciar el GameServer (`RECARGAR-GAMESERVER.cmd`) |
| Archivos del **cliente** (`Text.bmd`, `Slide.bmd`, `local.bmd`…) | cerrar y abrir el juego (no se toca el server) |
| Cosas de **SQL** (cuentas, personajes) | nada, se aplica al instante |

---

## 5. Las 4 capas del proyecto

```
C:\proyectos\servidor mu\
├── MANUAL.md              <- este manual (empezá acá)
├── README.md              <- índice viejo del proyecto
├── INICIAR-SERVIDOR.cmd   <- prende todo
├── DETENER-SERVIDOR.cmd   <- apaga todo
├── JUGAR.cmd              <- abre el cliente
├── RECARGAR-GAMESERVER.cmd
├── MuServer\              <- 5) el servidor (config, mapas, monstruos, eventos)
│   ├── ConnectServer, JoinServer, DataServer
│   ├── GameServer\        <- el mundo normal
│   ├── GameServerCS\      <- mapas de asedio
│   ├── MHPServer\
│   ├── Data\              <- config compartida (mensajes, ítems, eventos, mapas)
│   └── Tools\             <- MuMaker y editores
├── Cliente\               <- 6) el juego del jugador
│   ├── main.exe, MainInfo.ini, GetMainInfo.exe
│   └── Data\              <- textos, ítems, mapas, sonidos
├── scripts\               <- automatizaciones (PowerShell) + textos fuente
├── sql\                   <- scripts SQL
└── docs\                  <- documentación detallada por tema
```

**SQL Server 2019 Express** es la base: instancia `.\SQLEXPRESS`, puerto 1433,
base **`MuOnline`** (una sola base).

| Usuario SQL | Para qué |
|---|---|
| `sa` | administrador del motor |
| `muuser` | lo usa el servidor |
| `mumaker` | lo usa MuMaker |

> Las contraseñas están en `docs/02-sql-server.md` y `docs/13-herramientas.md`.

---

## 6. Cuentas, personajes y GM

### 6.1 Crear una cuenta (forma fácil: MuMaker)

1. Abrí `MuServer\Tools\MuMaker---------------------100%\MuMaker.exe`.
2. Pestaña de cuentas → **New/Add**.
3. Completá usuario y contraseña (máximo **10 caracteres** cada uno).
4. Guardá. La cuenta ya puede loguear.
5. Si querés darle VIP, poné `AccountLevel` en 1, 2 o 3.

### 6.2 Crear una cuenta por SQL (alternativa)

```sql
INSERT INTO MEMB_INFO (memb___id, memb__pwd, memb_name, sno__numb, bloc_code, ctl1_code, AccountLevel)
VALUES ('cuenta1', 'clave123', 'cuenta1', '1111111111111111', '0', '0', 0);
```

`memb___id` = usuario, `memb__pwd` = contraseña, `bloc_code` = 0 (no bloqueada).
⚠️ Si el login falla con una cuenta hecha así, usá MuMaker: completa columnas
que el juego espera.

### 6.3 Cuentas y personajes que existen hoy

| Cuenta | AL | Personaje | Nivel | Resets | Zen |
|---|---:|---|---:|---:|---:|
| `lean009` | 3 | `Nega` | 400 | 0 | 366.497.900 |
| `lean009` | 3 | `putita` | 1 | 0 | 0 |

### 6.4 Ser GM (administrador del juego)

Se define en **`MuServer\Data\Util\GameMaster.txt`**:

```
//Account         Name         Level
"lean009"        "Nega"       64
end
```

- Nivel **64** = GM total (los comandos piden 8 o 32).
- **Se lee solo cuando arranca el GameServer.** Si lo cambiás, reiniciá.
- ⚠️ `AccountLevel` (VIP) **no** da GM: son cosas distintas.

### 6.5 Personajes

| Clase | Se crea desde |
|---|---|
| Dark Wizard, Dark Knight, Elf | nivel 1 |
| Magic Gladiator | nivel **220** |
| Dark Lord | nivel **250** |
| Summoner | el cliente 1.02 no la tiene (el server la soporta, no se puede usar) |

- Stats por nivel: **5** puntos (7 para MG/DL) + **1** extra.
- Tope por stat: **32.767**.
- Zen máximo por personaje: **2.000.000.000**.

---

## 7. Progresión: nivel, reset, frutas

### 7.1 Nivel 1 → 400

Con **x3000** de exp se sube rápido. Los monstruos tienen **5 veces más vida**,
así que pegan y aguantan más que en un server normal.

### 7.2 Reset (el corazón del servidor)

```
Nivel 400  +  35.000.000 zen  ->  /reset
```

- Volvés a **nivel 1**.
- **Mantenés los stats** (no se pierden).
- Ganás **+1000 puntos** para repartir.
- Límite: 500 resets.
- ⚠️ `CommandResetMove = 1`: al resetear te manda al pueblo.
- ⚠️ `CommandResetAutoEnable = 1`: hay auto-reset, pero no se disparó al estar
  quieto en 400; parece que se activa al subir de nivel estando en el tope.
  **Pendiente confirmar.** Mientras tanto, usá `/reset` a mano.

### 7.3 Master Level

El servidor tiene el árbol de master activado (hasta 200 niveles), pero el
cliente 1.02 es viejo y casi no lo muestra. ❓ Para más adelante.

### 7.4 Frutas

Hoy el servidor tiene las frutas configuradas así:

| Ajuste | Valor |
|---|---|
| Puntos que suma una fruta | 1 a 3 |
| Puntos que resta si falla | 1 a 9 |
| Tasa de éxito | la calcula el server |

**Pendiente de diseño:** hacer que la fruta sea parte del sistema de reset
(costo en zen + joyas) para que sea "el giro" del servidor. Ver §16.

---

## 8. Zen, drops y cajas

### 8.1 Cómo cae el zen

Cada bicho tiene un `MoneyRate` (porcentaje). El zen que suelta es, en simple:

```
zen por bicho ≈ (MoneyAmountDropRate / 100) × MoneyValue × nivel del bicho × (MoneyRate / 100)
```

Con los valores actuales (`5` y `1000`), un bicho de nivel 100 con `MoneyRate = 100`
suelta ≈ **5.000 zen**. Los bichos con `MoneyRate = 0` **no sueltan nada**.

- El zen queda en el suelo **15 segundos** (`MoneyDropTime`).
- Tope por personaje: **2.000.000.000**.
- No hay mascota que junte zen en 1.02: se usa **`/pick zen`**.
- ⚠️ **Problema conocido:** a niveles altos los bichos pagan *menos* que a
  niveles medios (el `MoneyRate` de los monstruos fuertes es bajo). Está
  diagnosticado y hay una propuesta de arreglo, sin aplicar (§16).

### 8.2 Drop de ítems

- Multiplicador global: **15** (sobre 100) → caen **pocos ítems**.
- Cada mapa tiene sus propios multiplicadores (ver §11): por ejemplo Blood
  Castle 7 y Devil Square dan **x40** de probabilidad de ítem excellent.
- El ítem queda en el suelo **30 segundos**.

### 8.3 Cajas: qué sueltan y con qué %

**Todas las cajas son el mismo ítem (`14,11`)**; lo que cambia es el **nivel**.

| Nivel | Caja | Contenido |
|---:|---|---|
| 0 | Box of Luck | **50% Jewel of Creation / 50% Jewel of Chaos** (sin zen) |
| 1 | Star of Christmas | 1000 zen + 1 ítem al azar (nivel 3-7) |
| 3 | Heart of Love | 1000 zen + 1 ítem al azar |
| 5 | Silver Medal | 1000 zen + 1 ítem al azar |
| 6 | Gold Medal | 1000 zen + 1 ítem al azar |
| 7 | Box of Heaven | 1 fruta al azar de 5 → **20% cada una** |
| 8 | Box of Kundun 1 | **200.000 zen** + 1 excellent al azar entre 76 (**1,3%** c/u) |
| 9 | Box of Kundun 2 | 1 excellent al azar entre 82 (**1,2%** c/u) |
| 10 | Box of Kundun 3 | 1 excellent al azar entre 66 (**1,5%** c/u) |
| 11 | Box of Kundun 4 | 1 excellent al azar entre 84 (**1,2%** c/u) |
| 12 | Box of Kundun 5 | 1 excellent al azar entre 58 (**1,7%** c/u) |
| 13 | Blue Heart | 1000 zen + 1 ítem al azar |

Lazos (Red/Green/Blue Ribbon) y chocolates (Pink/Red/Blue): 1000 zen + 1 ítem.
Detalle técnico y archivos: `docs/17` §2.1.

### 8.4 Joyas

| Joya | Éxito |
|---|---|
| Jewel of Soul | 50% |
| Jewel of Life | 50% |
| Jewel of Harmony | 50% |
| Agregar Luck | 25% / 20% |

---

## 9. Comandos del jugador

> Los nombres salen de `MuServer\Data\Command.txt`. Lo que **no** está en esta
> tabla es porque está apagado o es solo para GM.

| Comando | Qué hace | Costo / requisito |
|---|---|---|
| `/reset` | resetea en nivel 400 | 35M zen (20M si sos AL3) |
| `/pk` | limpia el estado asesino | 50M zen (20M AL3) |
| `/pick zen` | junta el zen del suelo automáticamente | — |
| `/pick <ítem>` | junta ese ítem (bless, soul, life…) | — |
| `/store` | abre tu tienda personal | nivel 30+ |
| `/offstore` | deja la tienda abierta al desconectarte | nivel **250+** |
| `/offattack` | el personaje sigue peleando desconectado | nivel **250+**, gasta zen (400k AL0) |
| `/attack` | activa/desactiva el ataque automático | — |
| `/bau 1` … `/bau N` | cambia de baúl (más espacio) | 2 baúles (50 si sos AL3) |
| `/move <mapa>` | teletransporte (los mapas conocidos) | — |
| `/post <texto>` | mensaje global | nivel 1, gratis |
| `/f`, `/a`, `/v`, `/e` | funciones de social/party/guild | — |
| `/evo` | evolución/reset especial del server ⚠️ | probar |
| `/re` | reconectar/volver ⚠️ | probar |
| `/war`, `/soccer` | guild war / fútbol ⚠️ | probar |
| `/hide` | esconderse (GM) | GM 8 |
| `/gmmove`, `/gmpost`, `/track`, `/trace`, `/fireworks`, `/skin` | herramientas de GM | GM 8 |
| `/make`, `/setmoney`, `/disconnect`, `/makeset`, `/readd` | GM poderoso | GM 32 |
| `! <texto>` | aviso global de GM | GM 8 |

**Apagados:** `/zen` (cambiar zen), `/c` (cambiar clase), `/mreset` (master reset).

Detalle completo y niveles: `docs/12-comandos-admin.md`.

---

## 10. Eventos y horarios

Todos los horarios son **hora del servidor** (la de tu PC).

| Evento | Cuándo | Duración | Notas |
|---|---|---|---|
| **Blood Castle** | cada 3 h: 01:00, 04:00, 07:00, 10:00, 13:00, 16:00, 19:00, 22:00 | 15 min | 8 niveles, hasta 10 jugadores |
| **Devil Square** | cada 3 h: 02:00, 05:00, 08:00, 11:00, 14:00, 17:00, 20:00, 23:00 | — | hasta 15 jugadores |
| **Chaos Castle** | cada 3 h: 03:00, 06:00, 09:00, 12:00, 15:00, 18:00, 21:00, 00:00 | 10 min | mínimo 1 jugador |
| **Invasiones** (golden) | cada hora a los **:05, :15, :25 y :50** | — | monstruos dorados por el mundo |
| **Evento bonus** | día **5** de cada mes a las **00:00** | 2 h | exp extra (+35% a +60% según VIP) |
| **Kanturu** | por estados internos ⚠️ | — | jefe Nightmare |
| **Castle Siege** | **apagado** | — | `CastleSiegeEvent = 0` |
| **Crywolf** | **apagado** | — | el mapa se puede visitar, el evento no corre |
| **Illusion Temple** | **apagado** | — | |
| **Raklion** | **apagado** | — | |
| **Castle Deep** | **apagado** | — | |

Los horarios se editan en `MuServer\Data\Event\*.dat` (BloodCastle, DevilSquare,
ChaosCastle, InvasionManager, BonusManager).

---

## 11. Mapas

Cómo funciona: `/move <nombre>` usa el menú `MoveReq.bmd` del cliente, que manda
un número; el servidor lo resuelve con `Move.txt` + `Gate.txt`.

| # | Mapa | Exp del mapa | Excellent | Notas |
|---:|---|---:|---:|---|
| 0 | Lorencia | 100% | x10 | ciudad inicial |
| 1 | Dungeon | 100% | x10 | |
| 2 | Devias | 100% | x10 | desde nivel 15 |
| 3 | Noria | 100% | x10 | ciudad élfica |
| 4 | Lost Tower | 100% | x10 | |
| 6 | Arena | **140%** | x10 | mapa de duelos, nivel 10+ |
| 7 | Atlans | 100% | x10 | |
| 8 | Tarkan | 100% | x10 | |
| 9 | Devil Square 1 | **200%** | **x40** | solo evento |
| 10 | Icarus | 100% | x20 | necesitás item para volar |
| 11-16 | Blood Castle 1-6 | 110%-160% | x10 | solo evento |
| 17 | Blood Castle 7 | **170%** | **x40** | solo evento |
| 18-23 | Chaos Castle 1-6 | 110%-160% | x10 | solo evento |
| 24-29 | Kalima 1-6 | 100% | x10 | con Lost Map / Symbol |
| 30 | Castle Siege | 100% | x10 | **GameServerCS** |
| 31 | Land of Trials | **200%** | x10 | **GameServerCS** |
| 32 | Devil Square 2 | **200%** | **x40** | solo evento |
| 33 | Aida | 100% | x10 | |
| 34 | Crywolf | **15000%** | **x200** | **GameServerCS**, evento apagado |
| 36 | Kalima 7 | 100% | x10 | |
| 37-39 | Kanturu 1-3 | 140%-150% | x10 | |

- "Exp del mapa" se multiplica por la exp global: un bicho en Devil Square da
  **2 veces** más exp que el mismo bicho en Lorencia.
- Mapas **30, 31, 34, 41 y 42** los atiende el **GameServerCS** (por eso al
  `/move` a esos mapas el cliente cambia de servidor).
- Mapas **no habilitados**: 5, 35, 40, 54 y 55.
- Si un mapa da **`file corrupted`** al entrar, mirá `docs/14`.

---

## 12. El cliente (el juego)

### 12.1 Instalar en otra PC (para un amigo)

1. Copiá la carpeta **`Cliente\`** completa.
2. Editá **`MainInfo.ini`**: la IP tiene que ser la del servidor.
3. El amigo ejecuta **`JUGAR.cmd`** (o `GetMainInfo.exe` y después `main.exe`).

> `GetMainInfo.exe` genera `local.bmd`, que es donde el cliente lee la IP.

### 12.2 Ajustes ya aplicados

| Ajuste | Archivo |
|---|---|
| Modo ventana | `_window_mode.reg` |
| Resolución 1024×768 | `1024x768.reg` |
| Idioma español | `LangSpanish.reg` |

### 12.3 Qué se puede editar y qué no

| Sí | Archivo | Guía |
|---|---|---|
| Nombres de ítems | `Data\Local\Item.bmd` | `docs/17` |
| Descripciones de ítems | `Data\Local\Text.bmd` | `docs/17` |
| Línea extra de tooltip | `Data\CustomTooltip.txt` | `docs/17` |
| Tips de pantalla de carga | `Data\Local\Slide.bmd` | `docs/17` |
| Diálogos de NPC | `Data\Local\Dialog.bmd` | `docs/16` |
| Menú de `/move` | `Data\Local\MoveReq.bmd` | `docs/14` |
| **Lo que está dentro de `main.exe`** | — | **no** (empaquetado) |

### 12.4 Problemas típicos del cliente

| Síntoma | Solución |
|---|---|
| `file corrupted` al entrar a un mapa | faltan o están mal los `.att` de ese mapa → `docs/14` |
| Pantalla negra / no abre | ejecutá `JUGAR.cmd` (regenera `local.bmd`) |
| Crashea al abrir el inventario | un `.bmd` quedó con tamaño distinto → restaurá el `.bak` |
| FPS bajos (~21) | es el tope del motor; ver `docs/15` |
| No veo los textos nuevos | cerrá y abrí el juego |

---

## 13. Archivos del servidor que importan

| Archivo | Para qué |
|---|---|
| `GameServer\DATA\GameServerInfo - Common.dat` | exp, drop, zen, nivel, usuarios, PK |
| `GameServer\DATA\GameServerInfo - Command.dat` | comandos, costos, límites |
| `GameServer\DATA\GameServerInfo - Event.dat` | qué eventos están prendidos |
| `GameServer\DATA\GameServerInfo - Custom.dat` | customs (`/pick`, `/offattack`, `/store`) |
| `GameServer\DATA\GameServerInfo - Character.dat` / `Skill.dat` / `ChaosMix.dat` | clases, skills, Chaos Machine |
| `Data\Message.txt` | mensajes del servidor (bienvenida, errores) |
| `Data\Command.txt` | **nombres** de los comandos |
| `Data\Util\Notice.txt` | avisos rotativos en pantalla |
| `Data\Util\GameMaster.txt` | quién es GM |
| `Data\MapManager.txt` | mapas habilitados + rates por mapa |
| `Data\MapServerInfo.dat` | qué mapa atiende cada GameServer |
| `Data\Item\*.txt` | ítems, precios, drops |
| `Data\Monster\*.txt` | monstruos (vida, daño, zen) y apariciones |
| `Data\Event\*.dat` | horarios de eventos |
| `Data\EventItemBag\*.txt` | contenido de las cajas |
| `Data\EventItemBagManager.txt` | qué ítem abre qué bolsa |
| `Data\ShopManager.txt` | tiendas de los NPC |
| `Data\Script\ScriptMain.lua` | saludos de NPC y aviso de entrada |
| `GameServer\LOG\AAAA-MM-DD.txt` | registro diario (errores, logins, chat) |
| `_logs\*.err.txt` | salida de error de cada programa al arrancar |

**Reglas para editar sin romper nada**

1. Backup primero (`.bak`).
2. Texto en **ANSI/CP1252** (no UTF-8) — se usan los scripts del proyecto.
3. En `.bmd` el tamaño del archivo **no cambia**.
4. Cerrá el cliente antes de tocar archivos del cliente.

---

## 14. Recetas paso a paso

### 14.1 Cambiar la experiencia

1. Abrí `MuServer\GameServer\DATA\GameServerInfo - Common.dat`.
2. Buscá `AddExperienceRate_AL0`. **100 = 1x**, así que x100 = `10000`.
3. Guardá y corré `RECARGAR-GAMESERVER.cmd`.
4. Si querés el mismo rate para VIP, cambiá también `AL1`, `AL2`, `AL3`.

### 14.2 Cambiar el costo del reset

`GameServerInfo - Command.dat` → `CommandResetMoney_AL0` (y AL1/2/3), en zen.

### 14.3 Cambiar el costo de `/pk`

`GameServerInfo - Command.dat` → `CommandPKClearMoney_AL0`.

### 14.4 Agregar un aviso en pantalla

1. Editá `scripts\textos-cliente\notice.txt` (una línea por aviso, campos con `|`).
2. Corré:
   `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\aplicar-textos-cliente.ps1`
3. `RECARGAR-GAMESERVER.cmd`.

### 14.5 Cambiar un texto o descripción del cliente

1. Editá `scripts\textos-cliente\item-descripciones.txt` (índice|texto) o `slide-tips.txt`.
2. Corré el mismo script de arriba (hace backup y verifica tamaños).
3. Cerrá y abrí el juego.

### 14.6 Agregar mensajes del servidor (`Message.txt`)

1. Editá `scripts\textos-cliente\mensajes-servidor.txt` (`indice|texto`).
2. Corré:
   `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\aplicar-mensajes-servidor.ps1`
3. `RECARGAR-GAMESERVER.cmd`.

### 14.7 Crear cuenta / dar GM

- Cuenta: MuMaker (§6.1).
- GM: `Data\Util\GameMaster.txt` + reiniciar GameServer (§6.4).

### 14.8 Backup y restauración

- **Archivos**: los scripts ya guardan `.bak` con fecha.
- **Base de datos**: backup desde SQL Server Management Studio o
  `scripts\restaurar-bases.ps1` para volver al `.bak` original.
- **Cliente original**: `C:\Users\leand\Downloads\Client-1.02.44.zip` (pristino).

### 14.9 Publicar el servidor en internet

Resumen: abrir en el router los puertos **44405** y **55901** (y 55920 si usás
mapas de asedio) hacia la IP local `192.168.0.85`, abrir el Firewall de Windows
(`scripts\abrir-puertos-firewall.ps1`) y pasarle a tus amigos tu **IP pública**
(o un DNS dinámico). Paso a paso: `docs/09-exponer-a-internet.md`.

### 14.10 Ver qué pasó (logs)

| Querés saber | Mirá |
|---|---|
| Quién entró / chat / comandos | `MuServer\GameServer\LOG\AAAA-MM-DD.txt` |
| Si un programa falló al arrancar | `MuServer\_logs\<Programa>.err.txt` |
| Logins rechazados | `MuServer\JoinServer\LOG\AAAA-MM-DD.txt` |

---

## 15. Problemas conocidos y solución

| Problema | Causa / solución |
|---|---|
| `Could not find message 338!` al entrar | el `Message.txt` no tenía ese índice. **Ya agregado** (338 + 800-804). Si aparece otro número, se agrega con `scripts\aplicar-mensajes-servidor.ps1` |
| `file corrupted` en un mapa | faltan los `.att`/`EncTerrain` de ese mapa → `docs/14` |
| No puedo loguear y el personaje figura online | quedó un cliente colgado (o un cartel de error): cerrá el juego o reiniciá el GameServer |
| El servidor no arranca un componente | mirá `_logs\<Programa>.err.txt` y el puerto ocupado |
| Castle Siege crasheaba | fechas viejas en `MuCastle_DATA` → `scripts\arreglar-castle-siege.ps1` (el evento está apagado igual) |
| Cae poco zen | config actual + `MoneyRate` de los monstruos (§8.1) |
| Joya del Alma falla mucho | está en 50% a propósito |
| Los tips/descripciones no cambian | no cerraste el cliente, o el `.bmd` se guardó en UTF-8 |
| Los acentos salen `?` | se guardó en ASCII, no en CP1252 |

---

## 16. Qué falta / próximos pasos

| Tema | Estado |
|---|---|
| **Economía de zen** | diagnosticada (fin del juego paga menos); falta aplicar la config nueva y medir en juego |
| **Sistema de Frutas** | diseñado (costo en zen + joyas); sin implementar |
| **Exponer a internet** | pendiente: puertos + firewall + IP pública |
| **Web de registro + launcher propio** | pendiente |
| **60 FPS** | el motor topa ~21 FPS; no se pudo destrabar (`docs/15`) |
| **Tiendas de NPC** | hay 15 tiendas vacías (012-026) para armar |
| **Tests pendientes** | `/evo`, `/re`, `/war`, `/soccer`, `/f`, `/v`, `/e`; mapas Crywolf/Aida/Kanturu; `CustomTooltip` |
| **`CustomTooltip.txt`** | aplicado; falta ver si el cliente lo muestra |
| **Master level** | activado en el server, sin UI clara en 1.02 |
| **Anti-hack (MHP)** | sin configurar |
| **Auditoría de backdoors** | pendiente antes de publicar (`docs/06`) |

---

## 17. Bitácora de descubrimientos

> **Lo último va arriba.** Cada línea: qué aprendimos y dónde quedó guardado.

| Fecha | Qué aprendimos | Dónde |
|---|---|---|
| 2026-11-14 | Las cajas son un solo ítem (`14,11`) con distinto nivel; el contenido y los % salen de `EventItemBag\`; descripción nativa en `Text.bmd` 571 y detalle por nivel en `CustomTooltip.txt` | `docs/17` §2.1, §3 |
| 2026-11-14 | `Could not find message N!` = el `GameServer.exe` pide índices que el `Message.txt` del repack no tenía (338, 800-804) | `docs/16`, §15 |
| 2026-11-14 | El `%` en `Text.bmd` se escribe una sola vez (estaba `30%%`) | `docs/17` |
| 2026-11-14 | Textos del cliente: avisos rotativos, tips de carga (32), descripciones y bienvenida | `docs/16`, `docs/17` |
| 2026-11-13 | Qué causa `file corrupted` (header del `EncTerrain` y `.att` de 65.540 bytes) | `docs/14` |
| 2026-11-13 | Cómo funciona el menú de `/move` (`MoveReq.bmd` → índice → `Move.txt` → `Gate.txt`) | `docs/14` |
| 2026-11-13 | El zen por bicho depende de `MoneyRate`, `MoneyValue` y el nivel del monstruo | `docs/11` |
| 2026-11-12 | Los 6 componentes, sus puertos y el orden de arranque | este manual §4, `docs/10` |
| 2026-11-12 | Castle Siege crasheaba por fechas viejas en la base | `docs/08`, §15 |
| 2026-11-12 | El cliente 1.02 no carga plugins (adiós al unlock de FPS por plugin) | `docs/15` |

---

## 18. Índice de la documentación detallada

| Documento | Tema |
|---|---|
| `docs/01-obtener-archivos.md` | de dónde salió el repack |
| `docs/02-sql-server.md` | instalar y configurar SQL Server |
| `docs/03-configurar-muserver.md` | configurar los componentes |
| `docs/04-cliente.md` | preparar el cliente |
| `docs/05-deploy-vps.md` | pasarlo a un VPS (a futuro) |
| `docs/06-seguridad.md` | backdoors y seguridad |
| `docs/07-puertos.md` | puertos y firewall |
| `docs/08-muemu-season2.md` | guía del repack MuEmu |
| `docs/09-exponer-a-internet.md` | abrir el server a internet |
| `docs/10-como-jugar.md` | arrancar, apagar y jugar |
| `docs/11-servidor-en-detalle.md` | rates, eventos y customs en detalle |
| `docs/12-comandos-admin.md` | todos los comandos (jugador y GM) |
| `docs/13-herramientas.md` | MuMaker y editores |
| `docs/14-mapas-file-corrupted.md` | mapas y el error `file corrupted` |
| `docs/15-fps-y-rendimiento.md` | FPS y rendimiento |
| `docs/16-anuncios-y-npc.md` | avisos, bienvenida, mensajes y NPC |
| `docs/17-textos-y-descripciones.md` | nombres, descripciones y textos |
| `docs/diseno-servidor.md` | decisiones de diseño (rates, resets, frutas) |

---

## 19. Guía rápida para amigos (para pegar en Discord)

```
🎮 Mu Nega — MU Online Season 2 (1.02.44)

Cómo entrar:
1) Bajá la carpeta del cliente que te paso.
2) Descomprimila donde quieras (no hace falta instalar).
3) Abrí JUGAR.cmd y esperá la pantalla de login.
4) Creá tu cuenta desde el launcher/web (o pedímela).

El servidor:
• Exp x3000 y monstruos con 5x vida.
• Nivel máximo 400. Reset a los 400 con 35M de zen: +1000 puntos y NO perdés stats.
• Comandos útiles:
   /reset   → resetear
   /pick zen → junta el zen del suelo
   /store   → tu tienda personal
   /bau 1   → cambiá de baúl
   /pk      → te saca el estado asesino
• Eventos: Blood Castle, Devil Square y Chaos Castle cada 3 horas.
  Invasiones doradas cada hora (a los :05, :15, :25 y :50).
• Zen máximo: 2.000.000.000.
• Cualquier duda, preguntá en el Discord.
```

---

## 20. Cómo mantener este manual

1. Cada vez que descubrimos algo, se agrega:
   - una fila en la **bitácora** (§17, arriba de todo), y
   - el detalle en la sección que corresponda (o en el `docs/` del tema).
2. Si algo pasa de ⚠️/❓ a ✅, se cambia la marca.
3. Si un dato cambia (rate, costo, horario), se actualiza **acá y** en el doc
   específico, para que no queden dos versiones distintas.
