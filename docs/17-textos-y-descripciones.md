# Textos del cliente: nombres, descripciones y avisos

> Cliente **1.02.44** (Season 2). Todo lo de esta guía está en `Cliente\Data\` o
> `Cliente\Data\Local\`.
> **No hace falta reiniciar el servidor**: son archivos del cliente. Cerrás el
> juego, editás, abrís de nuevo.

---

## 1. Mapa rápido: dónde está cada texto

| Lo que querés cambiar | Archivo | Formato | Estado |
|---|---|---|---|
| Nombre de un ítem | `Data\Local\Item.bmd` | 8192 registros × 84 b + 4 b; nombre al inicio | editable |
| **Descripción nativa de ítems especiales** | `Data\Local\Text.bmd` | 3000 registros × 300 b; índices 571+ | editable ★ |
| Línea extra en el tooltip (ítem cualquiera) | `Data\CustomTooltip.txt` | `grupo,index  nivel  fuente  color  "texto"` | editable (~25 car.) |
| Diálogos de NPC (globos de texto) | `Data\Local\Dialog.bmd` | 200 × 1024 b, XOR **por registro** | editable → `docs/16` |
| Lore, quests, textos de interfaz | `Data\Local\Text.bmd` | 3000 × 300 b, XOR continuo | editable |
| Consejos de pantalla de carga | `Data\Local\Slide.bmd` | 16 b + 160 × 256 b + 32 b | editable ★ (ya en español) |
| Nombres de monstruos / NPC | `Data\Local\NpcName(Kor).txt` | texto plano | editable |
| Menú de teletransporte (`/move`) | `Data\Local\MoveReq.bmd` | XOR continuo | ya editado (Crywolf) |
| Mensajes del servidor (errores, bienvenida) | `MuServer\Data\Message.txt` | texto plano | editable → `docs/16` |
| Avisos rotativos en pantalla | `MuServer\Data\Util\Notice.txt` | texto plano (tabulado) | editable → `docs/16` |
| Nombres de los comandos (`/reset`, `/pk`...) | `MuServer\Data\Command.txt` | texto plano | editable |
| Textos metidos dentro de `main.exe` | — | binario empaquetado (VMProtect) | **no editable** |

Clave del XOR de los `.bmd`: `FC CF AB`.

---

## 2. ¿Dónde está la descripción del Box of Luck? (respuesta corregida)

La frase que ves, **"Throw it and you may receive some Zen or items"**, está en:

```
Cliente\Data\Local\Text.bmd   ->   registro 571   (offset 171.300)
```

Ese registro hoy dice (con el contenido real de la caja y sus porcentajes):

> *Da: 50% Jewel of Creation o 50% Jewel of Chaos*

### Cómo funciona (esto es lo importante)

`Text.bmd` **no** es una tabla de 900 × 1000 bytes como se creyó al principio.
Verificado sobre el archivo real:

- **900.000 bytes = 3000 registros × 300 bytes.**
- XOR **continuo** con `FC CF AB` (fase = `offset % 3`, offset global del archivo).
- Texto **ANSI/CP1252**, terminado en `00`, máximo 269 caracteres.
- Índice del registro = `offset ÷ 300`.

Dentro de `Text.bmd` hay un **bloque fijo de descripciones de ítems**:

| Índice | Sirve para | Texto actual (español) |
|---:|---|---|
| 570 | filtro de chat | `Pwned by the Filter!` (sin traducir) |
| **571** | **Box of Luck** | `Da: 50% Jewel of Creation o 50% Jewel of Chaos` |
| 572 | Jewel of Bless | `Sirve para subir el nivel del ítem hasta 6` |
| 573 | Jewel of Soul | `Sirve para subir el nivel del ítem a 7, 8 y 9` |
| 574 | Jewel of Chaos | `Sirve para combinar ítems del Chaos` |
| 575 | alas / opción | `Absorbe el 30% del daño` |
| 576 | alas / opción | `Aumenta el 30% el daño de ataque y mágico` |
| 577-578 | opciones con `%d` | `Increase %d%% of Damage` / `Absorb %d%% of Damage` (sin traducir) |
| 579 | botas / opción | `Aumenta la velocidad` |
| 637 | Devil's Invitation | `Sirve para combinar ítems y crear una invitación a Devil Square` |

**El mapeo ítem → índice está hardcodeado en `main.exe`** (no hay columna de
descripción en `Item.bmd`: el nombre ocupa los primeros 34 bytes y el resto son
números). Por eso:

- ✅ **Se pueden traducir o reescribir** las descripciones que ya existen.
- ❌ **No se puede inventar** una descripción nueva para un ítem que no la tiene
  (el cliente nunca la va a buscar).
- 🔧 Para esos ítems queda `CustomTooltip.txt` (§3), que agrega una línea suelta
  al tooltip (pendiente de probar en el juego cuántos caracteres entran).

---

## 2.1 Las cajas comparten un solo ítem: `14,11`

Todas las cajas del servidor son el **mismo ítem** (`14,11`, plano **7179**); lo
que cambia es el **nivel** del ítem, y el nivel elige qué bolsa de
`MuServer\Data\EventItemBag\` se abre (según `EventItemBagManager.txt`):

| Nivel | Caja (bolsa) | Qué suelta |
|---:|---|---|
| 0 | `000 - Box of Luck` | 1 joya: **Jewel of Creation 50%** o **Jewel of Chaos 50%** (no da zen) |
| 1 | `003 - Star of Christmas` | 1000 zen + 1 ítem al azar (nivel 3-7, con luck/skill/opción) |
| 3 | `004 - Heart of Love` | 1000 zen + 1 ítem al azar |
| 5 | `005 - Silver Medal` | 1000 zen + 1 ítem al azar |
| 6 | `006 - Gold Medal` | 1000 zen + 1 ítem al azar |
| 7 | `030 - Box of Heaven` | 1 fruta al azar de 5 → **20% cada una** (Str/Agi/Vit/Ene/Cmd) |
| 8 | `007 - Box of Kundun 1` | **200.000 zen** + 1 equipo excellent al azar entre 76 → **1,3%** c/u |
| 9 | `008 - Box of Kundun 2` | 1 equipo excellent al azar entre 82 (Bronze) → **1,2%** c/u |
| 10 | `009 - Box of Kundun 3` | 1 equipo excellent al azar entre 66 (Dragon) → **1,5%** c/u |
| 11 | `010 - Box of Kundun 4` | 1 equipo excellent al azar entre 84 (Black Dragon) → **1,2%** c/u |
| 12 | `011 - Box of Kundun 5` | 1 equipo excellent al azar entre 58 (Great Dragon) → **1,7%** c/u |
| 13 | `031 - Blue Heart` | 1000 zen + 1 ítem al azar |

Cómo se leen las bolsas:

- **Tipo evento** (`Star of Christmas`, medallas, chocolates, lazos): sección 0 con
  `DropZen` (zen fijo), `ItemDropRate` = 100 (siempre cae 1 ítem) y
  `ItemDropCount` = 1.
- **Tipo caja** (`Box of Luck`, `Box of Heaven`, Kundun): secciones 3-4-5. La 4
  tiene el `MoneyAmount` (zen fijo) y la 5 la lista de ítems, que se reparte **por
  partes iguales** (el `Duration` no se usa como peso: 2 ítems = 50% y 50%).

Con eso:

- `Text.bmd` **571** es la descripción del ítem `14,11` y el cliente la muestra
  **en todos los niveles** (el mapeo es por ítem, no por nivel). Por eso la
  descripción nativa habla solo del **nivel 0** (Box of Luck).
- `CustomTooltip.txt` agrega una línea **por nivel**, con el detalle y el
  porcentaje de cada caja (§3).

Otras cajas que existen en el cliente y también tienen línea propia:
**Red / Green / Blue Ribbon Box** (`12,032` / `12,033` / `12,034`) y
**Pink / Red / Blue Chocolate Box** (`14,032` / `14,033` / `14,034`): todas dan
1000 zen + 1 ítem al azar.

> En `Text.bmd` y en `CustomTooltip.txt` el signo `%` se escribe **una sola vez**
> (`30%`, no `30%%`). El doble `%%` era una costumbre de los scripts de formato y
> en el juego se veía tal cual.

---

## 3. Línea extra de tooltip (`CustomTooltip.txt`)

Formato (columnas separadas por espacios o tabulaciones):

```
// ItemIndex   ItemLevel   FontValue   FontColor   Text
14,011        *           1           1           "Contiene un item al azar"
```

- `14,011` = grupo 14, index 11 = **Box of Luck** (según `Item.txt`).
- `ItemLevel`: `*` = todos los niveles, o un número (0, 1, 2...).
- `FontValue`: `0` = fuente normal, `1` = negrita (probar).
- `FontColor`: `0` a `10` (paleta del cliente).
- `Text`: entre comillas. **~25 caracteres** según el propio archivo; si necesitás
  más, probá y fijate si corta.
- Terminá el archivo con una línea `end`.

Índice plano (el que usan otros archivos, ej. `EventItemBagManager.txt`):
`grupo × 512 + index` → Box of Luck = **7179**.

> Se comentó la línea de basura del repack (`02,050 ... "Mace foda"`, que se
> agregaba al **Mace of King**). Backup: `CustomTooltip.txt.bak-MaceFoda`.

### Lo que está aplicado hoy

`scripts\textos-cliente\custom-tooltip.txt` (UTF-8, formato
`item|nivel|fuente|color|texto`) genera **18 líneas**: una por cada nivel de
`14,011` (las cajas de §2.1) y una por cada lazo y chocolate. Se aplican con:

```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\aplicar-textos-cliente.ps1
```

El script valida el formato, rechaza textos de más de 25 caracteres y reemplaza
solo el bloque entre `// >>> MuNega: contenido de las cajas` y
`// <<< MuNega: contenido de las cajas`; el resto del archivo queda igual
(incluido el encabezado del repack).

