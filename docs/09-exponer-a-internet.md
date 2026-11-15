# Fase 9 (extra) — Exponer el servidor desde tu PC a internet

Objetivo: que tus amigos entren desde afuera de tu red, con el server corriendo
en tu PC.

> ⚠️ **Antes de invitar gente**, hacé la auditoría de backdoors (`docs/06-seguridad.md`).
> Exponer un repack sin auditar a internet es riesgoso.

---

## Paso 1 — Averiguar tu IP pública

```powershell
(Invoke-RestMethod https://api.ipify.org)
```

O entrá a https://www.cual-es-mi-ip.net

---

## Paso 2 — Fijar la IP local de tu PC

Tu PC tiene una IP local (ej. `192.168.0.15`) que puede cambiar. Para que el
port forwarding no se rompa:

- **Opción A (recomendada):** en el router, reservá (DHCP reservation) la IP
  local de tu PC por su dirección MAC.
- **Opción B:** configurá una IP local fija en Windows.

Mirá tu IP local actual:

```powershell
ipconfig | Select-String "IPv4"
```

---

## Paso 3 — Port forwarding en el router

1. Entrá al panel del router (normalmente `192.168.0.1` o `192.168.1.1`).
   Mirá la "puerta de enlace predeterminada" con `ipconfig`.
2. Buscá la sección **Port Forwarding / Virtual Server / NAT / Reenvío de puertos**.
3. Creá estas reglas (IP local = la de tu PC):

| Puerto externo | Protocolo | Destino (tu PC) |
|---|---|---|
| 44405 | TCP | `192.168.0.X:44405` |
| 55901 | TCP + UDP | `192.168.0.X:55901` |
| 55919 | TCP + UDP | `192.168.0.X:55919` |
| 55920 | TCP | `192.168.0.X:55920` |

> Los puertos exactos pueden variar según el repack. Confirmalos en `docs/07-puertos.md`
> y en los `.ini`.

---

## Paso 4 — Firewall de Windows

Ejecutá (se auto-eleva, aceptá el UAC):

```powershell
.\scripts\abrir-puertos-firewall.ps1
```

Para cerrarlos luego: `.\scripts\abrir-puertos-firewall.ps1 -Remove`

---

## Paso 5 — DDNS (si tu IP pública cambia)

La mayoría de las conexiones hogareñas tienen **IP dinámica**. Con un DDNS gratis
tenés siempre el mismo nombre (ej. `miservidor.duckdns.org`):

1. Creá una cuenta en https://www.duckdns.org
2. Creá un subdominio (ej. `miservidor`).
3. Instalá el cliente de DuckDNS en tu PC para que actualice la IP sola.
4. En el cliente MU y en `ServerList.dat`, usá ese dominio en vez de la IP.

---

## Paso 6 — Probar desde afuera

- **Desde el celular con datos móviles** (NO wifi): conectá el cliente MU a tu
  IP pública / dominio.
- Probá el puerto desde otra red:

```powershell
Test-NetConnection -ComputerName TU_IP_PUBLICA -Port 44405
```

- O usá un comprobador online: https://www.yougetsignal.com/tools/open-ports/

Si `44405` da **abierto** pero el cliente no conecta, revisá `ServerList.dat`
y que el ConnectServer esté corriendo.

---

## ⚠️ CGNAT — el bloqueador más común

Muchos ISPs (sobre todo en LatAm y con fibra/cable) usan **CGNAT**: tu conexión
no tiene IP pública propia, así que el **port forwarding no funciona** aunque lo
configures bien.

**Cómo detectarlo:**
- La IP "WAN" que muestra tu router **no coincide** con tu IP pública.
- `tracert 8.8.8.8` muestra un primer salto en `100.64.x.x` o `10.x.x.x`.

**Soluciones si tenés CGNAT:**
1. Pedirle al ISP una **IP pública** (a veces se paga aparte).
2. Usar **ZeroTier / Tailscale** (VPN): tus amigos instalan una app y entran
   por la red privada, sin tocar el router. Ideal para "probar con amigos".
3. Pasar a un **VPS** (`docs/05-deploy-vps.md`).

---

## Checklist

- [ ] IP pública anotada (o DDNS configurado).
- [ ] IP local de la PC fija.
- [ ] Port forwarding hecho en el router.
- [ ] Firewall de Windows abierto (`abrir-puertos-firewall.ps1`).
- [ ] Probado desde una red externa (celular con datos).
- [ ] Backdoors auditados.
- [ ] SQL (1433) y puertos internos **NO** expuestos.
