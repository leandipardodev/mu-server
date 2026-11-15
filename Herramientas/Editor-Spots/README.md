# Editor de Spots (Spawns)

Editor visual local para spawns de monstruos/NPCs del servidor MU.

## Archivos que edita
- `MuServer\Data\Monster\MonsterSetBase.txt`
- `MuServer\Data\Monster\MonsterSetBaseCS.txt`

Usa imágenes de mapas desde `MuServer\Tools\MonsterSpawnEditorV1.01\MonsterSpawnEditor\Images\` (si están disponibles) y nombres de monstruos desde `MuServer\Data\Monster\Monster.txt`.

## Funciones
- Visualización del mapa con spots (coordenadas 0-255) y zoom/ajuste.
- Filtro por mapa y búsqueda por ID/nombre/comentario/coordenadas.
- Selección en mapa o lista, arrastrar para mover, edición de campos (Monstruo ID, Mapa, Rango, X, Y, Dirección, Bloque, Comentario).
- Crear, duplicar y eliminar spots; buscador de monstruos por ID/nombre.
- Guardado con backup automático (`.bak-spots-*`).

## Uso
1. Ejecutar `Editor-Spots.bat`.
2. Elegir archivo y mapa, editar spots en el mapa/lista/formulario.
3. **Guardar** y **reiniciar el GameServer** para aplicar cambios.

## Notas
- Requiere Python 3 con Tkinter. Para ver imágenes de mapa se recomienda `Pillow` (`pip install pillow`); sin Pillow se muestra una grilla de referencia.
- Detecta automáticamente la raíz del MU. Para forzarla, crear `mu_path.txt` junto al `.py` con la ruta del MU.
- `Rango`: radio/área de aparición según configuración del spawn. `Dirección`: orientación (-1/valores según tipo). `Bloque`: índice del bloque en el archivo (agrupación interna del `MonsterSetBase`).
- Siempre se crean backups antes de guardar, pero conviene mantener copias propias al hacer cambios grandes.
