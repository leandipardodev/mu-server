<?php
define('PAGE_TITLE', 'Mi cuenta');
require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/db.php';
require_once __DIR__ . '/includes/account.php';
require_login();

$accId = current_user();
$errors = []; $okmsg = null;

function do_unstick($conn, $name) {
    // Lorencia segura
    $tries = [
        "UPDATE Character SET MapNumber=0, MapPosX=125, MapPosY=125 WHERE Name=?",
        "UPDATE Character SET MapNumber=0, MapPosX=125, MapPosY=125, MapDir=0 WHERE Name=?",
    ];
    foreach ($tries as $sql) { try { db_query($conn, $sql, [$name]); return true; } catch (Exception $e) {} }
    throw new Exception('No se pudo mover el personaje (verificá columnas MapNumber/MapPosX/MapPosY).');
}
function do_clearpk($conn, $name) {
    $tries = [
        "UPDATE Character SET PkLevel=3, PkCount=0, PkTime=0 WHERE Name=?",
        "UPDATE Character SET PkLevel=3, PkCount=0 WHERE Name=?",
        "UPDATE Character SET PkLevel=3 WHERE Name=?",
    ];
    foreach ($tries as $sql) { try { db_query($conn, $sql, [$name]); return true; } catch (Exception $e) {} }
    throw new Exception('No se pudo limpiar PK (verificá columnas PkLevel/PkCount/PkTime).');
}
function base_stats($class) {
    $c = (int)$class;
    if ($c >= 64 && $c <= 66) return ['Strength'=>26,'Dexterity'=>20,'Vitality'=>20,'Energy'=>15,'Leadership'=>25];
    if ($c >= 48 && $c <= 50) return ['Strength'=>26,'Dexterity'=>26,'Vitality'=>26,'Energy'=>26,'Leadership'=>0];
    if ($c >= 32 && $c <= 34) return ['Strength'=>22,'Dexterity'=>25,'Vitality'=>20,'Energy'=>15,'Leadership'=>0];
    if ($c >= 16 && $c <= 18) return ['Strength'=>28,'Dexterity'=>20,'Vitality'=>25,'Energy'=>10,'Leadership'=>0];
    return ['Strength'=>18,'Dexterity'=>18,'Vitality'=>15,'Energy'=>30,'Leadership'=>0]; // DW/SM/GM y default
}
function do_resetstats($conn, $charRow) {
    $name = char_field($charRow, ['Name'], '');
    $class = (int)char_field($charRow, ['Class'], 0);
    $base = base_stats($class);
    $str = (int)char_field($charRow, ['Strength'], $base['Strength']);
    $dex = (int)char_field($charRow, ['Dexterity'], $base['Dexterity']);
    $vit = (int)char_field($charRow, ['Vitality'], $base['Vitality']);
    $ene = (int)char_field($charRow, ['Energy'], $base['Energy']);
    $cmd = (int)char_field($charRow, ['Leadership','Command'], $base['Leadership']);
    $points = (int)char_field($charRow, ['LevelUpPoint','LevelUpPoints'], 0);
    $add = max(0,$str-$base['Strength']) + max(0,$dex-$base['Dexterity']) + max(0,$vit-$base['Vitality']) + max(0,$ene-$base['Energy']) + max(0,$cmd-$base['Leadership']);
    $newPoints = $points + $add;
    $cmdCol = array_key_exists('Leadership',$charRow) ? 'Leadership' : (array_key_exists('Command',$charRow) ? 'Command' : 'Leadership');
    $tries = [
        "UPDATE Character SET Strength=?, Dexterity=?, Vitality=?, Energy=?, {$cmdCol}=?, LevelUpPoint=? WHERE Name=?",
        "UPDATE Character SET Strength=?, Dexterity=?, Vitality=?, Energy=?, {$cmdCol}=?, LevelUpPoints=? WHERE Name=?",
    ];
    $params = [$base['Strength'],$base['Dexterity'],$base['Vitality'],$base['Energy'],$base['Leadership'],$newPoints,$name];
    foreach ($tries as $sql) { try { db_query($conn, $sql, $params); return $newPoints; } catch (Exception $e) {} }
    throw new Exception('No se pudieron resetear los stats (verificá columnas de stats/LevelUpPoint en Character).');
}