⚠️ **Sin verificar en el juego**: `main.exe` está empaquetado (VMProtect) y no se
puede leer para confirmar que use este archivo. Si al pasar el mouse por una caja
no aparece la línea, se borra el bloque y las cajas quedan solo con la
descripción nativa de `Text.bmd`.

---

## 4. Cómo cambiar el nombre de un ítem (`Item.bmd`)

- Tamaño **688.132 bytes** = 8192 registros × 84 + 4 bytes finales
  (`CA 57 D2 BE`, no tocar).
- Cifrado: XOR **continuo** con `FC CF AB`, fase = `offset % 3` (offset global).
- El nombre está en el **offset 0** de cada registro: 34 bytes, **ANSI (CP1252)**,
  terminado en `00`.
- Posición del registro = `grupo × 512 + index` (ej. Box of Luck = 7179).
- Nombre más largo actual: 28 caracteres (*Divine Crossbow of Archangel*).
- Si cambiás un nombre en el cliente, cambialo igual en
  `MuServer\Data\Item\Item.txt` para que coincidan (el servidor lo usa en algunos
  mensajes y en el bag de drops).

---

## 5. Consejos de pantalla de carga (`Slide.bmd`)

Mientras carga el mapa, el cliente muestra tips. **Ya están en español** y
explican lo particular de este servidor (reset, `/pick`, `/offattack`, `/store`,
`/bau`, `/pk`), sin gastar tips en `/move` ni `/post` (que ya son conocidos).

