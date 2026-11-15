<?php
define('PAGE_TITLE', 'Información');
require_once __DIR__ . '/includes/header.php';
?>
<div class="grid">
  <div class="card">
    <h2>Información del servidor</h2>
    <ul class="clean">
      <li><strong>Nombre:</strong> <?php echo h(SERVER_NAME); ?></li>
      <li><strong>Versión:</strong> <?php echo h(SERVER_VERSION); ?></li>
      <li><strong>Experiencia:</strong> <?php echo h(SERVER_EXP); ?></li>
      <li><strong>Drop:</strong> <?php echo h(SERVER_DROP); ?></li>
      <li><strong>Nivel máximo:</strong> <?php echo h(SERVER_MAX_LEVEL); ?></li>
      <li><strong>Reset:</strong> <?php echo h(SERVER_RESET_INFO); ?></li>
      <li><strong>IP/Dominio:</strong> <code class="inline"><?php echo h(SERVER_IP); ?></code></li>
      <li><strong>Puerto (Connect):</strong> <code class="inline"><?php echo h(SERVER_PORT); ?></code></li>
    </ul>
  </div>
  <div class="card">
    <h2>Comandos útiles</h2>
    <ul class="clean">
      <li><code class="inline">/reset</code> — Resetear al llegar a nivel 400.</li>
      <li><code class="inline">/pick zen</code> — Recoger zen automáticamente.</li>
      <li><code class="inline">/store</code> — Abrir tienda personal.</li>
      <li><code class="inline">/offstore</code> — Dejar tienda abierta al desconectarte.</li>
      <li><code class="inline">/bau 1</code>, <code class="inline">/bau 2</code> — Cambiar baúl.</li>
      <li><code class="inline">/pk</code> — Limpiar estado asesino.</li>
      <li><code class="inline">/attack</code> — Ataque automático.</li>
      <li><code class="inline">/offattack</code> — Seguir peleando desconectado (nivel 250+, consume zen).</li>
    </ul>
  </div>
  <div class="card">
    <h2>Eventos y actividades</h2>
    <ul class="clean">
      <li><strong>Blood Castle</strong> — cada 3 horas (01, 04, 07, 10, 13, 16, 19, 22).</li>
      <li><strong>Devil Square</strong> — cada 3 horas (02, 05, 08, 11, 14, 17, 20, 23).</li>
      <li><strong>Chaos Castle</strong> — cada 3 horas (03, 06, 09, 12, 15, 18, 21, 00).</li>
      <li><strong>Invasiones doradas</strong> — cada hora a los :05, :15, :25 y :50.</li>
    </ul>
    <p class="muted">Horarios según la hora del servidor.</p>
  </div>
  <div class="card">
    <h2>Reglas básicas</h2>
    <ul class="clean">
      <li>Respetá a los demás jugadores y al staff.</li>
      <li>No hagas spam ni publicidad de otros servidores.</li>
      <li>El uso de hacks/bugs puede resultar en sanción.</li>
      <li>Reportá problemas al staff con la mayor información posible.</li>
    </ul>
  </div>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>