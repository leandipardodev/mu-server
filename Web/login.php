<?php
define('PAGE_TITLE', 'Ingresar');
require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/db.php';

if (current_user()) { header('Location: cuenta.php'); exit; }
$errors = [];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user = trim($_POST['user'] ?? '');
    $pass = trim($_POST['pass'] ?? '');
    if ($user === '' || $pass === '') {
        $errors[] = 'Completá usuario y contraseña.';
    } else {
        try {
            $conn = db_connect();
            $st = db_query($conn, "SELECT memb___id, memb__pwd, bloc_code FROM MEMB_INFO WHERE memb___id = ?", [$user]);
            $row = db_fetch_one($st);
            if (!$row) {
                $errors[] = 'Usuario o contraseña incorrectos.';
            } else {
                $dbpass = (string)($row['memb__pwd'] ?? '');
                $bloc = (string)($row['bloc_code'] ?? '0');
                $ok = hash_equals($dbpass, $pass);
                // soporte opcional si usan md5 en algún entorno
                if (!$ok && strlen($dbpass) === 32 && ctype_xdigit($dbpass)) {
                    $ok = hash_equals(strtolower($dbpass), md5($pass));
                }
                if (!$ok) {
                    $errors[] = 'Usuario o contraseña incorrectos.';
                } elseif ($bloc !== '0' && $bloc !== '') {
                    $errors[] = 'La cuenta se encuentra bloqueada.';
                } else {
                    session_regenerate_id(true);
                    $_SESSION['memb_id'] = (string)$row['memb___id'];
                    $next = $_GET['next'] ?? 'cuenta.php';
                    if (strpos($next, '://') !== false) $next = 'cuenta.php';
                    header('Location: ' . $next);
                    exit;
                }
            }
        } catch (Exception $e) {
            $errors[] = 'Error de conexión/configuración: ' . $e->getMessage();
        }
    }
}
?>
<div class="card form">
  <h2>Ingresar a mi cuenta</h2>
  <?php foreach ($errors as $e): ?><div class="alert err"><?php echo h($e); ?></div><?php endforeach; ?>
  <form method="post" action="login.php<?php echo isset($_GET['next']) ? '?next='.h(urlencode($_GET['next'])) : ''; ?>">
    <label for="user">Usuario</label>
    <input type="text" id="user" name="user" required value="<?php echo h($_POST['user'] ?? ''); ?>">
    <label for="pass">Contraseña</label>
    <input type="password" id="pass" name="pass" required>
    <div class="btn-row">
      <button class="btn" type="submit">Ingresar</button>
      <a class="btn alt" href="registro.php">Crear cuenta</a>
    </div>
  </form>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>