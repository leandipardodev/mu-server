# Servidor MU Online 1.02N — Proyecto

Servidor de MU Online versión **1.02N** (era clásica, sin clases modernas) para
**uso público en internet**, sobre **Windows + SQL Server**.

> **Repack elegido: MuEmu Season 2 (1.02r) + Unstable Moon** (emulador).
> Guía específica: **`docs/08-muemu-season2.md`**.
> Hilo: https://tuservermu.eu/index.php?topic=386.0

> Estado actual: **servidor funcionando en local** (los 6 componentes arrancan,
> login verificado, mapa Arena/Stadium reparado). Falta confirmar la prueba in-game
> y exponerlo a internet.
> **Cómo arrancar y jugar: `docs/10-como-jugar.md`.**
> Comandos: **`docs/12-comandos-admin.md`**. Herramientas: **`docs/13-herramientas.md`**.
> Diseño del servidor: **`docs/diseno-servidor.md`**.

---

## Estructura del proyecto

```
servidor mu/
├── README.md                 <- este archivo
├── INICIAR-SERVIDOR.cmd      <- arranca todo el servidor
├── DETENER-SERVIDOR.cmd      <- apaga el servidor
├── JUGAR.cmd                 <- abre el cliente
├── docs/                     <- guía paso a paso
│   ├── 01-obtener-archivos.md
│   ├── 02-sql-server.md
│   ├── 03-configurar-muserver.md
│   ├── 04-cliente.md
│   ├── 05-deploy-vps.md
│   ├── 06-seguridad.md
│   ├── 07-puertos.md
│   ├── 08-muemu-season2.md   <- guía del repack elegido (MuEmu)
│   ├── 09-exponer-a-internet.md <- abrir puertos / DDNS desde tu PC
│   ├── 10-como-jugar.md      <- arrancar, detener y jugar (LEER PRIMERO)
│   ├── 11-servidor-en-detalle.md <- comandos, rates, eventos y customs
│   ├── 12-comandos-admin.md  <- lista completa de comandos (jugador y GM)
│   ├── 13-herramientas.md    <- MuMaker, editores y utilidades
│   ├── 14-mapas-file-corrupted.md <- error "file corrupted" (Arena y otros mapas)
│   ├── 15-fps-y-rendimiento.md <- FPS, info bar y rendimiento del cliente
│   ├── 16-anuncios-y-npc.md  <- avisos en pantalla y diálogos de los NPC
│   ├── 17-textos-y-descripciones.md <- nombres, descripciones y textos del cliente
│   └── diseno-servidor.md    <- decisiones del servidor (rates, resets, etc.)
├── MuServer/                 <- el repack MuEmu (configurado)
├── Cliente/                  <- cliente 1.02.44 (parcheado)
├── scripts/                  <- scripts de ayuda (PowerShell)
│   ├── instalar-sql-express.ps1 / .cmd  <- instala y configura SQL
│   ├── abrir-puertos-firewall.ps1       <- abre puertos en el firewall
│   ├── restaurar-bases.ps1
│   ├── verificar-puertos.ps1
│   ├── aplicar-config-servidor.ps1      <- aplica el diseño (exp/resets)
│   ├── aplicar-anuncios.ps1             <- avisos, bienvenida, NPC y Dialog.bmd
│   ├── editar-dialog-bmd.ps1            <- edita los diálogos de NPC (BMD)
│   ├── arreglar-castle-siege.ps1        <- corrige las fechas de Castle Siege
│   ├── iniciar-servidor.ps1
│   └── detener-servidor.ps1
└── sql/
    └── crear-login-muserver.sql
```

---

## Roadmap

- [x] **Fase 1 — Conseguir el repack** → `docs/01` + `docs/08-muemu-season2.md`
- [x] **Fase 2 — Instalar SQL Server y restaurar las bases** → `docs/02-sql-server.md`
- [x] **Fase 3 — Configurar los componentes del MuServer** → `docs/03-configurar-muserver.md`
- [x] **Fase 4 — Preparar el cliente** → `docs/04-cliente.md`
- [ ] **Fase 5 — Probar en local (LAN)** → probar login in-game (`docs/10-como-jugar.md`)
- [ ] **Fase 6 — Auditar backdoors y asegurar** → `docs/06-seguridad.md`
- [ ] **Fase 7 — Deploy en VPS (público)** → `docs/05-deploy-vps.md`

Se avanza en ese orden. No saltes a la Fase 7 sin haber pasado por la 6.

---

## Requisitos

### Para probar en tu PC (desarrollo)
- Windows 10/11 (tenés Windows 11 Pro ✔)
- 4 GB RAM libres mínimo (tenés 11.8 GB ✔)
- SQL Server 2019/2022 **Express** (gratis)
- El repack 1.02N + un cliente 1.02N compatible

### Para producción (público)
- **VPS Windows** (2 vCPU / 4 GB RAM / 60 GB SSD como base)
- SQL Server (Express sirve al principio; luego Standard si crece)
- Protección **DDoS**
- Dominio + web de registro + launcher

---

## Referencia rápida: componentes y puertos

| Componente      | Función                          | Puerto típico |
|-----------------|----------------------------------|---------------|
| ConnectServer   | Indica al cliente a dónde conectar | 44405 TCP   |
| JoinServer      | Login / creación de cuentas      | 55970 TCP     |
| DataServer 1    | Persistencia (parte 1)           | 55960 TCP     |
| DataServer 2    | Persistencia (parte 2)           | 55962 TCP     |
| GameServer      | Lógica del juego                 | 55901 TCP/UDP |
| GameServerCS    | Castle Siege                     | 55919 TCP/UDP |
| EventServer     | Eventos (Blood Castle, etc.)     | 55920 TCP     |
| RankingServer   | Rankings                         | 55921 TCP     |
| ExDB            | Base de datos de eventos         | variable      |

> Los puertos exactos **varían según el repack**. Verificalos en `docs/07-puertos.md`
> y en los `.ini` de tu repack.

---

## Bases de datos

Con **MuEmu** (nuestro repack) son 3 principales, creadas desde scripts `.sql`:

| Base           | Contenido                                  |
|----------------|--------------------------------------------|
| `MuOnline`     | Cuentas, personajes, ítems, guilds         |
| `Events`       | Eventos (Blood Castle, Devil Square, etc.) |
| `Ranking`      | Rankings                                   |

(Los repacks clásicos usan `MuOnline`, `Me_MuOnline` y `Ranking`.)

---

## Aviso

Los binarios de MU Online son propiedad de **Webzen**. Correr un servidor privado
es una zona legal gris según el país. Además, los repacks filtrados suelen traer
**backdoors**: hay que auditarlos antes de exponerlos a internet (Fase 6).