- Formato: **16 bytes de cabecera + 160 registros × 256 bytes + 32 bytes
  finales** = 41.008 bytes.
- XOR continuo `FC CF AB`, ANSI, terminado en `00`.
- **Solo los slots 0 a 31 tienen texto** (el resto está en cero); el cliente usa
  ese pool, así que los tips nuevos se escriben ahí.
- Reemplazaron a los tips oficiales en inglés: coordenadas de Devias/Noria,
  baúles, vendedores de Lorencia y Noria, teclas Q/W/E, hotkeys, etc.

### Cómo se editan

No se toca el `.bmd` a mano: los textos viven en texto plano y un script los
mete en el archivo.

1. Editá `scripts\textos-cliente\slide-tips.txt` (UTF-8, una línea por slot,
   la línea 1 = slot 0; máximo 32 líneas).
2. Corré:

```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\aplicar-textos-cliente.ps1
```

El script hace backup, escribe en CP1252, mantiene los 41.008 bytes y verifica el
tamaño. También aplica `Notice.txt` y las descripciones de `Text.bmd`.

---

## 6. Reglas para no romper nada

1. **Backup** del archivo antes de tocarlo (`.bak`).
2. Mantener **el tamaño exacto** del archivo.
3. Texto **ANSI/CP1252** (los acentos funcionan: á é í ó ú ñ ¿ ¡).
4. Terminar cada texto con `00` y rellenar el registro con `00`.
5. Respetar el tipo de XOR: **continuo** (Item, Text, Slide, MoveReq) vs
   **por registro** (Dialog.bmd, la clave reinicia en cada registro).
