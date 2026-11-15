# Fase 2 — Instalar SQL Server y restaurar las bases

El 1.02N usa **Microsoft SQL Server**. En local alcanza con **SQL Server Express**
(gratis). Para producción conviene una instancia propia en el VPS.

---

## 2.1 Instalar SQL Server Express

### Opción automática (recomendada)

Doble clic en **`scripts\instalar-sql-express.cmd`**. El script:

- Descarga el instalador **Core** oficial (`SQLEXPR_x64_ENU.exe`, ~250 MB) de
  SQL Server **2019 Express** y lo instala en modo silencioso.
- Habilita **TCP/IP en el puerto 1433**.
- Activa **autenticación mixta** y pide una clave inicial para `sa` durante la
  instalación. No la guarda en el proyecto ni en el log.
- Instala los **Visual C++ Redistributable** (x64 servidor / x86 cliente) y **SSMS**.
- Verifica la conexión al final.

Se pide permiso de Administrador (UAC) automáticamente. Al terminar:

| Dato        | Valor |
|-------------|-------|
| Instancia   | `.\SQLEXPRESS` |
| Administración | Autenticación de Windows |
| Puerto TCP  | `1433` |

No habilites el acceso entrante de SQL Server desde Internet. El puerto 1433 se
usa localmente; si necesitás acceso remoto, limitá el firewall a IPs privadas
concretas.

Si SQL Server ya estaba instalado con una clave anterior de este proyecto,
cambiala en SSMS antes de exponer la máquina. El DSN `MuOnline` usa
autenticación integrada de Windows, así que el servidor de juego no depende de
la clave de `sa`. Actualizá también cualquier herramienta administrativa que
se conecte como `sa`.

> Para usar SQL Server **2022** en vez de 2019:
> `.\scripts\instalar-sql-express.ps1 -SqlVersion 2022`
> (o editar el `.cmd` para agregar ese parámetro).

### Opción manual

1. Descargar **SQL Server Express** (Core/Basic):
   https://www.microsoft.com/en-us/sql-server/sql-server-downloads
   → elegir *Express* → *Download now* → instalación **Básica**.

2. Instalar **SQL Server Management Studio (SSMS)**:
   https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms

3. **Configurar para que acepte conexiones de red** (crítico, el MuServer se
   conecta por TCP, no por instancia local):
   - Abrir **SQL Server Configuration Manager**.
   - *SQL Server Network Configuration* → *Protocols for SQLEXPRESS*:
     - **TCP/IP** → Enable = `Yes`
     - TCP/IP → pestaña *IP Addresses* → **IPAll** → *TCP Port* = `1433`
   - *SQL Server Services* → reiniciar **SQL Server (SQLEXPRESS)**.

4. **Habilitar autenticación mixta** (SQL + Windows):
   - En SSMS: click derecho en el servidor → *Properties* → *Security*
     → **SQL Server and Windows Authentication mode**.
   - Reiniciar el servicio otra vez.

5. Si necesitás usar autenticación SQL, configurá una contraseña única para el
   login que corresponda y verificá que esté habilitado:
   - *Security* → *Logins* → `sa` → click derecho → *Properties*
     → establecer una contraseña fuerte y mantener la política de contraseña.
   - En *Status* → *Login* = **Enabled**.

---

## 2.2 Restaurar las bases de datos

El repack trae las bases como **`.bak`** (backup) o como **`.sql`** (scripts).

> **Con MuEmu**: son **scripts `.sql`** (`MuOnline.sql`, `Ranking.sql`,
> `Events.sql`). Ver `docs/08-muemu-season2.md`. Se ejecutan directo en SQL
> 2019/2022, sin problema de compatibilidad.

### Opción A — Restaurar `.bak` (lo habitual)

