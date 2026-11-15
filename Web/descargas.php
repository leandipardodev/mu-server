<?php
define('PAGE_TITLE', 'Descargas');
require_once __DIR__ . '/includes/header.php';
?>
<div class="card">
  <h2>Descargar cliente</h2>
  <p>Descargá el cliente para jugar en <strong><?php echo h(SERVER_NAME); ?></strong>.</p>
  <div class="grid" style="margin-top:14px">
    <div class="card" style="background:var(--panel2)">
      <h3><?php echo h(CLIENT_DOWNLOAD_NAME); ?></h3>
      <p class="muted">Cliente configurado para <?php echo h(SERVER_VERSION); ?>.</p>
      <p><strong>IP del servidor:</strong> <code class="inline"><?php echo h(SERVER_IP); ?></code></p>
      <div class="btn-row">
        <?php if (CLIENT_DOWNLOAD_URL && CLIENT_DOWNLOAD_URL !== '#'): ?>
          <a class="btn" href="<?php echo h(CLIENT_DOWNLOAD_URL); ?>" target="_blank" rel="noopener">Descargar</a>
        <?php else: ?>
          <span class="btn alt" style="opacity:.7;cursor:default">Link de descarga no configurado</span>
        <?php endif; ?>
      </div>
      <p class="muted" style="margin-top:10px">Configurá el enlace en <code class="inline">config.php</code> (CLIENT_DOWNLOAD_URL).</p>
    </div>
    <div class="card" style="background:var(--panel2)">
      <h3>Cómo instalar</h3>
      <ol class="clean">
        <li>Descargá y descomprimí el cliente en una carpeta (ej. <code class="inline">C:\MuNega</code>).</li>
        <li>Ejecutá el juego (launcher o <code class="inline">main.exe</code> según el cliente).</li>
        <li>Si te lo pide, creá tu cuenta desde la sección <a href="registro.php">Registro</a>.</li>
        <li>Ingresá con tu usuario y contraseña.</li>
      </ol>
      <p class="muted">Si el cliente no conecta, verificá que la IP/puerto del servidor coincidan con la configuración publicada.</p>
    </div>
  </div>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>