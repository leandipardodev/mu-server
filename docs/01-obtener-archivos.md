# Fase 1 — Conseguir el repack 1.02N

Objetivo: tener en `MuServer/` los binarios, datos y scripts SQL de un repack 1.02N.

---

## ¿Dónde se consiguen?

Los archivos circulan en foros de desarrollo de MU. Los más activos hoy:

- **RaGEZONE** — sección *MU Online Releases*
  https://forum.ragezone.com/forums/mu-online-releases.197/
- **TuServerMu** — foro europeo, subforos *Season1 / Season2*
  https://tuservermu.eu

Hay que **registrarse** para ver los enlaces de descarga.

### Términos de búsqueda útiles
- `MuServer 1.02N`
- `1.02n repack`
- `MuServer 1.02N + Client`
- `TosaMu 1.02N`
- `1.02c / 1.02d / 1.02e` (misma era, variantes)

> Elegí un repack que **incluya el cliente** de la misma versión. Emparejar
> servidor y cliente equivocados es el error más común y hace perder días.

---

## ¿Qué trae un repack completo?

```
MuServer/
├── ConnectServer/       -> ConnectServer.exe + Data/ServerList.dat
├── JoinServer/          -> JoinServer.exe
├── DataServer1/         -> DataServer.exe (instancia 1)
├── DataServer2/         -> DataServer.exe (instancia 2)
├── GameServer/          -> GameServer.exe + Data/ (mapas, ítems, monstruos)
├── GameServerCS/        -> GameServerCS.exe (Castle Siege)
├── EventServer/         -> EventServer.exe + Data/
├── RankingServer/       -> RankingServer.exe
├── ExDB/                -> ExDB.exe
└── ...
DB/  o  SQL/             -> .bak de las bases o scripts .sql
Client/                  -> cliente 1.02N (main.exe, Data/, etc.)
```

Los nombres exactos cambian de un repack a otro. Lo importante es identificar:
1. Los **.exe** de cada componente.
2. La carpeta de **Data** del GameServer (mapas/ítems).
3. Las **bases de datos** (`.bak` para restaurar, o `.sql` para ejecutar).
4. El **cliente** compatible.

---

## Checklist antes de confiar en un repack

- [ ] Lo bajé de un hilo con **reputación** y comentarios de otros usuarios.
- [ ] Incluye **cliente** de la misma versión.
- [ ] Incluye bases (`.bak`/`.sql`) **o** dice claramente de dónde sacarlas.
- [ ] Tiene **guía de instalación** (los buenos la traen).
- [ ] Escaneé el ZIP con **VirusTotal** (los `.exe` van a salir marcados igual, es normal).
- [ ] Lo pienso ejecutar **primero en una VM aislada** (ver Fase 6).

⚠️ **Nunca** ejecutes el GameServer/JoinServer directo en tu PC de uso diario sin
haber auditado antes. Los repacks traen backdoors con frecuencia.

---

## Al terminar esta fase

Dejá los archivos así:

```
MuServer/            <- todo el contenido del repack
sql/bak/             <- los .bak de MuOnline, Me_MuOnline, Ranking
```

Y avisame qué repack conseguiste: con eso ajusto la configuración exacta
(nombres de archivos, puertos y rutas cambian entre repacks).

Siguiente: **`docs/02-sql-server.md`**