try { $conn = db_connect(); } catch (Exception $e) { $conn = null; $errors[] = 'Error de BD: '.$e->getMessage(); }

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $conn) {
    if (!csrf_check($_POST['csrf'] ?? '')) {
        $errors[] = 'Sesión inválida (CSRF). Recargá la página e intentá de nuevo.';
    } else {
        $action = $_POST['action'] ?? '';
        if ($action === 'change_pass') {
            $cur = (string)($_POST['current_pass'] ?? '');
            $n1 = (string)($_POST['new_pass'] ?? '');
            $n2 = (string)($_POST['new_pass2'] ?? '');
            $acc = account_get($conn, $accId);
            $dbpass = (string)($acc['memb__pwd'] ?? '');
            $okcur = hash_equals($dbpass, $cur) || (strlen($dbpass)===32 && ctype_xdigit($dbpass) && hash_equals(strtolower($dbpass), md5($cur)));
            if (!$okcur) $errors[] = 'La contraseña actual es incorrecta.';
            elseif (strlen($n1) < MIN_PASS_LEN || strlen($n1) > MAX_PASS_LEN) $errors[] = 'La nueva contraseña debe tener entre '.MIN_PASS_LEN.' y '.MAX_PASS_LEN.' caracteres.';
            elseif (!preg_match('/^[A-Za-z0-9]+$/', $n1)) $errors[] = 'La nueva contraseña solo puede tener letras y números.';
            elseif ($n1 !== $n2) $errors[] = 'Las contraseñas nuevas no coinciden.';
            else {
                try { db_query($conn, "UPDATE MEMB_INFO SET memb__pwd = ? WHERE memb___id = ?", [$n1, $accId]); $okmsg = 'Contraseña actualizada.'; }
                catch (Exception $e) { $errors[] = 'No se pudo cambiar la contraseña: '.$e->getMessage(); }
            }
        } elseif (in_array($action, ['unstick','clearpk','resetstats'], true)) {
            $charName = trim($_POST['char'] ?? '');
            $char = char_belongs_to($conn, $accId, $charName);
            if (!$char) { $errors[] = 'Personaje inválido.'; }
            else {
                try {
                    if ($action === 'unstick') { do_unstick($conn, $charName); $okmsg = "Personaje '".h($charName)."' movido a Lorencia."; }
                    if ($action === 'clearpk') { do_clearpk($conn, $charName); $okmsg = "PK limpiado para '".h($charName)."'. (Si estaba online, puede requerir reloguear)"; }
                    if ($action === 'resetstats') { $np = do_resetstats($conn, $char); $okmsg = "Stats reseteados para '".h($charName)."'. Puntos disponibles: {$np}."; }
                } catch (Exception $e) { $errors[] = $e->getMessage(); }
            }
        }
    }
}

