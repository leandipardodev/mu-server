# Editor de Configuración del Servidor

Herramienta local (Python/Tkinter) para editar la configuración del GameServer de MU sin modificar los `.dat` a mano.

## Qué edita
Archivos en `MuServer\GameServer\DATA\`:
- `GameServerInfo - Common.dat` (servidor, conexiones, rates/exp/drop/zen, monstruos, PK, joyas, frutas, etc.)
- `GameServerInfo - Command.dat` (comandos: /reset, /pk, /ware, /post, /addpoint, etc.)
- `GameServerInfo - Custom.dat` (/store, /offstore, /attack, /offattack y opciones custom)
- `GameServerInfo - Event.dat` (activar/desactivar eventos: BC, DS, CC, invasiones, Castle Siege, Crywolf, Kanturu, etc.)
- `Character`, `ChaosMix`, `Skill` (mediante modo avanzado)

## Uso
1. Ejecutar `Editor-Config-Servidor.bat`.
2. **Configuración común:** pestaña con campos principales (rates, reset, comandos, eventos, IPs/puertos) y sus valores.
3. **Avanzado (por archivo):** permite ver y editar cualquier clave `clave = valor` del archivo seleccionado.
4. Guardar cambios y **reiniciar el GameServer** para que se apliquen.

## Notas
- Detecta automáticamente la raíz del MU (carpeta con `MuServer` y `Cliente`). Para forzar ruta, crear `mu_path.txt` junto al `.py` con la ruta del MU.
- Antes de guardar crea backups (`.bak-editorcfg-*`) en la misma carpeta `DATA`.
- Preserva comentarios y estructura de los `.dat` al actualizar valores existentes.
- Si una clave no existe en el archivo, al guardarla se agrega al final. Revisá valores y reiniciá el GameServer tras cambios importantes (IPs/puertos, rates, etc.).
