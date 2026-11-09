<?php
$message = '';
$error = '';
$adminEmail = $_SESSION['admin_email'] ?? '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'update-name') {
    try {
        $name = trim((string) ($_POST['admin_name'] ?? ''));
        if (mb_strlen($name) < 2 || mb_strlen($name) > 80) throw new RuntimeException('Use an administrator name between 2 and 80 characters.');
        $token = (string) ($_SESSION['firebase_id_token'] ?? '');
        if ($token === '') throw new RuntimeException('Your session has expired. Please sign in again.');
        firebase_update_display_name($token, $name);
        $_SESSION['admin_name'] = $name;
        $message = 'Administrator name updated successfully.';
    } catch (Throwable $exception) {
        $error = $exception->getMessage();
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'change-password') {
    try {
        $current = (string) ($_POST['current_password'] ?? '');
        $new = (string) ($_POST['new_password'] ?? '');
        $confirm = (string) ($_POST['confirm_password'] ?? '');
        if ($current === '' || $new === '' || $confirm === '') throw new RuntimeException('Complete all password fields.');
        if (strlen($new) < 8) throw new RuntimeException('Use at least 8 characters for the new password.');
        if ($new !== $confirm) throw new RuntimeException('The new passwords do not match.');
        $signIn = firebase_sign_in($adminEmail, $current);
        firebase_change_password($signIn['idToken'] ?? '', $new);
        $message = 'Password updated successfully.';
    } catch (Throwable $exception) {
        $error = $exception->getMessage() === 'INVALID_LOGIN_CREDENTIALS' ? 'Your current password is incorrect.' : $exception->getMessage();
    }
}
?>
<div class="profile-wrap">
    <?php if ($message !== ''): ?><section class="panel"><p style="color:#16834c;font-weight:700"><?= e($message) ?></p></section><?php endif; ?>
    <?php if ($error !== ''): ?><section class="panel"><p style="color:#c9252d;font-weight:700"><?= e($error) ?></p></section><?php endif; ?>
    <div class="profile-layout">
        <section class="panel">
            <header class="panel-head"><div><h2>Administrator Account</h2><p>Manage the public name displayed in this dashboard.</p></div></header>
            <form method="post" class="form-grid profile-inline-form">
                <input type="hidden" name="action" value="update-name">
                <div class="form-field"><label class="filter-label" for="admin-name">Administrator name</label><input class="form-input" id="admin-name" name="admin_name" value="<?= e($_SESSION['admin_name'] ?? 'Administrator') ?>" maxlength="80" required></div>
                <div class="form-field"><label class="filter-label">Authorized Firebase email</label><input class="form-input" value="<?= e($adminEmail) ?>" readonly></div>
                <div class="form-field"><label class="filter-label">Access level</label><input class="form-input" value="Dashboard administrator" readonly></div>
                <div class="form-actions"><button class="btn-primary" type="submit">Save Name</button></div>
            </form>
        </section>
        <section class="panel">
            <header class="panel-head"><div><h2>Change Password</h2><p>Update the Firebase Authentication password for this admin account.</p></div></header>
            <form method="post" class="form-grid profile-inline-form">
                <input type="hidden" name="action" value="change-password">
                <div class="form-field"><label class="filter-label">Current Password</label><input class="form-input" type="password" name="current_password" autocomplete="current-password" required></div>
                <div class="form-field"><label class="filter-label">New Password</label><input class="form-input" type="password" name="new_password" autocomplete="new-password" minlength="8" required></div>
                <div class="form-field"><label class="filter-label">Confirm New Password</label><input class="form-input" type="password" name="confirm_password" autocomplete="new-password" minlength="8" required></div>
                <div class="form-actions"><button class="btn-primary" type="submit">Update Password</button></div>
            </form>
        </section>
        <section class="panel">
            <header class="panel-head"><div><h2>Admin Security</h2><p>Only server-authorized emails can access this dashboard.</p></div></header>
            <div class="form-grid three"><div class="form-field"><label class="filter-label">Authorized administrators</label><input class="form-input" value="<?= e(implode(', ', firebase_admin_emails())) ?>" readonly></div></div>
        </section>
    </div>
</div>
