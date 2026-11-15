<?php
define('PAGE_TITLE', 'Ranking');
require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/db.php';

$rows = []; $error = null; $mode = $_GET['type'] ?? 'resets';
if (!in_array($mode, ['resets','level'], true)) $mode = 'resets';

try {
    $conn = db_connect();
    $limit = 50;
    if ($mode === 'level') {
        $sql = "SELECT TOP {$limit} Name, cLevel, Class, COALESCE(Resets, Reset, ResetCount, 0) AS Resets
                FROM Character
                WHERE CtlCode < 8 OR CtlCode IS NULL
                ORDER BY cLevel DESC, COALESCE(Resets, Reset, ResetCount, 0) DESC";
    } else {
        $sql = "SELECT TOP {$limit} Name, cLevel, Class, COALESCE(Resets, Reset, ResetCount, 0) AS Resets
                FROM Character
                WHERE CtlCode < 8 OR CtlCode IS NULL
                ORDER BY COALESCE(Resets, Reset, ResetCount, 0) DESC, cLevel DESC";
    }
    try {
        $rows = db_fetch_all(db_query($conn, $sql));
    } catch (Exception $e1) {
        // Fallback sin columna Resets/Reset variable
        $sql2 = "SELECT TOP {$limit} Name, cLevel, Class FROM Character WHERE CtlCode < 8 OR CtlCode IS NULL ORDER BY cLevel DESC";
        $rows = db_fetch_all(db_query($conn, $sql2));
    }
} catch (Exception $e) {
    $error = $e->getMessage();
}

function class_name($c) {
    $map = [0=>'Dark Wizard',1=>'Soul Master',2=>'Grand Master',16=>'Dark Knight',17=>'Blade Knight',18=>'Blade Master',32=>'Fairy Elf',33=>'Muse Elf',34=>'High Elf',48=>'Magic Gladiator',64=>'Dark Lord',80=>'Summoner'];
    return $map[(int)$c] ?? ('Clase ' . (int)$c);
}
?>
<div class="card">
  <h2>Ranking de personajes</h2>
  <div class="btn-row" style="margin-bottom:12px">
    <a class="btn <?php echo $mode==='resets'?'':'alt'; ?>" href="ranking.php?type=resets">Top Resets</a>
    <a class="btn <?php echo $mode==='level'?'':'alt'; ?>" href="ranking.php?type=level">Top Nivel</a>
  </div>

  <?php if ($error): ?>
    <div class="alert err">No se pudo cargar el ranking. Configurá la base de datos en <code class="inline">config.php</code>.<br><small><?php echo h($error); ?></small></div>
  <?php elseif (!$rows): ?>
    <p class="muted">No hay personajes para mostrar.</p>
  <?php else: ?>
    <table>
      <thead><tr><th>#</th><th>Personaje</th><th>Clase</th><th>Nivel</th><th>Resets</th></tr></thead>
      <tbody>
      <?php $i=1; foreach ($rows as $r): ?>
        <tr>
          <td><?php echo $i++; ?></td>
          <td><strong><?php echo h($r['Name'] ?? ''); ?></strong></td>
          <td><?php echo h(class_name($r['Class'] ?? 0)); ?></td>
          <td><?php echo h($r['cLevel'] ?? 0); ?></td>
          <td><?php echo h($r['Resets'] ?? $r['Reset'] ?? $r['ResetCount'] ?? 0); ?></td>
        </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
  <?php endif; ?>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>