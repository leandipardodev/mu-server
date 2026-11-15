<?php
require_once __DIR__ . '/../config.php';

function db_connect() {
    static $conn = null;
    if ($conn !== null) return $conn;

    // Driver 1: pdo_sqlsrv (recomendado en Windows con PHP)
    if (extension_loaded('pdo_sqlsrv')) {
        $server = DB_HOST . (DB_PORT ? ',' . DB_PORT : '');
        $dsn = "sqlsrv:Server={$server};Database=" . DB_NAME . ";TrustServerCertificate=1";
        try {
            $conn = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]);
            return $conn;
        } catch (Exception $e) {
            throw new Exception('Error de conexión (pdo_sqlsrv): ' . $e->getMessage());
        }
    }

    // Driver 2: sqlsrv
    if (function_exists('sqlsrv_connect')) {
        $server = DB_HOST . (DB_PORT ? ',' . DB_PORT : '');
        $c = @sqlsrv_connect($server, [
            'Database' => DB_NAME,
            'UID' => DB_USER,
            'PWD' => DB_PASS,
            'CharacterSet' => 'UTF-8',
            'TrustServerCertificate' => true,
        ]);
        if (!$c) {
            $errs = sqlsrv_errors();
            throw new Exception('Error de conexión (sqlsrv): ' . json_encode($errs));
        }
        $conn = $c;
        return $conn;
    }

    throw new Exception('No hay driver SQL Server para PHP. Instalá la extensión pdo_sqlsrv o sqlsrv.');
}

function db_is_pdo($conn) {
    return $conn instanceof PDO;
}

function db_query($conn, $sql, $params = []) {
    if (db_is_pdo($conn)) {
        $st = $conn->prepare($sql);
        $st->execute($params);
        return $st;
    }
    // sqlsrv: parámetros posicionales ?
    $st = @sqlsrv_query($conn, $sql, $params);
    if (!$st) {
        $errs = sqlsrv_errors();
        throw new Exception('Error de consulta: ' . json_encode($errs));
    }
    return $st;
}

function db_fetch_all($st) {
    if ($st instanceof PDOStatement) return $st->fetchAll();
    $rows = [];
    while ($row = sqlsrv_fetch_array($st, SQLSRV_FETCH_ASSOC)) $rows[] = $row;
    return $rows;
}

function db_fetch_one($st) {
    $rows = db_fetch_all($st);
    return $rows ? $rows[0] : null;
}

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
?>