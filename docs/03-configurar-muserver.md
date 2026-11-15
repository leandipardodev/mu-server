# Fase 3 — Configurar los componentes del MuServer

Cada componente es un `.exe` con uno o más archivos de configuración (`.ini`,
`.txt`, `.dat`). Los nombres exactos cambian entre repacks; acá va la lógica.

---

## 3.1 Orden de arranque (importante)

Se inician **en este orden**, esperando unos segundos entre cada uno:

1. **SQL Server** (servicio de Windows)
2. **ExDB**
3. **RankingServer**
4. **DataServer 1** y **DataServer 2**
5. **JoinServer**
6. **ConnectServer**
7. **EventServer**
8. **GameServer**
9. **GameServerCS**

El script `scripts/iniciar-servidor.ps1` hace esto automáticamente.

---

## 3.2 Las 3 direcciones IP que hay que alinear

Casi todos los errores de conexión vienen de acá. Hay que dejar coherentes:

| Dónde | Qué IP poner |
|-------|--------------|
| **ConnectServer** (`ServerList.dat`) | IP del GameServer (la que verá el cliente) |
| **GameServer** (config) | IP del JoinServer y del DataServer |
| **JoinServer** (config) | IP del DataServer |
| **Cliente** (`Cliente\MainInfo.ini` → `local.bmd`) | IP del ConnectServer |

### Local (prueba en tu PC)
Si el cliente corre en la misma PC que el servidor, usá `127.0.0.1`. Si corre
en otra PC de la LAN, usá la IP LAN del equipo servidor.

### Público (VPS)
Usá la **IP pública** del VPS en todos lados (o un dominio).

---

## 3.3 Configuración por componente

### ConnectServer
- Archivo típico: `ConnectServer/Data/ServerList.dat` (o `ServerInfo.dat`).
- Define los servidores que ve el cliente y a qué **IP:puerto** conectan.
- Ejemplo de línea: `0 "MiMu" "IP_PUBLICA" 55901`

### JoinServer
- Archivo típico: `JoinServer/JoinServer.ini` o `Data/JoinServer.ini`.
- Cadena de conexión a la base `MuOnline`.
- IP del DataServer.
- A veces requiere un **"serial"** y una **versión** que deben coincidir con el cliente.

### DataServer (1 y 2)
- Archivos típicos: `DataServer1/DataServer.ini`, `DataServer2/...`.
- Cadena de conexión a `MuOnline` / `Me_MuOnline`.
- Puerto (55960 / 55962).

### GameServer
- Carpeta `GameServer/Data/` con los `.dat` de mapas, ítems, monstruos, drops.
- Config general (`GameServerInfo.dat`, `CommonServer.cfg` o similar):
  - IP/puerto del JoinServer y DataServer
  - **Rate de experiencia**, drop, etc.
  - Puertos del GameServer (55901) y del GameServerCS (55919)
- Acá se ajustan las reglas de juego (rates, PvP, eventos).

### EventServer / RankingServer / ExDB
- Cadenas de conexión a `Me_MuOnline` / `Ranking`.
- Intervalos de eventos.

---

## 3.4 Cadenas de conexión

Formato típico (varía):

```
MuOnline = "Provider=SQLOLEDB;Data Source=.\SQLEXPRESS;Initial Catalog=MuOnline;User Id=muuser;Password=TU_PASS;"
```

O a veces en formato separado:

```
DBIP   = 127.0.0.1
DBUser = muuser
DBPass = TU_PASS
DBName = MuOnline
```

Buscá en los `.ini` palabras como `Provider`, `Data Source`, `ODBC`, `DBIP`,
`ConnectionString`.

---

## 3.5 Primer arranque en local

1. Iniciá SQL Server.
2. Corré `scripts/iniciar-servidor.ps1`.
3. Mirá los **logs** de cada componente: casi todos escriben un `.log` o muestran
   una consola. Buscá `error`, `fail`, `connect`, `DB`.
4. Cuando todo diga OK, conectá con el cliente (Fase 4).

### Errores típicos
| Síntoma | Causa probable |
|---------|----------------|
| JoinServer no conecta a DB | TCP/IP deshabilitado, puerto 1433, o credenciales |
| Cliente se queda en "connecting" | IP/puerto en `ServerList.dat` mal |
| "Disconnected" al elegir servidor | IP del GameServer no es alcanzable |
| Versión incorrecta | `MainInfo.ini` no coincide con GameServer/MHPServer |

---

## 3.6 Verificar puertos

```powershell
.\scripts\verificar-puertos.ps1
```

Siguiente: **`docs/04-cliente.md`**