6. Cerrar el cliente antes de editar. El servidor **no** se toca.

---

## 7. Problemas típicos

| Síntoma | Causa probable |
|---|---|
| El cliente crashea al abrir el inventario | tamaño del archivo distinto, o falta el `00` final |
| El texto sale con símbolos raros (Ã, ©...) | fase de XOR incorrecta o el archivo quedó en UTF-8 |
| El texto no aparece | cerrá y abrí el juego de nuevo (el cliente cachea) |
| Los acentos salen como `?` | se guardó en ASCII en vez de CP1252 |
| En el chat sale **`Could not find message N!`** | **no es un texto del cliente**: es el `GameServer.exe` pidiendo un índice que no existe en `MuServer\Data\Message.txt` (§8) |

### Sobre `Could not find message N!`

`Message.txt` del repack (traducido al español) solo tenía los índices **0 a
267**. El `GameServer.exe` (base Season 6) usa índices hardcodeados más altos
(bienvenida en el **338**, bonus en **800/801**, invasión en **802/803/804**) y,
cuando no los encuentra, manda ese cartel al chat. No rompe nada, pero tampoco
muestra el mensaje real.

Ya se agregaron esos índices (y se corrigió el `30%%`):

```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\aplicar-mensajes-servidor.ps1
```

- Los mensajes nuevos están en `scripts\textos-cliente\mensajes-servidor.txt`
  (UTF-8, `indice|texto`).
- El script reescribe `MuServer\Data\Message.txt` **ordenado y completo**
  (207 mensajes, 0..804), con backup, y valida que todo sea CP1252.
- `Message.txt` se lee **al arrancar el GameServer**: hay que reiniciar con
  `RECARGAR-GAMESERVER.cmd` (admin) para que tome efecto.

Si vuelve a aparecer un `Could not find message N!`, anotá el número exacto: se
agrega esa línea al archivo de arriba y se vuelve a correr el script.

---

## 8. Pendientes / ideas

- [x] Confirmar de dónde sale la descripción del Box of Luck → `Text.bmd` 571.
- [x] Traducir las descripciones nativas (571-576, 579, 637).
- [x] Comentar el `"Mace foda"` de `CustomTooltip.txt`.
- [x] Pasar `Slide.bmd` a español con tips de comandos propios.
- [x] Poner el contenido y los porcentajes de las cajas (571 + 18 líneas de
      `CustomTooltip.txt`) → §2.1 y §3.
- [x] Agregar los índices faltantes de `Message.txt` (338 y 800-804) →
      `scripts\aplicar-mensajes-servidor.ps1`.
- [ ] Probar en el juego si `CustomTooltip.txt` agrega la línea a las cajas
      (nivel 0 = Box of Luck) y si entra completa.
- [ ] Traducir índice 570 (`Pwned by the Filter!`) y 577/578.
- [ ] Decidir si traducimos nombres de ítems (no recomendado: rompe búsquedas,
      guías y el bag de drops si no se cambia también en el servidor).