$account = $conn ? account_get($conn, $accId) : null;
$chars = $conn ? account_characters($conn, $accId) : [];
?>
<div class="grid">
  <div class="card">
    <h2>Mi cuenta</h2>
    <?php foreach ($errors as $e): ?><div class="alert err"><?php echo h($e); ?></div><?php endforeach; ?>
    <?php if ($okmsg): ?><div class="alert ok"><?php echo $okmsg; ?></div><?php endif; ?>
    <p><strong>Usuario:</strong> <?php echo h($accId); ?></p>
    <p><strong>Email:</strong> <?php echo h($account['mail_addr'] ?? ($account['mail__addr'] ?? 'N/D')); ?></p>
    <p><strong>Estado:</strong> <?php $b=(string)($account['bloc_code']??'0'); echo ($b==='0'||$b==='')?'<span style="color:var(--ok)">Activa</span>':'<span style="color:var(--danger)">Bloqueada</span>'; ?></p>

    <h3 style="margin-top:18px">Cambiar contraseña</h3>
    <form method="post" class="form" style="max-width:420px">
      <input type="hidden" name="csrf" value="<?php echo h(csrf_token()); ?>">
      <input type="hidden" name="action" value="change_pass">
      <label>Contraseña actual</label>
      <input type="password" name="current_pass" required>
      <label>Nueva contraseña</label>
      <input type="password" name="new_pass" maxlength="<?php echo MAX_PASS_LEN; ?>" required>
      <label>Repetir nueva contraseña</label>
      <input type="password" name="new_pass2" maxlength="<?php echo MAX_PASS_LEN; ?>" required>
      <div class="btn-row"><button class="btn" type="submit">Actualizar</button></div>
    </form>
  </div>

  <div class="card" style="grid-column: span 2;">
    <h2>Mis personajes</h2>
    <p class="muted">Acciones: desbuguear mueve a Lorencia (mapa 0). Recomendado usar con el personaje desconectado.</p>
    <?php if (!$chars): ?>
      <p class="muted">No se encontraron personajes para esta cuenta.</p>
    <?php else: ?>
      <table>
        <thead><tr><th>Nombre</th><th>Clase</th><th>Nivel</th><th>Resets</th><th>Mapa</th><th>PK</th><th>Puntos</th><th>Acciones</th></tr></thead>
        <tbody>
        <?php foreach ($chars as $c):
          $name = (string)char_field($c,['Name'],'');
          $lvl = char_field($c,['cLevel','Level'],0);
          $res = char_field($c,['Resets','Reset','ResetCount'],0);
          $map = char_field($c,['MapNumber','Map'],0);
          $pk = char_field($c,['PkLevel'],0);
          $pts = char_field($c,['LevelUpPoint','LevelUpPoints'],0);
          $class = char_field($c,['Class'],0);
        ?>
          <tr>
            <td><strong><?php echo h($name); ?></strong></td>
            <td><?php echo h(char_class_name($class)); ?></td>
            <td><?php echo h($lvl); ?></td>
            <td><?php echo h($res); ?></td>
            <td><?php echo h($map); ?></td>
            <td><?php echo h($pk); ?></td>
            <td><?php echo h($pts); ?></td>
            <td>
              <form method="post" style="display:inline" onsubmit="return confirm('¿Mover a Lorencia? Hacelo con el PJ offline.');">
                <input type="hidden" name="csrf" value="<?php echo h(csrf_token()); ?>">
                <input type="hidden" name="action" value="unstick">
                <input type="hidden" name="char" value="<?php echo h($name); ?>">
                <button class="btn alt" type="submit">Desbuguear</button>
              </form>
              <form method="post" style="display:inline" onsubmit="return confirm('¿Limpiar PK?');">
                <input type="hidden" name="csrf" value="<?php echo h(csrf_token()); ?>">
                <input type="hidden" name="action" value="clearpk">
                <input type="hidden" name="char" value="<?php echo h($name); ?>">
                <button class="btn alt" type="submit">Limpiar PK</button>
              </form>
              <form method="post" style="display:inline" onsubmit="return confirm('¿Resetear stats a base? Los puntos volverán a disponibles.');">
                <input type="hidden" name="csrf" value="<?php echo h(csrf_token()); ?>">
                <input type="hidden" name="action" value="resetstats">
                <input type="hidden" name="char" value="<?php echo h($name); ?>">
                <button class="btn alt" type="submit">Reset stats</button>
              </form>
            </td>
          </tr>
        <?php endforeach; ?>
        </tbody>
      </table>
    <?php endif; ?>
  </div>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>