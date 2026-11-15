<?php
define('PAGE_TITLE', 'Inicio');
require_once __DIR__ . '/includes/header.php';

$db_ok = false; $db_err = null; $stats = ['accounts' => null, 'chars' => null, 'online' => null];
try {
    require_once __DIR__ . '/includes/db.php';
    $conn = db_connect();
    $db_ok = true;
    try { $r = db_fetch_one(db_query($conn, "SELECT COUNT(*) AS c FROM MEMB_INFO")); $stats['accounts'] = $r ? (int)$r['c'] : null; } catch (Exception $e) {}
    try { $r = db_fetch_one(db_query($conn, "SELECT COUNT(*) AS c FROM Character")); $stats['chars'] = $r ? (int)$r['c'] : null; } catch (Exception $e) {}
    try { $r = db_fetch_one(db_query($conn, "SELECT COUNT(*) AS c FROM MEMB_STAT WHERE ConnectStat = 1")); $stats['online'] = $r ? (int)$r['c'] : null; } catch (Exception $e) {}
} catch (Exception $e) { $db_err = $e->getMessage(); }
?>
<section class="hero">
  <h1>Bienvenido a <?php echo h(SERVER_NAME); ?></h1>
  <p><?php echo h(SERVER_VERSION); ?> &bull; Experiencia <?php echo h(SERVER_EXP); ?> &bull; Drop <?php echo h(SERVER_DROP); ?> &bull; Nivel máximo <?php echo h(SERVER_MAX_LEVEL); ?></p>
  <p><?php echo h(SERVER_RESET_INFO); ?></p>
  <div class="btn-row">
    <a class="btn" href="registro.php">Crear cuenta</a>
    <a class="btn alt" href="descargas.php">Descargar cliente</a>
    <a class="btn alt" href="ranking.php">Ver ranking</a>
  </div>
</section>

<div class="grid">
  <div class="card">
    <h3>Conexión</h3>
    <p><strong>IP/Dominio:</strong> <code class="inline"><?php echo h(SERVER_IP); ?></code></p>
    <p><strong>Puerto (Connect):</strong> <code class="inline"><?php echo h(SERVER_PORT); ?></code></p>
    <p class="muted">Usá estos datos en el cliente si es necesario (según configuración del Main/Launcher).</p>
  </div>
  <div class="card">
    <h3>Estado</h3>
    <?php if ($db_ok): ?>
      <p class="muted">Base de datos: <span style="color:var(--ok)">conectada</span></p>
      <p>Cuentas: <strong><?php echo $stats['accounts'] !== null ? h($stats['accounts']) : 'N/D'; ?></strong></p>
      <p>Personajes: <strong><?php echo $stats['chars'] !== null ? h($stats['chars']) : 'N/D'; ?></strong></p>
      <p>Online: <strong><?php echo $stats['online'] !== null ? h($stats['online']) : 'N/D'; ?></strong></p>
    <?php else: ?>
      <p class="muted">Base de datos: <span style="color:#f0b36b">no disponible (configurar en <code class="inline">config.php</code>)</span></p>
    <?php endif; ?>
  </div>
  <div class="card">
    <h3>Información rápida</h3>
    <ul class="clean">
      <li>Exp <?php echo h(SERVER_EXP); ?>, monstruos reforzados.</li>
      <li>Reset en nivel 400, mantenés stats.</li>
      <li>Eventos: Blood Castle, Devil Square, Chaos Castle e invasiones.</li>
      <li>Comandos útiles: <code class="inline">/reset</code>, <code class="inline">/pick zen</code>, <code class="inline">/store</code>, <code class="inline">/bau</code>.</li>
    </ul>
  </div>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>