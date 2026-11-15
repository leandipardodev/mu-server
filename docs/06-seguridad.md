# Fase 6 — Seguridad y auditoría de backdoors

Esta es la fase que **más gente saltea y más caro le sale**. Un repack filtrado
casi siempre trae puertas traseras. Un servidor público sin limpiar es cuestión
de horas antes de que lo destruyan.

---

## 6.1 Qué backdoors buscar

| Tipo | Cómo se manifiesta |
|------|--------------------|
| Comando de GM oculto | Un comando en el chat que da acceso total |
| Conexión saliente | El `.exe` abre conexión a una IP externa (C2) |
| DROP/borrado remoto | Comando que borra personajes o la base |
| Usuario maestro hardcodeado | Cuenta fija con permisos de admin |
| Envío de credenciales | El JoinServer manda usuarios/contraseñas afuera |
| Puertos extra | El `.exe` escucha en un puerto que no debería |

---

## 6.2 Metodología de auditoría

### Paso 1 — Ejecutar en una VM aislada
Nunca en tu PC principal. Sin red (o con red monitoreada). Observá:
- ¿Abre conexiones salientes? (Wireshark / `netstat -b`)
- ¿Escucha puertos raros?
- ¿Escribe/modifica archivos fuera de su carpeta?

### Paso 2 — Analizar los `.exe` con strings
Buscá texto sospechoso dentro de los binarios:

```powershell
# Buscar IPs, dominios, palabras clave en los .exe
Select-String -Path .\MuServer\**\*.exe -Pattern 'http://','https://','\.ru','\.cn','backdoor','cmd\.exe' -Encoding Default -List
```

Con `strings` (Sysinternals) es más cómodo:
```powershell
strings.exe -n 6 .\MuServer\GameServer\GameServer.exe | Select-String 'http|\.com|\.ru|\.cn|cmd|DROP'
```

### Paso 3 — Revisar los `.ini` y `.dat`
- Credenciales hardcodeadas.
- IPs desconocidas.
- Comandos GM predefinidos.

### Paso 4 — Revisar los scripts SQL
- ¿Crean usuarios/login inesperados?
- ¿Contienen `xp_cmdshell`, `OPENROWSET`, jobs programados?
- Verificá **todas** las tablas y stored procedures.

### Paso 5 — Buscar comparación con otro repack
Si tenés dos repacks, compará los `.exe` (hash, tamaño). Diferencias raras =
sospecha.

---

## 6.3 Herramientas útiles

- **VirusTotal** (subida de archivos, detecta familias conocidas)
- **Wireshark** (tráfico saliente)
- **Process Monitor / Process Explorer** (Sysinternals)
- **strings / Sigcheck** (Sysinternals)
- **PE-bear / CFF Explorer** (inspección de PE)

---

## 6.4 Endurecimiento básico

- [ ] **Cambiar TODAS** las contraseñas por defecto (SQL, cuentas GM, web).
- [ ] `sa` con contraseña fuerte; **no** exponer SQL a internet (solo `127.0.0.1`).
- [ ] Crear un login SQL **dedicado** para el MuServer con permisos mínimos.
- [ ] Revisar los comandos GM: dejar solo los que usás.
- [ ] Restringir por IP el acceso a la web de administración.
- [ ] Logs activados y revisados.
- [ ] Firewall: solo puertos de cliente abiertos.
- [ ] Antivirus/EDR en el VPS (excluyendo la carpeta del MuServer si da falsos positivos).

---

## 6.5 Anticheat

En un servidor público, sin anticheat es tierra de nadie. Opciones clásicas para
la era 1.02N:
- **MuGuard**, **MuAntiCheat**, **AntiCheat de X-Team** (varían según repack).
- Protección a nivel cliente (paquetes encriptados) + servidor.

Es un tema aparte, con costo y mantenimiento. Definilo **antes** de abrir el
servidor.

---

## 6.6 Plan de respuesta

- Tené un **backup reciente** siempre listo.
- Sepas **cómo banear** cuentas/IPs rápido.
- Sepas **cómo reiniciar** el servidor limpio.
- Documentá cada incidente.

---

Solo cuando esta fase esté completa, pasá a **`docs/05-deploy-vps.md`**.
