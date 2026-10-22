<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="LifeLink blood donation admin console">
    <title>LifeLink Admin</title>
    <link rel="icon" type="image/png" href="assets/images/lifelink_logo.png">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons+Round">
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
    <?= partial('sidebar', ['current' => $current]) ?>
    <div class="scrim" data-scrim></div>

    <div class="main">
        <?= partial('topbar', ['title' => $meta['title'], 'subtitle' => $meta['subtitle']]) ?>
        <main class="content">
            <div class="content-inner">
                <?= $content ?>
            </div>
        </main>
    </div>

    <div class="dialog-backdrop" data-dialog hidden>
        <div class="dialog" role="dialog" aria-modal="true" data-dialog-body></div>
    </div>

    <template id="logout-confirmation">
        <div class="dialog-head">
            <div class="dialog-title">Log out?</div>
            <button class="dialog-close" type="button" data-dialog-close aria-label="Close"><?= icon('close', 16) ?></button>
        </div>
        <div class="dialog-subtitle">Are you sure you want to log out of the admin console?</div>
        <div class="confirm-actions">
            <button class="confirm-cancel" type="button" data-dialog-close>Cancel</button>
            <a class="confirm-yes" href="admin-login.php?logout=1">Yes, log out</a>
        </div>
    </template>

    <script src="assets/js/app.js"></script>
</body>
</html>
