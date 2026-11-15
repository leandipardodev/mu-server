# Fase 4 — Preparar el cliente

El cliente debe ser de la **misma versión** que el servidor (1.02N). El repack
suele traerlo; si no, hay que conseguir uno compatible.

---

## 4.1 Qué necesita el cliente

- `main.exe` de la versión 1.02N
- Carpeta `Data/` (texturas, modelos, mapas)
- `Mu.exe` / launcher (opcional)

---

## 4.2 Apuntar el cliente a tu servidor

El cliente de este repack obtiene la conexión desde `MainInfo.ini`. El archivo
`GetMainInfo.exe` aplica esos valores al `local.bmd`, que es el que lee el
cliente al arrancar.

Configura `IpAddress`, `IpAddressPort`, `ClientVersion` y `ClientSerial` en
`Cliente\MainInfo.ini`. Luego inicia el cliente con `JUGAR.cmd`, que ejecuta
`GetMainInfo.exe` antes de abrir `main.exe`. No abras `main.exe` directamente
después de cambiar esos valores.

Para esta prueba local, usa la IPv4 LAN activa de la PC en vez de `127.0.0.1`
en `MainInfo.ini`, `ConnectServer\ServerList.dat` y `Data\MapServerInfo.dat`.
La configuración actual usa `192.168.0.85`; si cambia la dirección de la PC,
actualiza esos tres archivos y reinicia el servidor.

---

## 4.3 Versión y serial

La versión y el serial de `Cliente\MainInfo.ini` deben coincidir con
`GameServer\DATA\GameServerInfo - Common.dat` y `MHPServer\MHPServer.ini`:
- **Versión** (en este repack, `1.02.44`)
- **Serial**

Si no coinciden, el cliente no entra. No edites `main.exe`: `JUGAR.cmd` aplica
los valores del INI al `local.bmd` que lee el cliente.

---

## 4.4 Probar en local

1. Servidor corriendo y sin errores en los logs.
2. Lanzá `JUGAR.cmd`; regenerará `local.bmd` desde `MainInfo.ini` y abrirá el cliente.
3. Deberías ver la pantalla de login.
4. Creá una cuenta (según el repack, se crea desde el propio juego o con un
   comando SQL / herramienta).
5. Entrá y creá un personaje.

### Si no conecta
- Revisa `IpAddress` y `IpAddressPort` en `Cliente\MainInfo.ini`; usa `JUGAR.cmd`
  para regenerar `local.bmd`.
- Si el cliente termina antes de mostrar servidores usando `127.0.0.1`, prueba
  con la IPv4 LAN activa de la PC en los tres archivos indicados arriba.
- Puerto 44405 cerrado (en local, el firewall de Windows).
- El ConnectServer no está corriendo.
- Versión/serial distintos.

---

## 4.5 Firewall de Windows (local)

Para probar en LAN, permití el paso a los `.exe`:

```powershell
New-NetFirewallRule -DisplayName "MU ConnectServer" -Direction Inbound -Protocol TCP -LocalPort 44405 -Action Allow
New-NetFirewallRule -DisplayName "MU GameServer"   -Direction Inbound -Protocol TCP -LocalPort 55901 -Action Allow
```

---

Siguiente: probar todo en local, después **`docs/06-seguridad.md`** y recién
entonces **`docs/05-deploy-vps.md`**.
