<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/auth.php';
if (!function_exists('h')) { function h($s){ return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); } }
?>
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?php echo h(defined('PAGE_TITLE') ? PAGE_TITLE . ' - ' . SITE_TITLE : SITE_TITLE); ?></title>
  <link rel="stylesheet" href="assets/style.css">
</head>
<body>
  <div class="bg"></div>
  <header class="topbar">
    <div class="wrap nav">
      <a class="brand" href="index.php"><?php echo h(SERVER_NAME); ?></a>
      <nav>
        <a href="index.php">Inicio</a>
        <a href="ranking.php">Ranking</a>
        <a href="descargas.php">Descargas</a>
        <a href="info.php">Información</a>
        <?php if (current_user()): ?>
          <a href="cuenta.php">Mi cuenta</a>
          <a href="logout.php">Salir (<?php echo h(current_user()); ?>)</a>
        <?php else: ?>
          <a href="registro.php">Registro</a>
          <a href="login.php">Ingresar</a>
        <?php endif; ?>
      </nav>
    </div>
  </header>
  <main class="wrap">
    <?php $f = flash_get(); if ($f): ?>
      <div class="alert <?php echo $f['type']==='ok'?'ok':'err'; ?>"><?php echo h($f['msg']); ?></div>
    <?php endif; ?>