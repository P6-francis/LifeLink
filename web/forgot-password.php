<?php
require __DIR__ . '/includes/bootstrap.php';

if (!empty($_SESSION['admin_authenticated'])) {
    header('Location: index.php');
    exit;
}

$sent = false;
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $error = 'Please enter a valid email address.';
    } else {
        $sent = true;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Forgot Password | LifeLink</title>
    <link rel="icon" type="image/png" href="assets/images/lifelink_logo.png">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons+Round">
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body class="login-page">
    <main class="login-shell">
        <section class="login-card" aria-labelledby="login-title">
            <div class="login-brand"><img src="assets/images/lifelink_logo.png" alt="LifeLink"><div><div class="brand-name">LifeLink</div><div class="login-kicker">ADMIN CONSOLE</div></div></div>
            <div class="login-heading"><h1 id="login-title">Forgot password?</h1><p>Enter your email and we will send you instructions to reset your password.</p></div>
            <form method="post" action="forgot-password.php">
                <label class="login-field"><span>Admin Email</span><input type="email" name="email" autocomplete="email" placeholder="Enter your email" value="<?= htmlspecialchars($_POST['email'] ?? '', ENT_QUOTES, 'UTF-8') ?>" required></label>
                <?php if ($error !== ''): ?>
                    <p class="login-error" role="alert"><?= htmlspecialchars($error, ENT_QUOTES, 'UTF-8') ?></p>
                <?php endif; ?>
                <?php if ($sent): ?>
                    <p class="login-success" role="status">If that email belongs to an administrator account, reset instructions have been sent.</p>
                <?php endif; ?>
                <button class="login-submit" type="submit"><span>Send reset link</span><span class="material-icons-round" aria-hidden="true">send</span></button>
            </form>
            <div class="login-back-wrap"><a class="login-back" href="admin-login.php"><span class="material-icons-round" aria-hidden="true">arrow_back</span><span class="login-back-text">Back to sign in</span></a></div>
        </section>
    </main>
</body>
</html>
