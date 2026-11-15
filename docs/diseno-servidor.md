# Diseño del servidor MU — Decisiones

> Documento **vivo**: se completa a medida que definimos cosas.
> Última actualización: 2026-11-11

---

## 1. Identidad

| Tema | Valor |
|---|---|
| Nombre | **A definir** (provisorio: "Mu [tu nombre]") |
| Versión | MU Online **1.02N** / repack **MuEmu Season 2 (1.02r)** |
| Público | **Español (LatAm)** |
| Estilo | Clásico + customs |

---

## 2. Infraestructura

- Corre en **tu PC** (Windows 11 Pro).
- **Online cuando quieras** (on-demand), para probar con amigos.
- Acceso desde internet: **port forwarding** en el router
  (puertos `44405`, `55901` y `55919`/`55920` si aplica).
- Base de datos: **SQL Server 2019 Express** local (`.\SQLEXPRESS`, puerto `1433`).
- Comunicación: **Discord** (canal donde avisás cuando el server está online).
- Futuro: migrar a **VPS Windows** si el server crece.

> Tip: como la IP pública suele ser **dinámica**, conviene un **DDNS gratis**
> (DuckDNS / No-IP) para que tus amigos siempre entren con el mismo nombre.

---

## 3. Progresión

| Tema | Valor |
|---|---|
| Exp rate | **x3000** |
| Drop / zen | **Alto (x2–x5)** |
| Nivel máximo | 400 |
| Reset | A nivel **400**, **conservando los stats** (los puntos repartidos NO se pierden) |
| Puntos por reset | **1000 puntos** de stats por cada reset |

> **Cómo se escribe el rate:** en los archivos del servidor **`100` = 1x**
> (porcentaje). x3000 se escribe `300000` en `AddExperienceRate_AL0`.
> La exp final = (rate del mapa) × (`ExperienceTable`) × (`AddExperienceRate`).

---

## 4. Sistema de resets (CUSTOM — con "Fruits")

- **Resets 1 a 50:** reset normal.
- **Desde el reset 51:** hay que entregar **Fruits**.
  - Reset 51 → **1 fruit**
  - Reset 52 → **2 fruits**
  - Reset 53 → **3 fruits**
  - … y así, +1 fruit por cada reset.
- Cada **color de fruit** corresponde a una **clase**.
  Cada personaje necesita la fruit **de su color/clase**.

### Colores propuestos (5 clases)

| Clase | Color de fruit |
|---|---|
| Dark Wizard (DW) | Azul |
| Dark Knight (DK) | Rojo |
| Fairy Elf (Elf) | Verde |
| Magic Gladiator (MG) | Violeta |
| Dark Lord (DL) | Negro |

### Reglas de las fruits

| Tema | Valor |
|---|---|
| Origen | **Solo Chaos Machine** (`Creation` + `Jewel of Chaos`) |
| Comerciables | **Sí** (se pueden vender/intercambiar entre jugadores) |

### Viabilidad técnica (verificado en el repack)

Resultado de inspeccionar `GameServer.exe`, los `.dat` y el API Lua:

| Pregunta | Respuesta |
|---|---|
| ¿MuEmu tiene "requisito de ítem por reset" nativo? | ❌ **No.** `CommandResetCheckItem` significa **"requiere desequipar items"**, NO "requiere un item". |
| ¿Se puede hacer con Lua? | ⚠️ **Parcialmente.** Ver abajo. |
| ¿El API Lua puede contar/borrar items? | ✅ Sí: `InventoryGetItemCount`, `InventoryDelItemCount`, `InventoryGetItemIndex`, `InventoryDelItemIndex`. |
| ¿El API Lua puede incrementar el reset? | ❌ **No hay `SetObjectReset`** (sí hay `GetObjectReset`). |
| ¿El API Lua puede escribir en la base? | ✅ Sí: `SQLConnect`, `SQLQuery`, `SQLGetResult`, `SQLGetString`, `SQLGetNumber`, `SQLFetch`, `SQLClose`. |

**Conclusión:** el chequeo de Fruits (contar + borrar) **sí** es posible en Lua,
pero **el incremento del reset no**. Opciones:

- **A. Híbrido Lua + SQL** — interceptar `/reset` en `OnCommandManager`, chequear
  y borrar los Fruits, y hacer `SQLQuery("UPDATE Character SET ResetCount = ResetCount + 1 ...")`.
  Riesgo: el contador en memoria no se actualiza hasta relogear.
- **B. Lua bloquea + reset nativo** — si `OnCommandManager` puede **bloquear** el
  `/reset` nativo (devolver el valor correcto), el reset real lo hace el server
  y solo chequeamos/borramos Fruits. **Es la opción más limpia. Hay que probar
  qué valor de retorno bloquea.**
- **C. Simplificar** — que el reset cueste **zen** (nativo) y los Fruits sean
  solo un ítem coleccionable / cosmético, sin requisito real.

> ⚠️ **Bloqueante:** el Lua del repack es **inestable**. `Data\Script\Bridge\`
> está vacío y `ScriptMain.lua` llama funciones inexistentes
> (`NpcOfPresent_Entry/Close/Timer/Shut`). Hay que limpiarlo antes de confiar
> en él para algo crítico.

---

## 5. PvP

- **PK abierto** (PvP libre fuera de las ciudades).

---

## 6. Customs

- Usamos los customs del repack (HPBar, tecla F5, ítems custom).
- **Además agregamos contenido propio** más adelante.

---

## 7. Monetización

- **Donaciones voluntarias** → **VIP leve**
  (bonus chico de exp/zen, o slots extra de personaje).

---

## 8. Registro, web y launcher

| Tema | Valor |
|---|---|
| Registro | **Web de registro + launcher propio** |
| Hosting de la web | **Hosting gratis** (Netlify / Vercel) |

---

## 9. Pendientes

- [ ] **Nombre** del servidor.
- [ ] **Anticheat**.
- [ ] **Auditoría de backdoors** (Fase 6 — obligatoria antes de exponer a internet).
- [ ] **Confirmar rate de exp in-game** (matar un monstruo y medir).
- [ ] **Decidir el enfoque del sistema de Fruits** (A, B o C — ver sección 4).
- [ ] **Limpiar `ScriptMain.lua`** (llama funciones inexistentes; Lua inestable).
