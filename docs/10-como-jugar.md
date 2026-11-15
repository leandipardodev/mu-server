# Cómo jugar y administrar el servidor

> Última actualización: 2026-11-11
> Estado: **componentes del servidor inician y escuchan**; el acceso del cliente
> y el login todavía no están verificados.

---

## 1. Resumen del estado

| Componente | Estado |
|---|---|
| SQL Server 2019 Express (`.\SQLEXPRESS`) | ✅ Instalado y corriendo |
| Base `MuOnline` (restaurada desde `DB/MuOnline.bak`) | ✅ Lista |
| Cuenta de prueba `admin` / `admin123` (VIP3) | ✅ Creada |
| Los 6 componentes del MuServer | ✅ Arrancan y escuchan |
| Cliente 1.02.44 (parcheado) | ⚠️ Configurado para `192.168.0.85:44405`; falta verificar la conexión |
| Config de diseño (exp/resets) | ✅ Aplicada |
| Sistema de **Fruits** (custom) | ⚠️ **Pendiente** (ver `docs/diseno-servidor.md`) |

---

## 2. Arrancar el servidor

Doble clic en:

```
INICIAR-SERVIDOR.cmd
```

Arranca en orden: ConnectServer → JoinServer → DataServer → GameServer →
GameServerCS → MHPServer, y al final muestra el estado de cada puerto.

Debe verse así:

```
ConnectServer  44405  LISTEN
JoinServer     55970  LISTEN
DataServer     55960  LISTEN
GameServer     55901  LISTEN
GameServerCS   55920  LISTEN
MHPServer      55999  LISTEN
```

## 3. Detener el servidor

```
DETENER-SERVIDOR.cmd
```

---

## 4. Jugar (en tu propia PC)

Con el servidor arrancado, doble clic en:

```
JUGAR.cmd
```

Esto regenera `Cliente\local.bmd` desde `Cliente\MainInfo.ini` con
`Cliente\GetMainInfo.exe` y luego abre `Cliente\main.exe`. En la pantalla de
login usá:

La configuración local usa la IPv4 LAN activa de la PC (`192.168.0.85` en la
configuración actual) en lugar de `127.0.0.1`. Si esa IP cambia, actualizala
también en `MuServer\ConnectServer\ServerList.dat` y
`MuServer\Data\MapServerInfo.dat`, y reiniciá el servidor.

| Usuario | Contraseña |
|---|---|
| `admin` | `admin123` |

> Si el cliente no arranca, revisá `docs/04-cliente.md`.

### Idioma / resolución
El cliente trae scripts en `Cliente\Scripts\` (`.reg`):
- `LangSpanish.reg` → textos en español.
- Varios `.reg` de resolución y modo ventana/pantalla completa.

Se aplican con doble clic (no requieren admin).

---

## 5. Configuración de diseño aplicada

Se aplica con `scripts\aplicar-config-servidor.ps1` (re-ejecutable):

| Tema | Valor | Dónde |
|---|---|---|
| Exp rate | **x3000** | `AddExperienceRate_AL0..3 = 300000/330000/360000/390000` |
| Nivel máximo | 400 | (por defecto) |
| Reset a nivel | **400** | `CommandResetLevel_AL0..3` + `ResetTable.txt` |
| Reset conserva stats | **Sí** | `CommandResetType = 0` |
| Puntos por reset | **1000** | `CommandResetPoint_AL0..3` + `ResetTable.txt` |
| Límite de resets | 500 | `CommandResetLimit_AL0..3` |
| PK | Abierto | `NonPK = 0` |

> **Ojo con el rate:** en estos archivos **`100` = 1x** (porcentaje).
> Por eso x3000 se escribe `300000`. La exp final = (rate del mapa) ×
> (`ExperienceTable`) × (`AddExperienceRate`). Dejamos `ExperienceTable` en
> `100` (neutral) y todo el rate va en `AddExperienceRate`.
> **Hay que confirmarlo in-game** (ver punto 7).

> ⚠️ **Importante:** el GameServer lee su configuración **al arrancar**.
> Después de cambiar cualquier `.dat`/`.txt` hay que **reiniciar** con
> `DETENER-SERVIDOR.cmd` + `INICIAR-SERVIDOR.cmd`.

---

## 6. Archivos clave

| Archivo | Para qué |
|---|---|
| `MuServer\GameServer\DATA\GameServerInfo - Common.dat` | Rates (exp, drop, zen), PK |
| `MuServer\GameServer\DATA\GameServerInfo - Command.dat` | Comando `/reset` (nivel, puntos, tipo) |
| `MuServer\GameServerCS\DATA\...` | Los mismos, para Castle Siege |
| `MuServer\Data\Util\ExperienceTable.txt` | Rate por rango de resets |
| `MuServer\Data\Util\ResetTable.txt` | Nivel/puntos/dinero por rango de resets |
| `MuServer\Data\Script\ScriptMain.lua` | Scripts Lua (⚠️ inestable, ver abajo) |
| `Cliente\MainInfo.ini` | IP/puerto/versión del cliente |

---

## 7. Pendientes / problemas conocidos

1. **Confirmar el rate de exp in-game.** Matar un monstruo y ver cuánta exp da.
   Si x3000 no cuadra, ajustar `AddExperienceRate_AL0` (recordá: 100 = 1x).
2. **Sistema de Fruits** — no es nativo. Ver el análisis en
   `docs/diseno-servidor.md` (sección 4).
3. **Lua inestable.** `Data\Script\Bridge\` está **vacío** y `ScriptMain.lua`
   llama funciones (`NpcOfPresent_Entry`, etc.) que **no existen**. Hay que
   limpiar el script antes de usar Lua para algo crítico.
4. **`Data\Custom\CustomRankUser`** no existe en este repack (el usuario lo
   confirmó). No usarlo.
5. **Exponer a internet** — pendiente de configurar port forwarding
   (`docs/09-exponer-a-internet.md`).
