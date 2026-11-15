# Herramientas del servidor (qué son y cómo se usan)

> Todo está en `MuServer\Tools\`. Esta es la lista completa de lo que vino en el repack,
> con el estado de cada herramienta en **tu** servidor.

---

## Resumen

| Herramienta | Para qué sirve | Estado |
|---|---|---|
| **MuMaker 1.12** | Editor de la base de datos (personajes, ítems, cuentas) | ✅ Credenciales configuradas |
| **AIO Mu Editor** | Editor moderno "todo en uno" | ⚪ Sin configurar (se configura solo en su pantalla) |
| **EventItemBag-Editor** | Editar las cajas/bags de eventos (qué ítems sueltan) | ✅ Listo |
| **MonsterSpawnEditor V1.01** | Editar dónde y cuántos monstruos aparecen | ✅ Listo |
| **GetMainInfo** | Generar `local.bmd` del cliente (IP del servidor) | ✅ Usado |
| **GetHardwareId** | Generar el `HardwareId` que usan los `.ini`/`.dat` | ✅ Ya aplicado |
| **AH_INFO** | Datos del anti-hack del cliente (MHPServer, puerto 55999) | ⚪ Sin configurar (no hace falta ahora) |
| **CzFMuEditor** (del paquete 1.02N, en `mu lean\`) | Editor clásico de la DB | ❌ No recomendado |

---

## 1. MuMaker 1.12 — editor de la base de datos

Carpeta: `MuServer\Tools\MuMaker 1.12\`

```
MuMaker.exe
Config.ini          <- conexión a SQL Server
MuMaker.mdb         <- listas de ítems/monstruos
Interop.JRO.dll
```

### Credenciales (ya configuradas)

| Dato | Valor |
|---|---|
| Usuario SQL | `mumaker` |
| Contraseña | `MuMaker#2026!` |
| Servidor | `192.168.0.85` (o `localhost`), puerto `1433` |
| Base de datos | `MuOnline` |

`Config.ini` guarda la contraseña **cifrada**. El valor que hay ahora:

```ini
PassWord=0C516E2144438E06731411760E
```

> Ese valor cifrado corresponde a `MuMaker#2026!`. **No lo escribas en texto plano**:
> MuMaker no lo va a entender y va a fallar el login.

### Cómo se genera el valor cifrado (si algún día cambiás la contraseña)

MuMaker usa una función interna (clase `ab`, método `c`) que convierte el texto a ese
hexadecimal. Ejemplo real comprobado:

| Texto | Valor cifrado |
|---|---|
| `123456` | `701610741A10` |
| `admin123` | `20404E294117CE16` |
| `MuServer#2026!` | `0C5170255D509957621613721907` |
| `MuMaker#2026!` | `0C516E2144438E06731411760E` |

Podés generar el tuyo con `scripts\mumaker-password.ps1 -Password "TuClave"`.

### Notas importantes

- **Verificado funcionando**: abre y queda en la ventana `MuMaker - lean`.
- ⚠️ `Config.ini` tiene **dos** claves `Reset` distintas y **no** son lo mismo:
  - `[SQL] Reset=Resets` → nombre de base/tabla de resets (dejar como está).
  - `[Config] Reset=0` → **bandera numérica**. Si le ponés texto (por ejemplo
    `Reset=MuOnline`), MuMaker abre y **se cierra solo**. Tiene que ser `0` o `1`.
- MuMaker 1.12 es de la época de la **1.02N**. Si algún día da error al cargar
  personajes, es porque la base `MuOnline` es de **MuEmu Season 2** y tiene columnas
  distintas. En ese caso usá **AIO Mu Editor**.
- La cuenta SQL `mumaker` tiene permiso `db_owner` sobre `MuOnline`.

---

## 2. AIO Mu Editor (alternativa moderna)

