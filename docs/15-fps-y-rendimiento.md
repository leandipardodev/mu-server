# 15 - FPS y rendimiento del cliente (1.02.44 MuEmu)

## Resumen corto

El cliente clásico de MU **no tiene un ajuste de FPS en ningún archivo de configuración**.
El límite de cuadros está dentro de `Cliente\main.exe`, que viene **protegido con VMProtect**
(sus secciones se llaman `.vmp0` y `.vmp1`), así que **no se puede parchear** de forma segura
ni existe una opción para subirlo a 60.

Lo que sí se puede hacer es **quitar todo lo que le resta FPS por debajo del tope del motor**
(plan de energía, driver de video, resolución, apps en segundo plano).

## Cómo mirar los FPS

`Cliente\MainInfo.ini` ya tiene el contador activado:

```ini
[Custom]
InfoBar = 1
```

En la barra superior del juego aparece:

```
<NombreVentana> :: Character: <nombre> :: Level: <nivel> (<resets>) :: FPS: <n> :: (Update: <fecha>)
```

Interpretación:

| Lo que ves | Qué significa |
|---|---|
| Número estable (por ejemplo ~25–30) que casi no sube nunca | Es el **tope interno del motor** 1.02. No es tu PC. |
| Número que baila entre 15 y 60 | Es **rendimiento**: falta CPU/GPU, hay apps de fondo, o el driver de video está viejo. |
| Número muy bajo (< 15) y el juego se traba | Casi siempre **render por software** de OpenGL o el equipo en modo ahorro. |

## Cosas que sí mejoran los FPS (en orden de impacto)

1. **Plan de energía "Alto rendimiento"** (ya aplicado el 13/11/2026).
   El i5-1035G1 es de 1,0 GHz base; en "Equilibrado" con el servidor MU encima se queda
   a ~1 GHz y el cliente pierde cuadros. Para volver a ponerlo:
   ```cmd
   powercfg /list
   powercfg /setactive f26e2a62-5133-486a-8ae8-077b51f8ad01
   ```
   (el GUID puede cambiar si se crea de nuevo; elige el que diga *Alto rendimiento*).

2. **Portátil enchufado a la corriente.** Con batería el equipo baja el reloj aunque
   el plan sea Alto rendimiento.

3. **Driver de video Intel actualizado.** Hoy está en `27.20.100.8935` (octubre 2020).
   MU usa OpenGL; con un driver viejo se pierde mucho rendimiento. Descarga el driver
   más nuevo para *Intel UHD Graphics (Ice Lake)* desde la página de Intel o del
   fabricante del portátil.

4. **Bajar la resolución del juego.** Ya está en ventana 1024x768.
   Si quieres más margen, prueba 800x600 (mismo método `.reg` que
   `_window_mode.reg` / `1024x768.reg`).

5. **Cerrar lo que sobra.** Navegador, Discord con overlay, grabadores.
   El servidor MU completo consume ~4–5 GB de RAM de los 11,8 GB del equipo.

6. **Prioridad del proceso.** `Main.dll` ya sube la prioridad del hilo del cliente
   (`SetThreadPriority`), no hace falta hacerlo a mano.

## Lo que NO funciona / no existe

- No hay `FpsLimit`, `MaxFps` ni similar en `MainInfo.ini`. Ese archivo solo controla
  IP, nombre de ventana, info bar, reconexión y el nombre del servidor.
- No hay tool de FPS en `MuServer\Tools` ni en el repack.
- Cambiar el FPS desde el servidor es imposible: el servidor no manda cuadros.

## Plugin de 60 FPS: "VSyncLib" de takumi12 — PROBADO Y DESCARTADO

Se descargó el paquete `GL_2_SHADER.zip` (contiene `VSyncLib.GLIB`, `glew32.dll` y la carpeta
`shader\`) desde `https://tuservermu.com.ve/index.php?topic=90711.0` y se probó el 13/11/2026.

**Resultado: el cliente 1.02.44 NO carga plugins externos.**

| Prueba | Configuración | Resultado |
|---|---|---|
| 1 | `PluginName = "VSyncLib.GLIB"` | no se carga |
| 2 | `PluginName = "VSyncLib.dll"` (misma librería, otra extensión) | no se carga |
| 3 | Control: `PluginName = "glew32.dll"` (DLL nativa común) | **tampoco se carga** |
| 4 | `PluginName5 = "glew32.dll"` | no se carga |
| 5 | `PluginName` con ruta completa | no se carga |
| 6 | VSyncLib renombrado a `GameGuard.dll` (nombre fijo) | no se carga |

Cómo se verificó: se lanzó el cliente y se enumeraron sus módulos cargados con PowerShell de
32 bits (`SysWOW64`). `Main.dll` sí aparece; `glew32.dll` / `VSyncLib.GLIB` nunca.

Conclusión: en este `main.exe` las claves `PluginName` / `PluginName5` de `MainInfo.ini`
**no ejecutan ninguna carga de librería** (o exigen una firma/validación que no tenemos).
La ruta del plugin queda **cerrada** para este cliente.

Los archivos quedaron guardados fuera del cliente, en `descargas\vsynclib\`, y `MainInfo.ini`
se restauró byte a byte a su estado anterior.

Datos del plugin (por si algún día se cambia de cliente): fue diseñado para mains Season 6
(1.04e, clientes basados en `Main.dll`), está protegido con Themida/WinLicense (sección
`.fptable`), y el propio autor aclara: *"la lógica sigue siendo 25 fps, solo el renderizado es
de 60 fps"*. En el hilo se reportan crasheos, desconexiones con buffs de Wizard/RF e
incompatibilidad con la DLL `CEffect`.

## Advertencia si algún día consigues otro `main.exe` con FPS desbloqueado

Desbloquear los FPS en un cliente 1.02 **desincroniza las animaciones** respecto al
servidor (ataques, skills, movimiento). El servidor calcula a su propio ritmo
(~el tick clásico del motor) y el cliente mostraría la animación más rápido:
golpes que "no registran", animaciones cortadas y sensación de lag.
**No se recomienda** cambiarlo solo por tener "60" en el contador.
