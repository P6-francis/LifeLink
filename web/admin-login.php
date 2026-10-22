<?php
require __DIR__ . '/includes/bootstrap.php';

if (isset($_GET['logout'])) {
    $_SESSION = [];
    session_destroy();
    header('Location: admin-login.php');
    exit;
}

if (!empty($_SESSION['admin_authenticated'])) {
    header('Location: index.php');
    exit;
}

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    if (hash_equals(ADMIN_EMAIL, $email) && hash_equals(ADMIN_PASSWORD, $password)) {
        session_regenerate_id(true);
        $_SESSION['admin_authenticated'] = true;
        $_SESSION['admin_name'] = 'Administrator';
        header('Location: index.php');
        exit;
    }
    $error = 'Incorrect email or password.';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Sign in to the LifeLink admin console">
    <title>Admin Sign In | LifeLink</title>
    <link rel="icon" type="image/png" href="assets/images/lifelink_logo.png">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons+Round">
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body class="login-page">
    <main class="login-shell">
        <section class="login-card" aria-labelledby="login-title">
            <div class="login-brand"><img src="assets/images/lifelink_logo.png" alt="LifeLink"><div><div class="brand-name">LifeLink</div><div class="login-kicker">ADMIN CONSOLE</div></div></div>
            <div class="login-heading"><h1 id="login-title">Hello Admin</h1><p>Sign in with your authorized administrator account.</p></div>
            <form method="post" action="admin-login.php">
                <label class="login-field"><span>Admin Email</span><input type="email" name="email" autocomplete="email" placeholder="Enter your email" required></label>
                <label class="login-field"><span>Password</span><input type="password" name="password" autocomplete="current-password" placeholder="Enter your password" required></label>
                <?php if ($error !== ''): ?>
                    <p class="login-error" role="alert"><?= htmlspecialchars($error, ENT_QUOTES, 'UTF-8') ?></p>
                <?php endif; ?>
                <button class="login-submit" type="submit"><span>Sign in to dashboard</span><span class="material-icons-round" aria-hidden="true">arrow_forward</span></button>
            </form>
            <p class="login-help">Only accounts assigned the <strong>admin</strong> can access this console.</p>
        </section>
    </main>
</body>
</html>