Carpeta: `MuServer\Tools\AIO Mu Editor-release\`

- Se abre con `AIO Mu Editor-win_x64.exe`.
- Al abrirlo pide los datos de conexión (servidor, usuario, contraseña, base).
  Usá los mismos datos de la tabla de arriba.
- Es la opción más nueva y la que mejor soporta servidores tipo MuEmu.

---

## 3. EventItemBag-Editor — cajas de eventos

Carpeta: `MuServer\Tools\EventItemBag-Editor\`

- Sirve para editar qué ítems caen en cada caja/bag de evento.
- La carpeta **`Event Item Bags Corregidos\`** trae bags ya corregidos para esta versión.
- `Data\Config.ini` → `isEx700ItemList=0` (correcto para Season 2; no lo cambies).
- Los bags se guardan en `MuServer\Data\EventItemBag\`.

## 4. MonsterSpawnEditor V1.01 — monstruos por mapa

Carpeta: `MuServer\Tools\MonsterSpawnEditorV1.01\MonsterSpawnEditor\`

- Edita la aparición de monstruos mapa por mapa (incluye `006 - Stadium.txt` = Arena).
- Trabaja sobre `Monster\Monster.txt` y `MonsterSetBase\*.txt`.
- Al guardar, copiá los `.txt` resultantes a `MuServer\Data\Monster\` y reiniciá el
  GameServer para que se apliquen.

## 5. GetMainInfo — genera `local.bmd`

Carpeta: `MuServer\Tools\GetMainInfo\`

- Lee `MainInfo.ini` y genera `local.bmd`, que es lo que le dice al cliente
  **a qué IP conectarse** (`IpAddress` / `IpAddressPort`).
- **El `IpAddress` tiene que ser la IP de LAN de tu PC** (`192.168.0.85`), no `127.0.0.1`.
- ⚠️ `GetMainInfo.exe` falla si se ejecuta dentro de `Cliente\`. Por eso se corre en una
  carpeta temporal y después se copia el `local.bmd` a `Cliente\Data\Local\`.
- Después de regenerarlo, **cerrá y abrí el cliente**.

## 6. GetHardwareId — identificación de la máquina

Carpeta: `MuServer\Tools\GetHardwareId\`

- Genera `HardwareId.txt` (el identificador de tu PC).
- Ese valor ya está puesto en todos los `.ini` / `.dat` / `.txt` del servidor.
- Solo hay que volver a usarlo si **movés el servidor a otra PC**.

## 7. AH_INFO — anti-hack del cliente

Carpeta: `MuServer\Tools\AH_INFO\`

- `ClientInfo.ini` apunta al **MHPServer** (`ServerPort = 55999`).
- Todavía tiene los valores de fábrica (`CustomerName = XXX`, `IpAddress = 127.0.0.1`).
- **No es necesario** para jugar. Se configura más adelante si querés activar el
  anti-hack completo.

## 8. CzFMuEditor (paquete 1.02N) — no recomendado

Ubicación: `mu lean\...\MuServer 1.02N\Editor\`

- Viene con `sa` / `13579` y con DSNs de ODBC que no existen en tu PC.
- Es de la 1.02N y **no** entiende el esquema de MuEmu.
- Se guarda solo como referencia histórica.

---

## Acceso directo a SQL (sin interfaz)

`sqlcmd` ya está instalado y sirve para hacer consultas o arreglos rápidos:

```powershell
# Con autenticación de Windows (tu usuario es sysadmin)
& "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE" `
  -S ".\SQLEXPRESS" -E -d MuOnline -W -s "|" -Q "SELECT TOP 10 Name, cLevel FROM Character;"
```

### Logins de SQL Server

| Login | Contraseña | Permisos |
|---|---|---|
| `sa` | `MuServer#2026!` | sysadmin |
| `muuser` | `MuUser#2026!` | el que usan los `.exe` del servidor |
| `mumaker` | `MuMaker#2026!` | `db_owner` en `MuOnline` |

> Para verificar una contraseña de un login sin conectarte:
> `SELECT pwdcompare('laClave', password_hash) FROM sys.sql_logins WHERE name='mumaker';`
> (devuelve `1` si coincide).

---

## Utilidades propias del proyecto (`scripts\`)

| Script | Para qué |
|---|---|
| `scripts\arreglar-world7.ps1` | Arregla el `.att` de la Arena (`-World N` para otros mapas) |
| `scripts\terrain-scan.ps1` | Revisa todos los `EncTerrain*.att` del cliente |
| `scripts\terrain-scan-all.ps1` | Revisa `.att`, `.map` y `.obj` de todos los mundos |
| `scripts\terrain-att-tool.ps1` | Comprueba/repara un `.att` concreto |
| `scripts\convertir-att-128kb.ps1` | Pasa los `.att` de 128 KB (2 bytes/tile) al formato de 64 KB |
| `scripts\crear-variante-terreno.ps1` | Crea la variante de terreno que falta (`EncTerrain<world><n>.att/.map/.obj`) |
| `scripts\comparar-cliente-original.ps1` | Compara el cliente contra el ZIP original del repack |
| `scripts\restaurar-world1-original.ps1` | Restaura `World1` (Lorencia) desde el ZIP original |
| `scripts\dumpear-moverequest.ps1` | Lista el menú de transporte (`MoveReq.bmd`) |
| `scripts\moverequest-agregar.ps1` | Agrega/reemplaza una entrada del menú de transporte |
| `scripts\aplicar-config-servidor.ps1` | Aplica la configuración del diseño (exp x3000, reset, etc.) |
| `scripts\arreglar-castle-siege.ps1` | Arregla las fechas del Castle Siege |
| `scripts\iniciar-servidor.ps1` / `detener-servidor.ps1` | Arranca / para los 6 componentes |
| `scripts\recargar-gameserver.ps1` | Reinicia solo el GameServer (recarga GMs, `Move.txt`, terreno) |

> Los `.ps1` no se pueden ejecutar con doble clic por la política de PowerShell.
> Usá los `.cmd` de la raíz (`INICIAR-SERVIDOR.cmd`, `DETENER-SERVIDOR.cmd`,
> `RECARGAR-GAMESERVER.cmd`, `JUGAR.cmd`) **como administrador**.
