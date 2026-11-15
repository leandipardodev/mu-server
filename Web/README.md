# Web del servidor MU

Sitio web listo para el servidor MU (inicio, registro, ranking, descargas, información y gestión de cuenta/personajes).

## Contenido
- `index.php` — inicio y estado
- `registro.php` — creación de cuentas (tabla `MEMB_INFO`)
- `login.php` / `logout.php` — ingreso y cierre de sesión
- `cuenta.php` — panel de cuenta: datos, **cambio de contraseña** y **gestión de personajes**
  - Listado de personajes de la cuenta
  - **Desbuguear** (mueve a Lorencia, mapa 0)
  - **Limpiar PK**
  - **Resetear stats** (vuelve a stats base y devuelve puntos)
- `ranking.php` — ranking por resets/nivel (tabla `Character`)
- `descargas.php` — link de descarga del cliente
- `info.php` — información, comandos y eventos
- `config.php` — **configuración principal (editar al migrar a otra PC)**
- `includes/` — conexión a BD, autenticación/sesión, helpers de cuenta/personajes y layout
- `assets/style.css` — estilos
- `.htaccess` — protección básica (índices, config/README)

## Requisitos (en la PC servidor)
- Servidor web con **PHP 8+** (recomendado: XAMPP/WAMP, IIS+PHP, o Apache/Nginx+PHP).
- Extensión PHP para SQL Server: **`pdo_sqlsrv`** (recomendada) o `sqlsrv` (Microsoft Drivers for PHP for SQL Server) y ODBC Driver 17/18.
- Acceso al SQL Server donde está la base `MuOnline`.

> Si la web corre en la misma PC que el SQL Server, `DB_HOST` puede ser `127.0.0.1` o `.\SQLEXPRESS`.

## Configuración al mover a la otra PC
Editar `config.php`:
- **Base de datos:** `DB_HOST`, `DB_PORT`, `DB_NAME` (`MuOnline`), `DB_USER`, `DB_PASS`.
- **Servidor de juego:** `SERVER_IP` (IP pública/dominio), `SERVER_PORT` (ConnectServer, ej. 44405), nombre, rates, textos.
- **Descarga:** `CLIENT_DOWNLOAD_URL` (link al cliente) y `CLIENT_DOWNLOAD_NAME`.
- **Registro:** `ALLOW_REGISTRATION`, límites de usuario/contraseña.

La web queda igual al copiar la carpeta `Web`; solo cambiás las conexiones/datos en `config.php`.

## Despliegue rápido (XAMPP en Windows)
1. Instalar XAMPP (Apache + PHP).
2. Copiar la carpeta `Web` a `C:\xampp\htdocs\muweb` (o configurar un VirtualHost).
3. Instalar Microsoft Drivers for PHP for SQL Server y habilitar `extension=pdo_sqlsrv` en `php.ini`.
4. Editar `config.php` con los datos del SQL Server de esa PC.
5. Abrir `http://localhost/muweb/`.

## Notas
- **Autenticación/contraseñas:** este repack usa contraseñas en texto plano (`MD5Encryption = 0` en JoinServer). Login, registro y cambio de contraseña trabajan en ese formato; si en tu entorno usan MD5/hash, hay que adaptar `registro.php`, `login.php` y `cuenta.php`.
- **Gestión de personajes:** las acciones (desbuguear, limpiar PK, reset stats) deben hacerse preferentemente con el personaje **desconectado**. Se intentan columnas comunes (`MapNumber/MapPosX/MapPosY`, `PkLevel/PkCount/PkTime`, `Strength/Dexterity/Vitality/Energy/Leadership/LevelUpPoint`, `Resets/Reset/ResetCount`); si tu esquema difiere, ajustá `cuenta.php`/`includes/account.php`.
- **Vinculación cuenta-personajes:** se busca en `AccountCharacter` (campos `GameID*`) con fallback a `Character.AccountID`. Ajustar si tu repack usa otra estructura.
- **Seguridad:** formularios con sesión y token CSRF básico. Para producción, usá HTTPS, credenciales SQL seguras, restringí acceso al SQL Server y considerá captcha/rate-limit en registro/login si lo exponés a internet. Configurá `DB_PASS` y `SERVER_IP` reales en `config.php` al migrar.