1. Copiá los `.bak` a `sql/bak/`.
2. Creá la carpeta de datos, por ejemplo `C:\MuServerDB\`.
3. Ejecutá el script incluido:

```powershell
.\scripts\restaurar-bases.ps1 -BakDir ".\sql\bak" -DataDir "C:\MuServerDB"
```

El script detecta los archivos lógicos dentro de cada `.bak` y restaura
`MuOnline`, `Me_MuOnline` y `Ranking`.

### Opción B — Ejecutar `.sql`

Si el repack trae scripts SQL, abrilo en SSMS y ejecutá cada uno. Suelen crear
la base y las tablas de una.

---

## 2.3 Crear el login que usa el MuServer

El DSN `MuOnline` de este proyecto usa autenticación integrada de Windows; el
GameServer no necesita el login `sa`. Si una herramienta requiere el login
dedicado `muuser`, configurá una clave única localmente en
`sql/crear-login-muserver.sql` antes de ejecutarlo. El script limita sus
permisos a lectura/escritura y ejecución; no usa `db_owner`. Si el login ya
existía, el script cambia su contraseña al ejecutarse.

Ejecutalo después de crear las bases (`MuOnline`, `Ranking`, `Events` y/o
`Me_MuOnline`). No guardes ni compartas la clave que configures.

---

## 2.4 Verificar

- [ ] Servicio SQL Server corriendo.
- [ ] TCP/IP habilitado en puerto 1433.
- [ ] Autenticación mixta activada.
- [ ] Las 3 bases existen (`MuOnline`, `Me_MuOnline`, `Ranking`).
- [ ] El DSN `MuOnline` conecta usando autenticación integrada de Windows.

Probá la instancia usando autenticación de Windows:

```powershell
sqlcmd -S ".\SQLEXPRESS" -E -Q "SELECT name FROM sys.databases"
```

---

## Alternativa: SQL Server en Docker (para pruebas)

Ya tenés Docker. Podés levantar SQL Server sin instalarlo:

```powershell
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=TuPassw0rd!" `
  -p 1433:1433 --name mssql-mu -d mcr.microsoft.com/mssql/server:2022-latest
```

Útil para probar. Para producción, igual conviene SQL nativo en el VPS.

---

## Notas sobre versiones

- Algunos repacks muy viejos piden **SQL Server 2000/2008**. En general
  funcionan igual en 2019/2022 con TCP/IP + autenticación SQL.
- Si un `.exe` se niega a conectar, revisá el **driver ODBC** que espera
  (algunos usan `SQLOLEDB`, otros `MSDASQL`). Se ve en los `.ini` o en el log.

---

## ⚠️ Repacks de la era 2007 (como el MuServer 1.02N original)

Los repacks originales de 1.02N/0.99/1.01 se hicieron para **SQL Server 2000**.
Eso trae dos problemas en un Windows/SQL moderno:

### 1. Restaurar un `.bak` de SQL 2000 en SQL 2019/2022
**No se puede directo.** SQL Server 2012+ ya no acepta backups generados por
SQL Server 2000. El camino es:

```
SQL Server 2000 (.bak)  →  SQL Server 2008 R2  →  SQL Server 2019/2022
```

- **Opción simple:** instalar **SQL Server 2008 R2 Express**, restaurar ahí, y
  dejarlo en 2008 R2 (sirve perfecto para 1.02N).
- **Opción purista:** una **VM** con Windows XP/2003 + SQL 2000 SP4, y reenviar
  los puertos 44405/55901 desde el host a la VM.

> Si el repack trae **scripts `.sql`** en vez de `.bak`, es mucho más fácil:
> se ejecutan directo en SQL 2019/2022 y listo.

### 2. Nivel de compatibilidad de la base
Las bases de esa época usan sintaxis vieja (`*=`, vistas `sysobjects`, etc.).
Al restaurar/crear la base, dejá el nivel de compatibilidad bajo:

```sql
ALTER DATABASE MuOnline    SET COMPATIBILITY_LEVEL = 80;  -- SQL 2000
ALTER DATABASE Me_MuOnline SET COMPATIBILITY_LEVEL = 80;
ALTER DATABASE Ranking     SET COMPATIBILITY_LEVEL = 80;
```

### 3. Driver ODBC
Los `.exe` viejos suelen esperar el driver **`SQL Server`** (legacy), no
`ODBC Driver 17/18`. En Windows de 64 bits, los DSN de 32 bits se configuran en:

```
C:\Windows\SysWOW64\odbcad32.exe
```

(el MuServer es 32 bits, así que usa los DSN de 32 bits).

### 4. Otros detalles de archivos viejos
- Instalá el MuServer **fuera de `C:\Program Files\`** (ej. `C:\MuServer`) para
  evitar problemas de permisos/UAC.
- Algunos GameServer viejos fallan en CPUs con muchos hilos. Con 8 hilos
  (tu i5) no debería ser problema, pero tenelo presente.
- Probá en **modo compatibilidad** (Windows XP SP3) si un `.exe` no arranca.

---

Siguiente: **`docs/03-configurar-muserver.md`**
