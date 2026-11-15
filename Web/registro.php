<?php
define('PAGE_TITLE', 'Registro');
require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/db.php';

$errors = []; $ok = null;

function valid_id($s) { return (bool)preg_match('/^[A-Za-z0-9]+$/', $s); }

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!ALLOW_REGISTRATION) {
        $errors[] = 'El registro está deshabilitado temporalmente.';
    } else {
        $user = trim($_POST['user'] ?? '');
        $pass = trim($_POST['pass'] ?? '');
        $pass2 = trim($_POST['pass2'] ?? '');
        $email = trim($_POST['email'] ?? '');

        if (strlen($user) < MIN_USER_LEN || strlen($user) > MAX_USER_LEN) $errors[] = 'El usuario debe tener entre ' . MIN_USER_LEN . ' y ' . MAX_USER_LEN . ' caracteres.';
        if (strlen($pass) < MIN_PASS_LEN || strlen($pass) > MAX_PASS_LEN) $errors[] = 'La contraseña debe tener entre ' . MIN_PASS_LEN . ' y ' . MAX_PASS_LEN . ' caracteres.';
        if (!valid_id($user)) $errors[] = 'El usuario solo puede contener letras y números (sin espacios ni símbolos).';
        if (!valid_id($pass)) $errors[] = 'La contraseña solo puede contener letras y números.';
        if ($pass !== $pass2) $errors[] = 'Las contraseñas no coinciden.';
        if ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) $errors[] = 'El email no es válido.';

        if (!$errors) {
            try {
                $conn = db_connect();
                // Verificar si existe
                $st = db_query($conn, "SELECT memb___id FROM MEMB_INFO WHERE memb___id = ?", [$user]);
                $exists = db_fetch_one($st);
                if ($exists) {
                    $errors[] = 'Ese nombre de usuario ya está en uso.';
                } else {
                    // Inserción compatible con esquema MuOnline estándar (ajustar si tu DB difiere)
                    $sno = '1111111111111111';
                    $name = $user;
                    $bloc = '0'; $ctl1 = '0';
                    $sql = "INSERT INTO MEMB_INFO (memb___id, memb__pwd, memb_name, sno__numb, bloc_code, ctl1_code, mail_addr)
                            VALUES (?, ?, ?, ?, ?, ?, ?)";
                    // Algunos esquemas no tienen mail_addr; intentar fallback
                    try {
                        db_query($conn, $sql, [$user, $pass, $name, $sno, $bloc, $ctl1, $email]);
                    } catch (Exception $e1) {
                        try {
                            $sql2 = "INSERT INTO MEMB_INFO (memb___id, memb__pwd, memb_name, sno__numb, bloc_code, ctl1_code)
                                     VALUES (?, ?, ?, ?, ?, ?)";
                            db_query($conn, $sql2, [$user, $pass, $name, $sno, $bloc, $ctl1]);
                        } catch (Exception $e2) {
                            // Fallback mínimo
                            $sql3 = "INSERT INTO MEMB_INFO (memb___id, memb__pwd, memb_name) VALUES (?, ?, ?)";
                            db_query($conn, $sql3, [$user, $pass, $name]);
                        }
                    }
                    $ok = 'Cuenta creada correctamente. Ya podés ingresar al juego con tu usuario y contraseña.';
                }
            } catch (Exception $e) {
                $errors[] = 'No se pudo crear la cuenta. Verificá la conexión/configuración de la base de datos en config.php. Detalle: ' . $e->getMessage();
            }
        }
    }
}
?>
<div class="card form">
  <h2>Crear cuenta</h2>
  <p class="muted">Usuario y contraseña: <?php echo MIN_USER_LEN; ?>-<?php echo MAX_USER_LEN; ?> caracteres, solo letras y números.</p>

  <?php foreach ($errors as $e): ?>
    <div class="alert err"><?php echo h($e); ?></div>
  <?php endforeach; ?>
  <?php if ($ok): ?>
    <div class="alert ok"><?php echo h($ok); ?></div>
  <?php endif; ?>

  <form method="post" action="registro.php" autocomplete="off">
    <label for="user">Usuario</label>
    <input type="text" id="user" name="user" maxlength="<?php echo MAX_USER_LEN; ?>" required value="<?php echo h($_POST['user'] ?? ''); ?>">

    <label for="email">Email (opcional)</label>
    <input type="email" id="email" name="email" value="<?php echo h($_POST['email'] ?? ''); ?>">

    <label for="pass">Contraseña</label>
    <input type="password" id="pass" name="pass" maxlength="<?php echo MAX_PASS_LEN; ?>" required>

    <label for="pass2">Repetir contraseña</label>
    <input type="password" id="pass2" name="pass2" maxlength="<?php echo MAX_PASS_LEN; ?>" required>

    <div class="btn-row">
      <button class="btn" type="submit">Registrarme</button>
    </div>
  </form>
</div>
<?php require_once __DIR__ . '/includes/footer.php'; ?>