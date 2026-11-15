<?php
// ============================================================
//  Configuración de la web del servidor MU
//  Cambiá estos valores al mover el servidor a la otra PC.
// ============================================================

// --- Base de datos (SQL Server / MuOnline) ---
define('DB_HOST', '127.0.0.1');      // IP/host del SQL Server (en la PC servidor puede ser 127.0.0.1 o .\SQLEXPRESS)
define('DB_PORT', '1433');           // Puerto SQL Server
define('DB_NAME', 'MuOnline');       // Nombre de la base de datos
define('DB_USER', 'sa');             // Usuario SQL (o 'muuser')
define('DB_PASS', 'CAMBIAR_CLAVE');  // Contraseña SQL

// --- Servidor de juego (para mostrar en la web) ---
define('SERVER_NAME', 'Mu Nega');
define('SERVER_VERSION', 'Season 2 - 1.02.44');
define('SERVER_IP', 'TU_IP_O_DOMINIO');     // IP pública o dominio que usarán los jugadores
define('SERVER_PORT', '44405');              // Puerto ConnectServer (cliente)
define('SERVER_EXP', 'x3000');
define('SERVER_DROP', '15%');
define('SERVER_MAX_LEVEL', '400');
define('SERVER_RESET_INFO', 'Nivel 400 + 35M zen = Reset (+1000 puntos, mantenés stats)');

// --- Descarga del cliente ---
define('CLIENT_DOWNLOAD_URL', '#');  // Link a Mega/Google Drive/archivo zip del cliente
define('CLIENT_DOWNLOAD_NAME', 'Cliente Mu Nega (1.02.44)');

// --- Sitio ---
define('SITE_TITLE', SERVER_NAME . ' - MU Online');
define('TIMEZONE', 'America/Argentina/Buenos_Aires');

// --- Seguridad/registro ---
define('ALLOW_REGISTRATION', true);
define('MIN_USER_LEN', 4);
define('MAX_USER_LEN', 10);
define('MIN_PASS_LEN', 4);
define('MAX_PASS_LEN', 10);

date_default_timezone_set(TIMEZONE);
?>