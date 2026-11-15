# Herramientas MU

Carpeta para software/utilidades que ayudan a administrar y editar el servidor y cliente de MU.

## Herramientas disponibles
- **Editor-Textos/** — Editor local (Python/Tkinter) de textos del servidor y cliente.
  - Ejecutar: `Editor-Textos\MU-Text-Editor.bat`
  - Edita: `MuServer\Data\Message.txt`, `Notice.txt`, `Data\Monster\Monster.txt`, y del cliente `Dialog.bmd`, `Slide.bmd`, `Text.bmd`.
  - Detecta automáticamente la carpeta raíz del MU. Si hace falta forzar la ruta, crear `Editor-Textos\mu_path.txt` con la ruta completa del MU.

- **Editor-Config-Servidor/** — Editor local de configuración del GameServer.
  - Ejecutar: `Editor-Config-Servidor\Editor-Config-Servidor.bat`
  - Edita `MuServer\GameServer\DATA\GameServerInfo - *.dat`: rates/EXP/drop, reset, comandos (/pk, /ware, /post), /store, /offattack, eventos, IPs/puertos y más.
  - Incluye pestaña de **configuración común** (con ayuda `?`) y modo **avanzado**. Crea backups `.bak-editorcfg-*`. Requiere reiniciar GameServer para aplicar.

- **Editor-Spots/** — Editor visual de spawns (monstruos/NPCs) sobre el mapa.
  - Ejecutar: `Editor-Spots\Editor-Spots.bat`
  - Edita `MuServer\Data\Monster\MonsterSetBase.txt` y `MonsterSetBaseCS.txt` con vista de mapa (imágenes en `MuServer\Tools\MonsterSpawnEditorV1.01\MonsterSpawnEditor\Images\`), filtros, búsqueda, agregar/mover/duplicar/eliminar spots y selector de monstruos.
  - Recomendado: `pip install pillow` para ver imágenes de mapas. Crea backups `.bak-spots-*`. Requiere reiniciar GameServer para aplicar.

## Convenciones
- Cada herramienta en su propia subcarpeta.
- Guardar backups antes de modificar archivos del servidor/cliente.
- Preferir herramientas que funcionen localmente y con rutas configurables (útil al migrar el MU a otra PC).
