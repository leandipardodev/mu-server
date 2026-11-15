# Referencia — Puertos

Los puertos **varían según el repack**. Estos son los valores típicos de la era
1.02N. Verificalos siempre en los `.ini` de tu repack y en `ServerList.dat`.

---

## Puertos por componente

| Componente     | Puerto por defecto | Protocolo | Expuesto a internet |
|----------------|--------------------|-----------|---------------------|
| ConnectServer  | 44405              | TCP       | **Sí**              |
| JoinServer     | 55970              | TCP       | No (interno)        |
| DataServer 1   | 55960              | TCP       | No (interno)        |
| DataServer 2   | 55962              | TCP       | No (interno)        |
| GameServer     | 55901              | TCP/UDP   | **Sí**              |
| GameServerCS   | 55919              | TCP/UDP   | **Sí**              |
| EventServer    | 55920              | TCP       | Según repack        |
| RankingServer  | 55921              | TCP       | No (interno)        |
| ExDB           | variable           | TCP       | No (interno)        |
| SQL Server     | 1433               | TCP       | **No** (solo local) |

---

## Regla de oro

> Solo se exponen al mundo los puertos que el **cliente** necesita:
> **44405**, **55901** y (si aplica) **55919 / 55920**.
>
> Todo lo demás (JoinServer, DataServer, SQL) queda en `127.0.0.1`.

---

## Comandos útiles (Windows)

### Ver qué está escuchando
```powershell
.\scripts\verificar-puertos.ps1
```

### Ver puertos en uso (nativo)
```powershell
netstat -ano | Select-String "LISTENING" | Select-String "44405|55901|55919|55970|55960|55962"
```

### Ver qué proceso usa un puerto
```powershell
Get-NetTCPConnection -LocalPort 44405 | Select-Object LocalAddress,LocalPort,State,OwningProcess
```

### Probar conectividad a un puerto
```powershell
Test-NetConnection -ComputerName IP_O_DOMINIO -Port 44405
```

---

## Abrir puertos en el firewall de Windows

```powershell
$ports = 44405,55901,55919,55920
foreach ($p in $ports) {
  New-NetFirewallRule -DisplayName "MU-$p" -Direction Inbound -Protocol TCP -LocalPort $p -Action Allow
}
```

Para cerrar un puerto que abriste de más:

```powershell
Remove-NetFirewallRule -DisplayName "MU-55920"
```
