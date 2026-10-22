<header class="topbar">
    <button class="icon-btn menu-btn" type="button" data-menu-toggle aria-label="Open menu">
        <?= icon('menu') ?>
    </button>

    <div class="topbar-text">
        <h1><?= e($title) ?></h1>
        <p><?= e($subtitle) ?></p>
    </div>

    <a class="icon-btn bell-btn" href="index.php?page=notifications" title="Notifications">
        <span class="bell">
            <?= icon('notifications_none') ?>
            <span class="bell-dot" data-unread-dot<?= unread_notifications() ? '' : ' hidden' ?>></span>
        </span>
    </a>

    <div class="topbar-user">
        <div class="avatar avatar-sm">A</div>
        <span><?= e($_SESSION['admin_name'] ?? 'Administrator') ?></span>
    </div>
</header>
