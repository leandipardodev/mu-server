# MuEmu Season 2 (1.02r) — Guía específica

Repack elegido: **MuEmu Season 2 (1.02r) + Unstable Moon**, de *Reject*.

- Hilo: https://tuservermu.eu/index.php?topic=386.0
- Para descargar: registrate en TuServerMu, entrá al hilo y tocá el botón
  **"Unlock Content"** (esquina inferior derecha). Los enlaces están ocultos
  hasta que agradecés/desbloqueás.

---

## Qué es MuEmu

**MuEmu** es un **emulador** (no son los binarios originales de Webzen). Este
release es el emulador de **Season 6 downgradeado a Season 2 (1.02r)**. Ventajas:

- Corre en **Windows moderno (10/11/Server)** y **SQL Server nuevo**.
- **Sin los backdoors clásicos** de los repacks de 2007 (igual auditar).
- Configuración más ordenada (archivos `.ini` con comentarios).

Cosas que el propio autor aclara:
- El **script Lua** que trae "está completamente inestable".
- Algunas cosas no funcionan (ej. `Data/Custom/CustomRankUser`) simplemente
  porque no existen.
- El cliente trae customs: ítem custom, tecla F5 (status extra), HPBar, barra
  de título con información.

---

## Requisitos

| Componente | Versión |
|---|---|
| SO | Windows x64 (10/11/Server) |
| Base de datos | SQL Server 2012 R2 o superior → usá **2019/2022 Express** |
| VC++ servidor | **Visual C++ 2015 Redistributable (x64)** |
| VC++ cliente | **Visual C++ 2010 SP1 Redistributable (x86)** |
| .NET | .NET Framework (el que pida el repack) |
| Editor | **Notepad++** (los .ini están pensados para él) |

> Los `.ini` deben guardarse como **UTF-8 sin BOM**.

---

## Estructura típica de MuEmu

Verificá los nombres exactos en tu repack. Lo habitual:

```
MuServer/
├── Server/
│   └── Files/
│       ├── DataServer/       -> IGCDS.ini  (config de base de datos)
│       ├── ChatServer/       -> config.ini
│       ├── ConnectServer/    -> config (lista de servidores)
│       ├── GameServer/       -> config + Data/ (mapas, ítems, drops)
│       └── GameServerCS/     -> config (Castle Siege)
└── Tools/                    -> editores, utilidades
```

---

## Bases de datos (MuEmu)

MuEmu usa **scripts `.sql`** (no `.bak` de SQL 2000), así que **no hay problema
de compatibilidad** con SQL moderno. Las bases por defecto:

| Base | Contenido |
|---|---|
| `MuOnline` | Cuentas, personajes, ítems, guilds |
| `Ranking` | Rankings |
| `Events` | Datos de eventos |
| `Me_MuOnline` | (opcional, config avanzada) |
| `BattleCore` | (solo si usás Battle Core; nombre **no** se puede cambiar) |

### Cómo crearlas
1. Abrí SSMS.
2. Ejecutá los scripts en orden: `MuOnline.sql`, `Ranking.sql`, `Events.sql`
   (y `Me_MuOnline.sql` si lo usás).
3. Colación por defecto de los scripts: `SQL_Latin1_General_CP1_CI_AS`.

---

## Configuración de base de datos (`IGCDS.ini`)

En `Server/Files/DataServer/IGCDS.ini`:

```ini
; IP pública (WAN) del servidor
WanIP = TU_IP_PUBLICA

; Nombres de las bases
MuOnlineDB   = MuOnline
MeMuOnlineDB = MuOnline
EventDB      = Events
RankingDB    = Ranking

; Usuario de SQL (NO usar 'sa' en producción)
User = muuser
Pass = <clave-unica-configurada-localmente>

; Dirección/instancia del SQL Server
Address = 127.0.0.1
```

> El valor de `Pass` es solo un marcador: reemplazalo localmente y no guardes
> la contraseña real en el repositorio. El DSN `MuOnline` de este proyecto usa
> autenticación integrada de Windows.
>
> Si el DataServer se "congela" al iniciar, casi siempre es que no conecta a SQL:
> revisá TCP/IP (puerto 1433), autenticación mixta y que el usuario tenga acceso.

`ChatServer/config.ini` es similar (IP del DataServer, nombre de base, user/pass).

---

## ⚠️ Licencia

El MuEmu **oficial** (muemu.tech) pide **activación de licencia**. Verificá si el
release de Reject viene **license-free** o si pide activación. Si pide licencia y
no la tenés, no sirve para producción.

---

## Orden de arranque

1. SQL Server (servicio)
2. **DataServer** (IGCDS)
3. **ChatServer**
4. **ConnectServer**
5. **GameServer**
6. **GameServerCS**

> Ajustá `scripts/iniciar-servidor.ps1` con los nombres reales de los `.exe`
> de tu repack.

---

## ODBC

MuEmu normalmente conecta **directo** (por `Address` + `User` + `Pass` en el
`.ini`), sin depender de DSN ODBC. Si algún componente igual pide un DSN,
creá uno de **32 bits** con `C:\Windows\SysWOW64\odbcad32.exe` (el MuServer es
32 bits).

---

## Notas

- Instalá fuera de `C:\Program Files\` (ej. `C:\MuServer`) para evitar UAC.
- Guardá los `.ini` en UTF-8 sin BOM.
- El Lua es inestable: no te apoyes en él al principio.
