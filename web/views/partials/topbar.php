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
            <?php $notificationCount = dashboard_unread_notification_count(); ?>
            <span class="bell-count" data-unread-count<?= $notificationCount ? '' : ' hidden' ?>><?= $notificationCount > 99 ? '99+' : $notificationCount ?></span>
        </span>
    </a>

    <div class="topbar-user">
        <div class="avatar avatar-sm">A</div>
        <span><?= e($_SESSION['admin_name'] ?? 'Administrator') ?></span>
    </div>
</header>
