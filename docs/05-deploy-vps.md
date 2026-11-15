# Fase 7 — Deploy en VPS (público)

> ⚠️ No hagas esto antes de completar la **Fase 6 (seguridad)**. Un servidor
> público con backdoors sin limpiar dura horas.

---

## 7.1 Elegir el VPS

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| SO | Windows Server 2019 | Windows Server 2022 |
| vCPU | 2 | 4 |
| RAM | 4 GB | 8 GB |
| Disco | 60 GB SSD | 100 GB SSD |
| Red | 1 Gbps | 1 Gbps + DDoS |

**MU 1.02N es liviano**: con 4 GB RAM y 2 vCPU corre cómodo para decenas de
jugadores. Lo que sube el costo es el **DDoS** y el ancho de banda.

Proveedores con foco en MU (incluyen DDoS): buscá hosts de game servers.
Alternativas generales: cualquier VPS Windows de buena reputación.

---

## 7.2 Puesta en marcha en el VPS

1. Instalar **SQL Server Express** (misma guía que `docs/02`).
2. Copiar la carpeta `MuServer/` completa.
3. Restaurar las bases (`scripts/restaurar-bases.ps1`).
4. **Reemplazar todas las IPs** de `127.0.0.1`/LAN por la **IP pública del VPS**
   en: ConnectServer, JoinServer, GameServer, DataServer, cliente.
5. Abrir los puertos en el **firewall de Windows** y en el **firewall del
   proveedor**:

```powershell
$ports = 44405,55901,55919,55920,55970,55960,55962
foreach ($p in $ports) {
  New-NetFirewallRule -DisplayName "MU-$p" -Direction Inbound -Protocol TCP -LocalPort $p -Action Allow
}
```

6. Iniciar los componentes (`scripts/iniciar-servidor.ps1`).
7. Probar la conexión **desde otra red** (no desde el propio VPS).

### Puertos a exponer al mundo
Solo los que el **cliente** necesita:
- **44405 TCP** (ConnectServer)
- **55901 TCP/UDP** (GameServer)
- **55919 TCP/UDP** (GameServerCS)
- (55920 si el cliente lo usa)

Los puertos internos (DataServer, JoinServer) **NO** deben exponerse a internet.
Dejalos solo en `127.0.0.1` o en la red privada del VPS.

---

## 7.3 Web de registro + launcher

Para que la gente se registre necesitás una web que escriba en `MuOnline`:

- **MuCore**, **MuWeb**, **WebEngine** (CMS clásicos para MU).
- O una web propia que inserte en la tabla de cuentas.

Y un **launcher** que:
- Descargue/actualice el cliente.
- Aplique la IP configurada en `MainInfo.ini` al `local.bmd` y lance `main.exe`.

---

## 7.4 Dominio y DNS

- Apuntá un registro `A` (o un subdominio) a la IP del VPS.
- Opcional: usar el dominio en lugar de la IP en `ServerList.dat` y en el cliente.

---

## 7.5 Backups (no negociable)

Programá backups diarios de las 3 bases:

```sql
BACKUP DATABASE MuOnline    TO DISK = 'C:\Backups\MuOnline.bak'    WITH INIT;
BACKUP DATABASE Me_MuOnline TO DISK = 'C:\Backups\Me_MuOnline.bak' WITH INIT;
BACKUP DATABASE Ranking     TO DISK = 'C:\Backups\Ranking.bak'     WITH INIT;
```

Automatizalo con el **Programador de tareas** de Windows.

---

## 7.6 Monitoreo

- Revisá los `.log` de cada componente.
- Vigilá el uso de CPU/RAM y conexiones.
- Tené un plan para reinicios (el GameServer se degrada con el tiempo).

---

## Checklist final de producción

- [ ] Backdoors auditados (Fase 6)
- [ ] Todas las contraseñas por defecto cambiadas
- [ ] `sa` con contraseña fuerte y SQL **no** expuesto a internet
- [ ] Puertos internos cerrados al mundo
- [ ] IP pública en todos los componentes y en el cliente
- [ ] Web de registro funcionando
- [ ] Launcher operativo
- [ ] Backups automáticos
- [ ] DDoS contratado
- [ ] Anticheat decidido
